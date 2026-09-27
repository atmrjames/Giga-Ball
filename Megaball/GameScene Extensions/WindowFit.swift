//
//  WindowFit.swift
//  Megaball
//
//  The game view following the window's shape after the level has been built.
//
//  James, round 342: "is it not possible to make those purple side bars dynamic so their width
//  can adjust as the window adjusts, ensuring the game view fills the vertical space without
//  being clipped."
//
//  It is, and it costs the level nothing, because of where the purple is. The play zone holds
//  its 1.8236 ratio and fills the window's height; everything either side of it is border -
//  the walls, drawn in the app's purple, and whatever lies past them. So a window that changes
//  width while keeping its height has exactly one honest answer: the same play zone, the same
//  height, more or less border. The scene is widened or narrowed to the window's shape and
//  `aspectFit` then has nothing to letterbox.
//
//  **Only the width moves, never the height and never a node with a body.** Dozens of places
//  read `frame.height` while a run is going - the top of the field, the line a lost ball
//  crosses, the edges a falling brick is culled at - and every physics body was built against
//  the size the level was laid out at. Widening the canvas around them leaves all of it where
//  it was: the scene's anchor is its centre, so the play zone stays centred and the walls'
//  inner edges stay on the play zone's edges. What is past the walls is painted the walls'
//  own colour, which is what makes the wider scene read as wider bars rather than as a gap.
//

import SpriteKit

extension GameScene {

    /// The walls' purple, from `GameScene.sks` (and the `GameViewController` letterbox, which
    /// uses the same literal). Past the walls is painted this, so the border reads as one bar
    /// however wide the window makes it.
    static let borderColour = UIColor(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)

    /// The scene size that fills a window of `view`'s shape, given the size the level was
    /// laid out at and the narrowest the scene can be without cutting anything off.
    ///
    /// Pure arithmetic, so it can be pinned without a window. Height is always the laid-out
    /// height; width follows the window's shape down to `narrowest`, and below that the window
    /// is thinner than the game itself, so the scene stops narrowing and `aspectFit` shows
    /// bands above and below instead. Those are the one shape of window that cannot be filled
    /// without cutting off the walls or the HUD, which James's own condition rules out.
    static func sizeFilling(_ view: CGSize, laidOut: CGSize, narrowest: CGFloat) -> CGSize {
        guard laidOut.width > 0, laidOut.height > 0, view.width > 0, view.height > 0 else {
            return laidOut
        }
        let width = laidOut.height*view.width/view.height
        return CGSize(width: max(width, min(narrowest, laidOut.width)), height: laidOut.height)
    }

    /// The narrowest the scene can be drawn without losing anything a player needs.
    ///
    /// The play zone, and the HUD at the top. On an iPad the HUD sits inside the play zone's
    /// edges (`isRegularWidth`), so that is the play zone alone; on a compact width it was
    /// hung off the screen's edges when the level was built, and those are then the limit -
    /// with the same margin it was given, so the pause button is never left touching the
    /// window's edge. Never wider than the level was laid out, which by definition fitted.
    var narrowestTheSceneCanBe: CGFloat {
        min(gameWidth, laidOutSceneSize.width)
    }
    // **The play zone alone, on every layout** (James, round 351: "still getting black bars at
    // the top and bottom of the game view on iPad when it's not necessary. Reduce the width of
    // the purple side bars as needed to always make the game view as tall as possible").
    // A narrow iPad window lays out with a compact width, which hangs the pause button and the
    // score off the *screen's* edges - and this used to stop narrowing there, so a window
    // thinner than the one the level was built in kept its purple bars and banded top and
    // bottom instead. The HUD follows the edges now (`placeTheHUDAcross`), so nothing but the
    // play zone itself sets the limit.

    /// Puts the pause button and the score across the HUD row for the scene's width now.
    ///
    /// A regular-width layout hangs them off the play zone, which does not move. A compact one
    /// hangs them off the scene's edges - so as a window narrows they come in with it, at the
    /// margin they were first given, rather than being left out past an edge that has moved.
    ///
    /// **And the pause button keeps clear of the window's own controls** (James, round 351:
    /// "pause button in the top left can overlap with the window controls. Shift the pause
    /// button in to the right a bit when running in multitasking / windowed mode on iPad").
    /// iPadOS 26 reports how far its controls reach through a corner-adapted safe area; the
    /// difference from the plain one is their width, and it is zero on a phone and on a
    /// full-screen iPad, where there are no controls to avoid.
    func placeTheHUDAcross() {
        guard laidOutSceneSize.width > 0 else { return }
        let half = size.width/2
        let margin = labelSpacing*2
        var pauseX: CGFloat
        let scoreX: CGFloat
        if hudHangsOnThePlayZone {
            pauseX = -gameWidth/2 + pauseButton.size.width/2 + layoutUnit/2
            scoreX = gameWidth/2 - layoutUnit/2
        } else {
            pauseX = -half + margin + pauseButton.size.width/2
            scoreX = half - margin
        }
        if let controls = windowControlsEdge {
            pauseX = max(pauseX, controls + labelSpacing + pauseButton.size.width/2)
        }
        pauseButton.position.x = pauseX
        pauseButtonTouch.position.x = pauseX
        let scoreShift = scoreX - scoreLabel.position.x
        scoreLabel.position.x = scoreX
        multiplierLabel.position.x += scoreShift
        if dailyClockLabel != nil { showDailyClock() }
        // The clock is placed against the score and the multiplier every time it is drawn
    }

    /// Where the window's controls end, in scene coordinates, or nil when there are none.
    var windowControlsEdge: CGFloat? {
        guard #available(iOS 26.0, *), let view else { return nil }
        let adapted = view.edgeInsets(for: .safeArea(cornerAdaptation: .horizontal)).left
        let plain = view.safeAreaInsets.left
        guard adapted - plain > 1 else { return nil }
        return convertPoint(fromView: CGPoint(x: adapted, y: 0)).x
    }

    /// Reshapes the scene to a window of `viewSize`, keeping the level as it was built.
    ///
    /// Called from `GameViewController.viewDidLayoutSubviews`, so it follows every drag of an
    /// iPad or Mac window. A phone never changes shape and it never does anything there.
    func fitTheWindow(_ viewSize: CGSize) {
        guard laidOutSceneSize.width > 0 else { return }
        let target = GameScene.sizeFilling(viewSize, laidOut: laidOutSceneSize,
                                           narrowest: narrowestTheSceneCanBe)
        defer { placeTheHUDAcross() }
        // Every layout, resized or not: the window's controls come and go with windowing, and
        // a window moved between full screen and a window can keep the same shape
        guard abs(target.width - size.width) > 0.5 || abs(target.height - size.height) > 0.5
        else { return }

        size = target
        backgroundColor = GameScene.borderColour
        // The walls are only as thick as the border was when the level was built (at least
        // `minimumWallThickness`), and their bodies were built with them - so they stay as they
        // are and the scene behind them takes their colour. Resizing a wall would move its
        // centre, and with it the body's inner edge the ball bounces off.

        topScreenBlock.size.width = max(topScreenBlock.size.width, target.width)
        // The HUD's backdrop, a slightly different purple from the walls, runs the whole width
        // or the new border would show a step at the height of the HUD. Its body (from the
        // .sks) keeps the size it was built with; a sprite's size does not reach its body.

        for tile in endlessIIBackdropTiles {
            tile.size.width = max(tile.size.width, target.width)
        }
        // Mayhem's scrolling backdrop is drawn across the whole scene, borders included, and
        // is above the walls - so it widens with the scene rather than stopping at the old edge.
    }
}
