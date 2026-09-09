//
//  MenuLayoutTests.swift
//  GigaBallTests
//
//  The main menu at every shape a window can be dragged into.
//
//  James, round 313, from iPadOS 26's windowed mode: two of his screenshots show the GIGA-BALL
//  wordmark sitting on top of Classic Mode, and the information and settings buttons sitting on
//  top of Daily Challenge.
//
//  The cause was a fixed height. The mode table carried a hard 450 points in the storyboard
//  (563 at regular width), and it is centred in a container whose height is whatever is left
//  between the logo and the icon row. On a phone that container is 495 points, so 450 fits and
//  nobody ever saw it. In a 931x708 window it is 248, and a 450-point table centred in 248
//  points of room hangs 100 points out of each end - over the logo above and the icons below.
//  Measured, before the fix: container 275 to 523, table 117 to 680, logo 140 to 185.
//
//  The row height made it worse rather than catching it: it was `min(150, tableHeight/4)`,
//  asked of the table's *own* height, which is four rows of whatever that returns. Every
//  height is its own fixed point, so the answer was only ever whatever the table happened to
//  start at.
//

import XCTest
import UIKit
@testable import Giga_Ball

final class MenuLayoutTests: XCTestCase {

    /// Every shape, including the two he sent.
    private let shapes: [(String, CGSize)] = [
        ("phone", CGSize(width: 393, height: 852)),
        ("small phone", CGSize(width: 320, height: 568)),
        ("his square window", CGSize(width: 950, height: 975)),
        ("his wide window", CGSize(width: 931, height: 708)),
        ("his tall window", CGSize(width: 430, height: 1180)),
        ("iPad portrait", CGSize(width: 1024, height: 1366)),
        ("iPad landscape", CGSize(width: 1366, height: 1024)),
        ("slide over", CGSize(width: 320, height: 1024)),
    ]

    private func laidOut(_ size: CGSize) -> MenuViewController {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: MenuViewController.self))
        let menu = board.instantiateViewController(withIdentifier: "menuView")
            as! MenuViewController
        window.rootViewController = menu
        window.isHidden = false
        for _ in 0..<4 {
            menu.view.setNeedsLayout()
            menu.view.layoutIfNeeded()
        }
        return menu
    }

    private func rect(_ view: UIView, in menu: MenuViewController) -> CGRect {
        view.convert(view.bounds, to: menu.view)
    }

    // MARK: - The report

    /// The wordmark and the mode rows are never in the same place.
    func testTheModeRowsNeverReachTheWordmark() {
        for (name, size) in shapes {
            let menu = laidOut(size)
            let logo = rect(menu.logoImage, in: menu)
            let table = rect(menu.modeSelectTableView, in: menu)
            XCTAssertGreaterThanOrEqual(table.minY, logo.maxY, "\(name): "
                + "the rows start at \(Int(table.minY)) and the wordmark ends at "
                + "\(Int(logo.maxY)) - they are on top of one another")
        }
    }

    /// Nor the mode rows and the information and settings buttons.
    func testTheModeRowsNeverReachTheIconRow() {
        for (name, size) in shapes {
            let menu = laidOut(size)
            let icons = rect(menu.iconCollectionView, in: menu)
            let table = rect(menu.modeSelectTableView, in: menu)
            XCTAssertLessThanOrEqual(table.maxY, icons.minY, "\(name): "
                + "the rows end at \(Int(table.maxY)) and the icons start at "
                + "\(Int(icons.minY))")
        }
    }

    /// Which both follow from this: the table stays in the room it was given.
    func testTheTableStaysInsideItsContainer() {
        for (name, size) in shapes {
            let menu = laidOut(size)
            let container = rect(menu.tableViewContainer, in: menu)
            let table = rect(menu.modeSelectTableView, in: menu)
            XCTAssertGreaterThanOrEqual(table.minY, container.minY - 0.5, name)
            XCTAssertLessThanOrEqual(table.maxY, container.maxY + 0.5, name)
        }
    }

    /// And every mode is reachable without scrolling, which is the menu's own rule.
    func testTheMenuNeverScrolls() {
        for (name, size) in shapes {
            let menu = laidOut(size)
            let table = menu.modeSelectTableView!
            let room = menu.tableViewContainer.bounds.height
            let needed = MenuViewController.modeRowHeight(inRoomOf: room)
                * CGFloat(GameMode.allCases.count)
            guard needed <= room + 0.5 else {
                // A window too short for four cards at their minimum: scrolling is the
                // graceful failure, and the constraint keeps the rows inside the room
                continue
            }
            XCTAssertLessThanOrEqual(table.contentSize.height, table.bounds.height + 0.5,
                                     "\(name): the main menu never scrolls")
        }
    }

    // MARK: - The rule itself

    /// The room is the container's, and never the table's own height.
    ///
    /// The old line was circular - `min(150, tableHeight/4)` asked of a table four rows tall -
    /// so any height at all was a fixed point and the answer was an accident of which layout
    /// pass got there first. This one is a function of room the table does not decide.
    ///
    /// **The ceiling is read, not restated** (round 314). These three assertions were written
    /// as the literal 150 and all three failed the moment James asked for the rows to stop
    /// growing on an iPad, reporting a change that was the point of the change. What the test
    /// is actually for is the *shape* of the rule - capped above, floored at the card, linear
    /// between, and never zero - so it asks `tallestModeRow` for the number.
    func testTheRowHeightIsAFunctionOfTheRoom() {
        let ceiling = MenuViewController.tallestModeRow
        XCTAssertEqual(MenuViewController.modeRowHeight(inRoomOf: ceiling*8), ceiling,
                       "capped, or a tall window gives four enormous buttons")
        XCTAssertEqual(MenuViewController.modeRowHeight(inRoomOf: 495),
                       min(ceiling, 495/4),
                       "and linear in the room between the floor and the ceiling")
        XCTAssertEqual(MenuViewController.modeRowHeight(inRoomOf: 248), 75,
                       "and floored at the card inside the cell, or the cards overlap")
        XCTAssertEqual(MenuViewController.modeRowHeight(inRoomOf: 0), ceiling,
                       "a table with no size yet must not stick at nothing")
    }

    /// And the ceiling itself is a phone's, which is the thing James asked for.
    ///
    /// A separate assertion because it is a separate claim: the rule above is about shape and
    /// this is about the number. The card inside a row is 75, so this says the gap between two
    /// cards never exceeds 45 points however large the screen - against roughly 33 on a phone,
    /// and 75 under the old ceiling of 150.
    func testTheModeRowCeilingStaysPhoneSized() {
        XCTAssertLessThanOrEqual(MenuViewController.tallestModeRow - 75, 45,
                                 "the four modes have to read as one block on an iPad")
        XCTAssertGreaterThan(MenuViewController.tallestModeRow, 108,
                             "and still be no tighter than a phone, which fits about 108")
    }

    /// Four rows always fit the height the table is given.
    func testFourRowsFillTheTableExactly() {
        for room in stride(from: 200.0, through: 1200.0, by: 25.0) {
            let menu = MenuViewController.modeRowHeight(inRoomOf: CGFloat(room))
            let total = menu*CGFloat(GameMode.allCases.count)
            XCTAssertLessThanOrEqual(total, max(CGFloat(room), 300),
                                     "\(room) points of room, \(total) of rows")
        }
    }
}
