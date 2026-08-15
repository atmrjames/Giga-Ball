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

    func resumeBrickCreation() {
        guard let savedGame else { return }
        // Same as resumeGame: bound once instead of unwrapped at every use

        
        if levelNumber == 0 {
            prepEndlessMode(height: savedGame.endlessHeight)
        }

        powerUpProbAllocation(levelNumber: levelNumber)
        
        var brickArray: [SKNode] = []
        // Array to store all bricks
        
        for i in 0..<savedGame.brickTextures.count {
            let brick = SKSpriteNode(imageNamed: "BrickNormal")
                        
            var brickTexture: SKTexture?
            switch savedGame.brickTextures[i] {
            case 0:
                brickTexture = brickNormalTexture
                brick.isHidden = false
            case 1:
                brickTexture = brickNormalTexture
                brick.isHidden = true
            case 2:
                brickTexture = brickInvisibleTexture
                brick.isHidden = false
            case 3:
                brickTexture = brickInvisibleTexture
                brick.isHidden = true
            case 4:
                brickTexture = brickMultiHit1Texture
            case 5:
                brickTexture = brickMultiHit2Texture
            case 6:
                brickTexture = brickMultiHit3Texture
            case 7:
                brickTexture = brickMultiHit4Texture
            case 8:
                brickTexture = brickIndestructible1Texture
            case 9:
                brickTexture = brickIndestructible2Texture
            case 10:
                brickTexture = brickNullTexture
            default:
                brickTexture = brickNormalTexture
            }

            if let hidden = savedGame.brickHidden, hidden.indices.contains(i) {
                brick.isHidden = hidden[i]
            }
            // The saved field's own word beats the texture encoding: the texture index
            // only carries hidden for two of the types, and a Fog of War day fogs them
            // all - resuming re-fogged everything the run had revealed (play-test
            // round 8). Saves from before the array exists keep the old behaviour
            brick.texture = brickTexture!
            
            if savedGame.brickColours.count > 0 {
                var brickColour: UIColor?
                switch savedGame.brickColours[i] {
                case 0:
                    brickColour = brickBlue
                case 1:
                    brickColour = brickBlueDark
                case 2:
                    brickColour = brickBlueDarkExtra
                case 3:
                    brickColour = brickBlueLight
                case 4:
                    brickColour = brickGreenGigaball
                case 5:
                    brickColour = brickGreenSI
                case 6:
                    brickColour = brickGrey
                case 7:
                    brickColour = brickGreyDark
                case 8:
                    brickColour = brickGreyLight
                case 9:
                    brickColour = brickOrange
                case 10:
                    brickColour = brickOrangeDark
                case 11:
                    brickColour = brickOrangeLight
                case 12:
                    brickColour = brickPink
                case 13:
                    brickColour = brickPurple
                case 14:
                    brickColour = brickWhite
                case 15:
                    brickColour = brickYellow
                case 16:
                    brickColour = brickYellowLight
                
                case 17:
                    brickColour = brickBrown
                case 18:
                    brickColour = brickBrownLight
                case 19:
                    brickColour = brickGreen
                case 20:
                    brickColour = brickGreenDark
                case 21:
                    brickColour = brickGreenLight
                case 22:
                    brickColour = brickPurpleDark
                case 23:
                    brickColour = brickYellowDark
                default:
                    brickColour = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
                }
                if brick.texture == brickNormalTexture && brickColour != nil {
                    brick.color = brickColour!
                }
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
        
        
        
        


