//
//  GameSceneLayout.swift
//  Megaball
//
//  How big the playfield is, and everything that follows from that.
//
//  This was inline in `computeLayoutMetrics`, which was the only place that needed it. The
//  background selection screen needs it too: it draws a scale model of the game scene, and a
//  model whose walls or brick rows are a different proportion from the real thing is a picture
//  of a game the player is not about to play.
//
//  Pure arithmetic, no nodes, so it can be worked out for a screen that is not on screen -
//  which is exactly what a mock-up is - and pinned down by tests. The play area's ratio is a
//  promise the game makes across every device, and it is worth being able to assert it.
//

import UIKit

struct GameSceneLayout {

    /// Play height : play width. Measured from the shipping build and held constant on every
    /// device so the game plays identically across a player's devices.
    static let playRatio: CGFloat = 1.8236

    static let brickRows = 22
    static var brickColumns: Int { brickRows/2 }

    /// The HUD row (2 units), the power-up tray (2.25 units) and the spacing between
    /// them, in layout units. Must cover everything stacked below the safe area inset,
    /// or the tray overhangs into the playfield.
    ///
    /// Shortened from 5.5 when the tray's bars became rings (play-test round 7): the
    /// tray was two icon-heights tall to give each bar its room, and the ring needs
    /// none. A deliberate change, not a side effect - the whole layout scales from this,
    /// so the play zone keeps its ratio and the game is geometrically identical, just
    /// with a little more of the screen.
    ///
    /// Five exactly, not less: at 4.75 the solved field grows past the width of current
    /// iPhones and the layout clamps, which wastes the very height the shortening was
    /// meant to spend - the layout tests caught it on the 17 Pro and Pro Max. Five keeps
    /// every phone height-constrained, and still leaves Mayhem's shorter bar (4.7) with
    /// a wider field to buy.
    static let hudUnits: CGFloat = 5.0
    /// The same bar in Endless 2.0, which does not carry the eight-slot tray.
    static let endlessIIHudUnits: CGFloat = 4.7

    /// Clearance from the physical top edge to the HUD, in points, used instead of
    /// `safeAreaInsets.top`.
    static let hudTopClearance: CGFloat = 20

    /// How solid each wall is, when the border it fills is thinner than this.
    ///
    /// Costs nothing on screen - the surplus is off the edge - and it means the play area never
    /// has to leave a margin behind just to keep its walls.
    static let minimumWallThickness: CGFloat = 20

    let screen: CGSize
    let bottomInset: CGFloat
    /// The width of the play area, which everything else is measured in.
    let gameWidth: CGFloat
    /// The height of the bar above the playfield.
    let topBarHeight: CGFloat

    var layoutUnit: CGFloat { gameWidth/CGFloat(GameSceneLayout.brickRows) }
    var brickWidth: CGFloat { layoutUnit*2 }
    var brickHeight: CGFloat { layoutUnit }

    /// The playfield proper - the fixed-ratio rectangle the ball is confined to.
    var playHeight: CGFloat { gameWidth*GameSceneLayout.playRatio }

    /// How much room is left either side of the play area.
    var borderWidth: CGFloat { (screen.width - gameWidth)/2 }
    /// And how wide the walls filling it are drawn, which is not the same thing - a wall
    /// thinner than this would have no physics body, so it takes a minimum and runs off the
    /// edge of the screen instead.
    var wallThickness: CGFloat { max(borderWidth, GameSceneLayout.minimumWallThickness) }

    /// The gap above the first brick row, in Classic and Endless. Endless 2.0 starts its field
    /// at the top of the play area instead.
    var topGap: CGFloat { brickHeight*2 }
    /// The gap between the bottom brick row and the paddle.
    var paddleGap: CGFloat { layoutUnit*7 }

    /// How far the paddle's centre sits above the bottom of the screen, in the game.
    ///
    /// The scene's own line (`paddlePositionY`), measured from the other end: the screen, less
    /// the bar, the gap above the bricks, the bricks themselves, the gap under them and half
    /// the paddle. About a fifth of the screen on a modern phone, and all of it is where the
    /// thumb goes - which is why the paddle-speed screen needs this number rather than the
    /// clearance between the paddle and the line a lost ball crosses (James, round 147: "there
    /// needs to be more room below the paddle for the user's thumb").
    var paddleCentreAboveScreenBottom: CGFloat {
        screen.height - topBarHeight - topGap
            - CGFloat(GameSceneLayout.brickRows)*brickHeight - paddleGap - paddleHeight/2
    }

    var ballSize: CGFloat { layoutUnit*0.67 }
    var paddleWidth: CGFloat { ballSize*7.5 }
    var paddleHeight: CGFloat { ballSize }

    /// Sized from the space actually available, holding a fixed ratio.
    ///
    /// Solved in closed form because the top bar's height depends on `layoutUnit`, which
    /// depends on `gameWidth`, which depends on the bar. Clamped to the available width so
    /// short, wide layouts fall back to taller borders rather than a reshaped playfield.
    init(screen: CGSize, bottomInset: CGFloat = 0, sideInsets: CGFloat = 0,
         hudUnits: CGFloat = GameSceneLayout.hudUnits) {
        self.screen = screen
        self.bottomInset = bottomInset

        let availableHeight = screen.height - GameSceneLayout.hudTopClearance - bottomInset
        let availableWidth = screen.width - sideInsets

        let rows = CGFloat(GameSceneLayout.brickRows)
        let width = (availableHeight/(1 + hudUnits/(rows*GameSceneLayout.playRatio)))
            / GameSceneLayout.playRatio
        gameWidth = max(0, min(width, availableWidth))
        topBarHeight = GameSceneLayout.hudTopClearance
            + (gameWidth/rows)*hudUnits
    }
}
