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

    /// How to read a save's point coordinates into the layout running now.
    ///
    /// Round 313, from James's iPad: a resume with "misplaced bricks below the low level line
    /// and no ball in sight". A save written before this - or one written in exactly this
    /// layout - gives the identity, so nothing that already worked changes.
    func resumeGeometry(for saved: SavedGame) -> ResumeGeometry {
        ResumeGeometry(saved: saved, gameWidth: gameWidth, fieldTop: resumedBrickTopRow)
            ?? ResumeGeometry(scale: 1, savedFieldTop: resumedBrickTopRow,
                              fieldTop: resumedBrickTopRow)
    }

    /// One brick, described well enough to be put back exactly (round 150).
    ///
    /// Everything the four legacy arrays cannot say: the size a Tiny or Big brick actually
    /// is, the anchor a Big brick hangs from, the exact position a Moving or drifting brick
    /// had reached, and every style it was wearing.
    /// The anchor a brick would have at its full size.
    ///
    /// `(0.5 - anchorPoint) * size` is where the drawing sits relative to the node, and every
    /// shrink is defined to hold it - so the anchor for the unshrunk cell falls straight out of
    /// it. A brick nothing has shrunk answers its own anchor, since its size *is* the cell.
    func resumedAnchor(of sprite: SKSpriteNode) -> CGPoint {
        let cell = endlessIIFieldSize(of: sprite)
        guard cell.width > 0, cell.height > 0 else { return sprite.anchorPoint }
        let centre = CGPoint(x: (0.5 - sprite.anchorPoint.x)*sprite.size.width,
                             y: (0.5 - sprite.anchorPoint.y)*sprite.size.height)
        return CGPoint(x: 0.5 - centre.x/cell.width, y: 0.5 - centre.y/cell.height)
    }

    func savedBrick(for sprite: SKSpriteNode, texture: Int, colour: Int,
                    restingY: CGFloat) -> SavedGame.SavedBrick {
        SavedGame.SavedBrick(
            texture: texture,
            colour: colour,
            x: Double(endlessIICanonicalRestingX(of: sprite)),
            y: Double(restingY),
            width: Double(endlessIIFieldSize(of: sprite).width),
            height: Double(endlessIIFieldSize(of: sprite).height),
            anchorX: Double(resumedAnchor(of: sprite).x),
            anchorY: Double(resumedAnchor(of: sprite).y),
            // **The cell it occupies, not the sprite hidden inside it.** `makeRounded` and
            // `makeFace` shrink the sprite so it disappears behind the face they build, and
            // the restore applies the style again from whatever it reads here - so saving the
            // shrunk sprite made a rounded brick 22% smaller on every resume, compounding.
            // The path is what still knows the cell (`endlessIIFieldSize`), and the anchor is
            // recovered from the drawn centre, which shrinking is defined to leave alone
            hidden: sprite.isHidden,
            role: sprite.endlessIIRole?.rawValue,
            face: sprite.endlessIIFace?.rawValue,
            faceMirrored: sprite.endlessIIFaceMirrored,
            faceFlipped: sprite.endlessIIFaceFlipped,
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
            staysPlain: sprite.endlessIIStaysPlain,
            vulnerableSide: sprite.endlessIIVulnerableSide?.rawValue)
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

        let intoThisLayout = resumeGeometry(for: savedGame!)

        for record in saved {
            let brick = SKSpriteNode(imageNamed: "BrickNormal")
            brick.texture = resumedTexture(record.texture) ?? brickNormalTexture
            brick.isHidden = record.hidden
            if let colour = resumedColour(record.colour), brick.texture == brickNormalTexture {
                brick.color = colour
                brick.colorBlendFactor = 1
            }
            brick.size = CGSize(width: intoThisLayout.length(record.width),
                                height: intoThisLayout.length(record.height))
            brick.anchorPoint = CGPoint(x: record.anchorX, y: record.anchorY)
            brick.position = intoThisLayout.point(CGPoint(x: record.x, y: record.y))
            // **The one part of a save that is in points** (James, round 313). A brick's cell
            // travels between layouts on its own, but Mayhem's record keeps an exact position
            // and size, because its bricks drift, shrink and sit between rows - and an iPad
            // does not always open at the size, or the orientation, the save was written in.
            // The anchor is a fraction of the size and needs no scaling
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

            if let raw = record.vulnerableSide, let side = EndlessIISide(rawValue: raw) {
                brick.endlessIIVulnerableSide = side
            }
            // Before the role is applied, for the reason the shaped face is: `makeDirectional`
            // rolls a side only when the brick does not already carry one, so this is what
            // stops a resumed brick being open somewhere else

            if let raw = record.role, let role = EndlessIIRole(rawValue: raw) {
                applyEndlessIIStyle(style(for: role), to: brick)
            }
            if let raw = record.face, let face = EndlessIIFace(rawValue: raw) {
                brick.endlessIIFaceMirrored = record.faceMirrored
                brick.endlessIIFaceFlipped = record.faceFlipped
                applyEndlessIIStyle(face.style, to: brick)
                // Orientation first: `makeFace` rolls one only when the brick does not
                // already carry it, so this is what stops a resumed wedge pointing the other
                // way and a resumed dome coming back the right way up
            }
            for raw in record.styles {
                guard let style = EndlessIIStyle(rawValue: raw) else { continue }
                applyEndlessIIStyle(style, to: brick)
            }
            // Applied through the same call the generator uses, so a restored spinner is in
            // the spinners list, a restored flasher is in the flashers list, and a restored
            // breather breathes - which is what "the same field" has to mean

            if brick.endlessIIFace != nil {
                resizeEndlessIIFace(brick, to: endlessIIFieldSize(of: brick))
            }
            // **The face is fitted last, because the size is decided last** (James, round 312:
            // "on returning from quitting and resuming, one of the wedge shaped bricks wasn't
            // lined up properly with the brick's shape grid").
            //
            // The face is built above, before `record.styles` - it has to be, because the
            // orientation must be in place before `makeFace` rolls one. But Big, Square and
            // Tiny are *styles*, and they change the cell the face is supposed to fill. So a
            // shaped brick that was also resized came back with its silhouette cut for the
            // cell it had before the style landed, which is a wedge sitting off its own grid.
            //
            // Re-fitting is the generator's own move: `resizeEndlessIIFace` exists because a
            // Breathing shaped brick has it done again on every breath, and it is written to be
            // called more than once

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
        // Same as resumeGame: bound once instead of unwrapped at every use

        if levelNumber == 0 {
            prepEndlessMode(height: savedGame.endlessHeight)
        }
        powerUpProbAllocation(levelNumber: levelNumber)
        // **Both of these belong above the Mayhem branch below, and used to sit under it.**
        //
        // A resumed run never goes through `Playing`'s `switch levelNumber` - that is the
        // fresh-level path - so this is the only place a level-0 resume is dressed as an
        // endless run: `prepEndlessMode` is what sets `endlessMode`, hides the lives row and
        // the multiplier, and turns the score label into a height. Mayhem returned before
        // reaching it, so a resumed Mayhem run came back wearing Classic's HUD - the score,
        // the multiplier and the ball container - over a field that still descended (James,
        // rounds 169 and 176, with a screenshot). It could not be reproduced in the original
        // Endless for the same reason: that mode falls through to the cell path and always
        // reached these two lines.
        //
        // `powerUpProbAllocation` was in the same trap and is the quieter half: a resumed
        // Mayhem run had every drop weight at zero until something else happened to call it,
        // so nothing fell from a brick.
        //
        // Hoisted rather than repeated inside the branch, and hoisted *above* it rather than
        // below: `prepEndlessMode` calls `resetEndlessIIBricks`, which empties the spinners,
        // flashers and breathers - run after the restore it would throw away the very lists
        // the restore had just filled.

        if resumeEndlessIIBricks() { return }
        // Mayhem puts its own field back, brick for brick. Everything else - Classic, the
        // original Endless, and any Mayhem save written before round 150 - takes the cell
        // path below, which is what those modes have always used
        
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
        
        
        
        


