//
//  DailyCardTwistsTests.swift
//  GigaBallTests
//
//  James, round 313: "On endless mode or endless mayhem in the daily challenge menu view,
//  centre the twists in the gap between the game mode heading and the bottom of the container.
//  It looks a bit awkward."
//
//  A classic day carries a pack-and-level line under its mode name, and the twists sit a fixed
//  distance below that. An endless day has none - "the mode name and the twists are the day"
//  (round 306) - and the label was left in place holding an empty string. Not hidden, so zero
//  points tall and still taking the stack's spacing on *both* sides: measured before the fix,
//  the mode name ended at 148 and the card at 218 with the twists at 178 to 200, which is
//  thirty points of air above them and eighteen below.
//

import XCTest
import UIKit
@testable import Giga_Ball

final class DailyCardTwistsTests: XCTestCase {

    private func card(for key: String) -> (card: DailyCardView, mode: GameMode) {
        let card = DailyCardView()
        card.frame = CGRect(x: 0, y: 0, width: 393, height: 700)
        card.show(key: key, isToday: false, record: nil, standing: nil)
        card.setNeedsLayout()
        card.layoutIfNeeded()
        return (card, DailyChallengeGenerator.challenge(forKey: key).mode)
    }

    /// The first day of each kind, found rather than written down - which day generates which
    /// mode is the generator's business and changes with the calendar.
    private func firstDay(where wanted: (GameMode) -> Bool) -> String? {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for offset in 0..<60 {
            var day = DateComponents(year: 2026, month: 9, day: 1)
            day.day = 1 + offset
            guard let date = calendar.date(from: day) else { continue }
            let key = formatter.string(from: date)
            if wanted(DailyChallengeGenerator.challenge(forKey: key).mode) { return key }
        }
        return nil
    }

    private func parts(_ card: DailyCardView) -> (heading: CGRect, twists: CGRect,
                                                  container: CGRect)? {
        func stacks(_ root: UIView) -> [UIStackView] {
            root.subviews.flatMap { child -> [UIStackView] in
                ((child as? UIStackView).map { [$0] } ?? []) + stacks(child)
            }
        }
        func labels(_ root: UIView) -> [UILabel] {
            root.subviews.flatMap { child -> [UILabel] in
                ((child as? UILabel).map { [$0] } ?? []) + labels(child)
            }
        }
        guard let outer = stacks(card).first,
              let inner = stacks(card).dropFirst().first,
              let heading = labels(card).first(where: {
                  ($0.text ?? "").isEmpty == false && $0.isHidden == false
              }),
              let container = outer.superview
        else { return nil }

        return (heading.convert(heading.bounds, to: card),
                inner.convert(inner.bounds, to: card),
                container.convert(container.bounds, to: card))
    }

    // MARK: - The report

    /// On a day with no level line, the twists sit in the middle of what is left.
    func testTheTwistsAreCentredOnAnEndlessDay() throws {
        let key = try XCTUnwrap(firstDay { $0 == .endlessII || $0 == .endless },
                                "no endless day in the next two months")
        let (card, mode) = self.card(for: key)
        let parts = try XCTUnwrap(self.parts(card))

        let above = parts.twists.minY - parts.heading.maxY
        let below = parts.container.maxY - parts.twists.maxY

        XCTAssertEqual(above, below, accuracy: 1,
                       "\(mode) on \(key): \(Int(above)) above the twists and \(Int(below)) "
                       + "below is the awkwardness James saw")
        XCTAssertEqual(above, DailyCardView.twistsGap, accuracy: 1,
                       "and both are the card's own inset, so it is one number rather than two")
    }

    /// The empty level line is out of the layout, not merely empty.
    ///
    /// A zero-height label still takes the stack's spacing either side of it, which is where
    /// the extra twelve points came from.
    func testTheAbsentLevelLineIsHiddenRatherThanEmpty() throws {
        let key = try XCTUnwrap(firstDay { $0 == .endlessII || $0 == .endless })
        let (card, _) = self.card(for: key)

        func labels(_ root: UIView) -> [UILabel] {
            root.subviews.flatMap { child -> [UILabel] in
                ((child as? UILabel).map { [$0] } ?? []) + labels(child)
            }
        }
        let empty = labels(card).filter { ($0.text ?? "").isEmpty && $0.attributedText == nil }
        XCTAssertTrue(empty.allSatisfy { $0.isHidden || $0.superview is UIStackView == false },
                      "an empty label left in a stack is still spacing")
    }

    // MARK: - What must not change

    /// A classic day keeps its level line, and the twists keep their distance from it.
    func testAClassicDayIsUnchanged() throws {
        let key = try XCTUnwrap(firstDay { $0 == .classic }, "no classic day")
        let (card, _) = self.card(for: key)
        let parts = try XCTUnwrap(self.parts(card))

        XCTAssertGreaterThan(parts.twists.minY, parts.heading.maxY,
                            "the twists are still below the heading")
        XCTAssertEqual(parts.container.maxY - parts.twists.maxY,
                       DailyCardView.twistsGap, accuracy: 1,
                       "and the card's inset below them is the same on every day")
    }

    /// The pager reuses one card for every day, so a classic day after an endless one must not
    /// inherit the endless spacing.
    func testTheSameCardShowsBothKindsInTurn() throws {
        let endless = try XCTUnwrap(firstDay { $0 == .endlessII || $0 == .endless })
        let classic = try XCTUnwrap(firstDay { $0 == .classic })

        let card = DailyCardView()
        card.frame = CGRect(x: 0, y: 0, width: 393, height: 700)
        for key in [endless, classic, endless] {
            card.show(key: key, isToday: false, record: nil, standing: nil)
            card.setNeedsLayout()
            card.layoutIfNeeded()
        }

        let parts = try XCTUnwrap(self.parts(card))
        let above = parts.twists.minY - parts.heading.maxY
        XCTAssertEqual(above, DailyCardView.twistsGap, accuracy: 1,
                       "back on an endless day, the gap is the endless day's again")
    }
}
