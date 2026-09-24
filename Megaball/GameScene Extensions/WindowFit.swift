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
        var half = gameWidth/2
        let margin = labelSpacing*2
        if pauseButton.parent != nil {
            half = max(half, -pauseButton.frame.minX + margin)
        }
        if scoreLabel.parent != nil {
            half = max(half, scoreLabel.frame.maxX + margin)
        }
        return min(half*2, laidOutSceneSize.width)
    }

    /// Reshapes the scene to a window of `viewSize`, keeping the level as it was built.
    ///
    /// Called from `GameViewController.viewDidLayoutSubviews`, so it follows every drag of an
    /// iPad or Mac window. A phone never changes shape and it never does anything there.
    func fitTheWindow(_ viewSize: CGSize) {
        guard laidOutSceneSize.width > 0 else { return }
        let target = GameScene.sizeFilling(viewSize, laidOut: laidOutSceneSize,
                                           narrowest: narrowestTheSceneCanBe)
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
