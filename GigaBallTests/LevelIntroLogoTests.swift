//
//  LevelIntroLogoTests.swift
//  GigaBallTests
//
//  James, round 313: "The Giga-Ball logo on the level intro splash screen shouldn't animate
//  along with the game mode title and icon."
//
//  The icon travelling with the name is deliberate, and the code says so: "a child of the
//  intro's own view, so every entrance and exit the intro plays carries the icon with the name
//  for free". Round 312 added the wordmark to the same view and inherited that for free as
//  well, without anyone deciding it should - so the intro's 1.15 entrance, its 1.5-second
//  drift and its 1.5 exit all took the wordmark with them.
//
//  A wordmark is chrome. It is the same fixed mark the pause and game-over screens wear at the
//  top, and those two do not swell.
//

import XCTest
import UIKit
@testable import Giga_Ball

final class LevelIntroLogoTests: XCTestCase {

    /// The intro, built and shown the way `GameViewController` builds and shows it.
    private func shownIntro() -> (host: UIView, intro: InbetweenViewController) {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let intro = UIStoryboard(name: "Main",
                                 bundle: Bundle(for: InbetweenViewController.self))
            .instantiateViewController(withIdentifier: "inbetweenView")
            as! InbetweenViewController
        intro.view.frame = host.bounds
        host.addSubview(intro.view)
        intro.view.layoutIfNeeded()
        intro.updateLabels()
        // Builds the mode icon, which is what builds the wordmark beside it
        intro.showAnimate()
        // And this is where the intro learns which view it is being shown inside, which is
        // the first moment the wordmark can be hosted outside it
        intro.view.transform = .identity
        intro.view.alpha = 1
        host.layoutIfNeeded()
        return (host, intro)
    }

    private func wordmark(in root: UIView) -> UIImageView? {
        for child in root.subviews {
            if let image = child as? UIImageView,
               image.image === UIImage(named: "Logo") { return image }
            if let found = wordmark(in: child) { return found }
        }
        return nil
    }

    private func descends(_ view: UIView, from ancestor: UIView) -> Bool {
        var next = view.superview
        while let here = next {
            if here === ancestor { return true }
            next = here.superview
        }
        return false
    }

    /// The report: the wordmark is not inside the view the intro animates.
    func testTheWordmarkIsNotInsideTheAnimatedIntro() throws {
        let (host, intro) = shownIntro()
        let logo = try XCTUnwrap(wordmark(in: host), "the intro has no wordmark on it")

        XCTAssertFalse(descends(logo, from: intro.view),
                       "a subview of the intro is scaled by every transform the intro plays - "
                       + "1.15 in, a 1.5-second drift, and 1.5 out")
        XCTAssertTrue(descends(logo, from: host),
                      "but it still belongs to the screen, and leaves with it")
    }

    /// A transform on the intro does not move it.
    func testTheIntroCanZoomWithoutTakingTheWordmarkWithIt() throws {
        let (host, intro) = shownIntro()
        let logo = try XCTUnwrap(wordmark(in: host))
        host.layoutIfNeeded()
        let before = logo.convert(logo.bounds, to: host)

        intro.view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        host.layoutIfNeeded()
        let after = logo.convert(logo.bounds, to: host)

        XCTAssertEqual(before, after,
                       "the wordmark held still while the intro played its exit")
    }

    /// And the mode icon still does travel with the name, which is the deliberate half.
    func testTheModeIconStillTravelsWithTheName() throws {
        let (host, intro) = shownIntro()
        func icons(_ root: UIView) -> [UIImageView] {
            root.subviews.flatMap { child -> [UIImageView] in
                let mine = (child as? UIImageView).map { [$0] } ?? []
                return mine + icons(child)
            }
        }
        let insideTheIntro = icons(intro.view)
        XCTAssertFalse(insideTheIntro.isEmpty,
                       "the mode icon is a child of the intro on purpose - it is part of the "
                       + "title block, and every entrance and exit should carry it")
        XCTAssertFalse(insideTheIntro.contains { $0.image === UIImage(named: "Logo") },
                       "and the wordmark is not one of them")
    }
}
