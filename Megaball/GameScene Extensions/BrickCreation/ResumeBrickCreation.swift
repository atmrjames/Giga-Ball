//
//  ResumeBrickCreation.swift
//  Megaball
//
//  Created by James Harding on 31/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {

    /// The height of row zero for the mode being resumed.
    ///
    /// Stated once and named, because it is the same question the *save* asks when it turns
    /// a brick's height into a row index - and the two disagreeing is exactly what round
    /// 126 was.
    var resumedBrickTopRow: CGFloat {
        endlessMode ? yBrickOffsetEndless : yBrickOffset
    }

    /// One brick, described well enough to be put back exactly (round 150).
    ///
    /// Everything the four legacy arrays cannot say: the size a Tiny or Big brick actually
    /// is, the anchor a Big brick hangs from, the exact position a Moving or drifting brick
    /// had reached, and every style it was wearing.
    func savedBrick(for sprite: SKSpriteNode, texture: Int, colour: Int,
                    restingY: CGFloat) -> SavedGame.SavedBrick {
        SavedGame.SavedBrick(
            texture: texture,
            colour: colour,
            x: Double(sprite.position.x),
            y: Double(restingY),
            width: Double(sprite.size.width),
            height: Double(sprite.size.height),
            anchorX: Double(sprite.anchorPoint.x),
            anchorY: Double(sprite.anchorPoint.y),
            hidden: sprite.isHidden,
            role: sprite.endlessIIRole?.rawValue,
            face: sprite.endlessIIFace?.rawValue,
            styles: endlessIIStyles(on: sprite)
                .filter { $0 == .rounded || $0 == .spinning || $0 == .flashing
                    || $0 == .breathing }
                .map(\.rawValue),
            // Only the four tracked by identity or by a child node. The rest are roles and
            // faces, which have their own fields - saving a style twice is a way for the two
            // copies to disagree
            portalBlue: sprite.endlessIIPortalIsBlue,
            anchored: sprite.endlessIIIsAnchored,
            powerUpIndex: sprite.endlessIIPowerUpIndex,
            staysPlain: sprite.endlessIIStaysPlain)
    }

    /// Rebuilds the Mayhem field from the rich record, exactly as it was left.
    ///
    /// Returns whether it did: a save written before round 150, or any other mode, falls
    /// through to the cell-index path below.
    @discardableResult
    func resumeEndlessIIBricks() -> Bool {
        guard gameMode == .endlessII,
              let saved = savedGame?.endlessIIBricks, saved.isEmpty == false else {
            return false
        }

        for record in saved {
            let brick = SKSpriteNode(imageNamed: "BrickNormal")
            brick.texture = resumedTexture(record.texture) ?? brickNormalTexture
            brick.isHidden = record.hidden
            if let colour = resumedColour(record.colour), brick.texture == brickNormalTexture {
                brick.color = colour
                brick.colorBlendFactor = 1
            }
            brick.size = CGSize(width: record.width, height: record.height)
            brick.anchorPoint = CGPoint(x: record.anchorX, y: record.anchorY)
            brick.position = CGPoint(x: record.x, y: record.y)
            brick.zPosition = 1
            brick.name = BrickCategoryName

            let centre = CGPoint(x: (0.5 - brick.anchorPoint.x)*brick.size.width,
                                 y: (0.5 - brick.anchorPoint.y)*brick.size.height)
            brick.physicsBody = brickBody(SKPhysicsBody(rectangleOf: brick.size,
                                                        center: centre))
            // The body follows the sprite rather than the node, which is the whole of how a
            // Big brick keeps its node on a row centre (§8.6)

            brick.endlessIIStaysPlain = record.staysPlain
            brick.endlessIIIsAnchored = record.anchored
            brick.endlessIIPortalIsBlue = record.portalBlue
            brick.endlessIIPowerUpIndex = record.powerUpIndex
            addChild(brick)

            if let raw = record.role, let role = EndlessIIRole(rawValue: raw) {
                applyEndlessIIStyle(style(for: role), to: brick)
            }
            if let raw = record.face, let face = EndlessIIFace(rawValue: raw) {
                applyEndlessIIStyle(face.style, to: brick)
            }
            for raw in record.styles {
                guard let style = EndlessIIStyle(rawValue: raw) else { continue }
                applyEndlessIIStyle(style, to: brick)
            }
            // Applied through the same call the generator uses, so a restored spinner is in
            // the spinners list, a restored flasher is in the flashers list, and a restored
            // breather breathes - which is what "the same field" has to mean

            brick.endlessIIIsAnchored = record.anchored
            // Set again: `makeFixed` starts a brick unanchored, and a Fixed brick that had
            // already been struck must come back struck
            bricksLeft += 1
        }

        applyEndlessIIPowerUpSchedule()
        showEndlessIIBest()
        seedEndlessIIMarkers()
        countBricks()
        resumeGame()
        return true
    }

    /// The role a style stands for, which is the same list `endlessIIStyles(on:)` reads back.
    private func style(for role: EndlessIIRole) -> EndlessIIStyle {
        switch role {
        case .gravity: return .gravity
        case .moving: return .moving
        case .directional: return .directional
        case .exploding: return .exploding
        case .spawner: return .spawner
        case .portal: return .portal
        case .fixed: return .fixed
        }
    }

    // MARK: - What a saved index means

    /// The texture a saved index stands for. One mapping, asked by both restore paths -
    /// the cell-index one every mode has always used and Mayhem's own (round 150).
    func resumedTexture(_ index: Int) -> SKTexture? {
        switch index {
        case 0: return brickNormalTexture
        case 1: return brickNormalTexture
        case 2: return brickInvisibleTexture
        case 3: return brickInvisibleTexture
        case 4: return brickMultiHit1Texture
        case 5: return brickMultiHit2Texture
        case 6: return brickMultiHit3Texture
        case 7: return brickMultiHit4Texture
        case 8: return brickIndestructible1Texture
        case 9: return brickIndestructible2Texture
        case 10: return brickNullTexture
        default: return brickNormalTexture
        }
    }

    /// Whether a saved index means hidden. The index carries it for two of the types only,
    /// which is why the save writes the flag separately as well - a Fog of War day fogs
    /// every type, and resuming used to reveal everything the run had hidden (round 8).
    func resumedIsHidden(_ index: Int, saved: Bool?) -> Bool {
        if let saved { return saved }
        return index == 1 || index == 3
    }

    /// The colour a saved index stands for, for the plain bricks that carry one.
    func resumedColour(_ index: Int) -> UIColor? {
        switch index {
        case 0: return brickBlue
        case 1: return brickBlueDark
        case 2: return brickBlueDarkExtra
        case 3: return brickBlueLight
        case 4: return brickGreenGigaball
        case 5: return brickGreenSI
        case 6: return brickGrey
        case 7: return brickGreyDark
        case 8: return brickGreyLight
        case 9: return brickOrange
        case 10: return brickOrangeDark
        case 11: return brickOrangeLight
        case 12: return brickPink
        case 13: return brickPurple
        case 14: return brickWhite
        case 15: return brickYellow
        case 16: return brickYellowLight
        case 17: return brickBrown
        case 18: return brickBrownLight
        case 19: return brickGreen
        case 20: return brickGreenDark
        case 21: return brickGreenLight
        case 22: return brickPurpleDark
        case 23: return brickYellowDark
        default: return nil
        }
    }

    func resumeBrickCreation() {
        guard let savedGame else { return }
        if resumeEndlessIIBricks() { return }
        // Mayhem puts its own field back, brick for brick. Everything else - Classic, the
        // original Endless, and any Mayhem save written before round 150 - takes the cell
        // path below, which is what those modes have always used
        // Same as resumeGame: bound once instead of unwrapped at every use

        
        if levelNumber == 0 {
            prepEndlessMode(height: savedGame.endlessHeight)
        }

        powerUpProbAllocation(levelNumber: levelNumber)
        
        var brickArray: [SKNode] = []
        // Array to store all bricks
        
        for i in 0..<savedGame.brickTextures.count {
            let brick = SKSpriteNode(imageNamed: "BrickNormal")
                        
            brick.texture = resumedTexture(savedGame.brickTextures[i])
            let savedHidden = savedGame.brickHidden.flatMap {
                $0.indices.contains(i) ? $0[i] : nil
            }
            brick.isHidden = resumedIsHidden(savedGame.brickTextures[i], saved: savedHidden)
            if brick.texture == brickNormalTexture,
               let colour = resumedColour(savedGame.brickColours[i]) {
                brick.color = colour
            }
            // Assign brick texture & colour
            
            let brickPositionX = savedGame.brickXPositions[i]
            let brickPositionY = savedGame.brickYPositions[i]
            let topRow = resumedBrickTopRow
            brick.position = CGPoint(x: gameWidth/2 - brickWidth/2 - brickWidth*CGFloat(brickPositionX),
                                     y: topRow - brickHeight*CGFloat(brickPositionY))
            // Assign brick position.
            //
            // **The row index is measured from the mode's own top row, and must be restored
            // against the same one** (play-test round 126). The save writes it against
            // `yBrickOffsetEndless` in the endless modes, whose field starts at the top of
            // the play area, and against `yBrickOffset` in Classic, which leaves a two-row
            // gap under the bar - and this line restored *both* against the Classic offset.
            // Every resume therefore put the whole field two brick rows lower than it was,
            // and because the shifted field is what gets saved next time it happened again
            // on every quit: "each time I quit the app and restarted, the bricks were lower",
            // eventually below the line the run is lost at
            
            brickArray.append(brick)
        }
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }

}
        
        
        
        


