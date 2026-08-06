//
//  EndlessIIMarkers.swift
//  Megaball
//
//  The hundred-metre lines that drift down behind the field.
//
//  Height in Endless is a number in a corner, and a number in a corner is hard to feel. The
//  field descending is the thing the player actually watches, so putting the milestones into
//  that motion is what turns a score into a sense of distance travelled - you see 300m coming
//  before you reach it, and you see it go past.
//
//  Behind everything, dim, and never in the way. A marker competing with the bricks for
//  attention would be worse than no marker at all.
//

import SpriteKit

extension GameScene {

    static let endlessIIMarkerName = "endlessIIMarker"
    /// How often a line appears.
    static let endlessIIMarkerSpacing = 100

    /// Adds a line for this height if it is one worth marking.
    ///
    /// Created in the row that represents that height and then carried down with it, so it
    /// means "this is where 300m was" rather than "this is roughly 300m".
    func addEndlessIIMarkerIfDue() {
        guard gameMode == .endlessII, endlessHeight > 0 else { return }

        let best = totalStatsArray.first?.endlessIIHeights.max() ?? 0
        let isBest = best > 0 && endlessHeight == best
        let isHundred = endlessHeight % GameScene.endlessIIMarkerSpacing == 0
        guard isBest || isHundred else { return }

        let marker = SKNode()
        marker.name = GameScene.endlessIIMarkerName
        marker.position = CGPoint(x: 0, y: yBrickOffsetEndless + brickHeight/2)
        marker.zPosition = 0.6
        // Above the background and below the bricks, which sit at 1. A marker in front of the
        // field would be something to look past rather than something to notice
        addChild(marker)

        let line = SKShapeNode(rect: CGRect(x: -gameWidth/2, y: -0.5,
                                            width: gameWidth, height: 1))
        line.fillColor = isBest ? brickGreenGigaball : UIColor(white: 1, alpha: 0.16)
        line.strokeColor = .clear
        line.alpha = isBest ? 0.5 : 1
        marker.addChild(line)

        let label = SKLabelNode(fontNamed: scoreLabel.fontName)
        label.text = isBest ? "BEST \(best)m" : "\(endlessHeight)m"
        label.fontSize = fontSize*0.6
        label.fontColor = isBest ? brickGreenGigaball : UIColor(white: 1, alpha: 0.3)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .bottom
        label.position = CGPoint(x: -gameWidth/2 + labelSpacing, y: labelSpacing/3)
        marker.addChild(label)
        // Labelled, because an unlabelled line at 300m and one at 400m are the same line
    }

    /// Moves the markers down with the field, and clears the ones that have left it.
    ///
    /// Separate from the brick descent because markers are not bricks - they must not be
    /// counted, hit, or wait for the bottom row to clear before the field can move.
    func moveEndlessIIMarkersDown() {
        guard gameMode == .endlessII else { return }
        let move = SKAction.moveBy(x: 0, y: -brickHeight, duration: 0.05)

        enumerateChildNodes(withName: GameScene.endlessIIMarkerName) { node, _ in
            if node.position.y <= -self.frame.size.height/2 {
                node.removeFromParent()
                return
            }
            node.run(move)
        }
    }

    func clearEndlessIIMarkers() {
        enumerateChildNodes(withName: GameScene.endlessIIMarkerName) { node, _ in
            node.removeFromParent()
        }
    }
}
