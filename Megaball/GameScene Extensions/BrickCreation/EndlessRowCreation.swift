//
//  EndlessRowCreation.swift
//  Megaball
//
//  Created by James Harding on 19/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    
    func buildNewEndlessRow() {
        
        var brickArray: [SKNode] = []
        // Array to store all bricks
        
        var normalProb: Int?
        var mHThreeProb: Int?
        var mHTwoProb: Int?
        var mHOneProb: Int?
        var indestTwoProb: Int?
        var indestOneProb: Int?
        var invisiProb: Int?
        // Setup individual brick probability variables
        
        var randRowProb: Int?
        var nullRowProb: Int?
        var normalSemiRowProb: Int?
        var normalFullRowProb: Int?
        var invisibleSemiRowProb: Int?
        var invisibleFullRowProb: Int?
        var multiHitSemiRowProb: Int?
        var multiHitFullRowProb: Int?
        var indestructible1SemiRowProb: Int?
        var indestructible2SemiRowProb: Int?
        var indestructibleMixSemiRowProb: Int?
        // Setup random row brick probability variables
        
        let rare = Int.random(in: 1...3)
        let few = Int.random(in: 2...6)
        let infrequent = Int.random(in: 4...10)
        let several = Int.random(in: 7...15)
        let frequent = Int.random(in: 15...25)
        let many = Int.random(in: 25...35)
        // Set brick frequency limits
        
        let randRow = Int.random(in: 1...100)
        let randRowSelect = Int.random(in: 1...100)
        // Random pre-defined row selector
                
        powerUpProbArray[7] = 7 // Gravity
        powerUpProbArray[18] = 5 // Reset Multi-Hit Bricks
        powerUpProbArray[19] = 5 // Remove Indestructible Bricks
        powerUpProbArray[21] = 3 // Undestructi-Ball
        
        advanceEndlessIIPhase()
        // Checked per row, so a phase ends where it ends rather than on a schedule

        let milestoneRow = endlessIIRowIsMilestone
        let endlessII = endlessIIReserveOrBuildBig()
        let setRow = milestoneRow
            ? nil
            : endlessIINextSetRow(reservationPending: endlessII.skip.isEmpty == false)
        // A designed pattern is not started on a row that is about to be emptied, or its first
        // row would be thrown away and the rest would arrive without it
        // Asked after the reservation so a pattern never starts on a row that is already
        // being shaped by a Big brick or a spinner
        // Endless 2.0 only. Either this row leaves a gap for a Big brick, or it builds the
        // one the row before it left a gap for

        for j in 0..<numberOfBrickColumns {
            let brick = SKSpriteNode(imageNamed: "BrickNormal")

            normalProb = 0
            mHThreeProb = 0
            mHTwoProb = 0
            mHOneProb = 0
            indestTwoProb = 0
            indestOneProb = 0
            invisiProb = 0
            
            randRowProb = 0
            nullRowProb = 0
            normalSemiRowProb = 0
            normalFullRowProb = 0
            invisibleSemiRowProb = 0
            invisibleFullRowProb = 0
            multiHitSemiRowProb = 0
            multiHitFullRowProb = 0
            indestructible1SemiRowProb = 0
            indestructible2SemiRowProb = 0
            indestructibleMixSemiRowProb = 0
            
            if endlessHeight < height01! {
                normalProb = several
                mHThreeProb = rare
                // Brick probs

                randRowProb = 0
            }

            if endlessHeight >= height01! && endlessHeight < height02! {
                normalProb = several
                mHThreeProb = rare
                // Brick probs

                randRowProb = 4
                normalSemiRowProb = 100
                // Row probs
            }

            if endlessHeight >= height02! && endlessHeight < height03! {
                normalProb = several
                mHThreeProb = few
                indestTwoProb = rare
                // Brick probs

                randRowProb = 2
                normalFullRowProb = 100
                // Row probs
            }

            if endlessHeight >= height03! && endlessHeight < height04! {
                normalProb = several
                mHThreeProb = few
                mHTwoProb = rare
                indestTwoProb = rare
                // Brick probs

                randRowProb = 4
                normalFullRowProb = 100
                // Row probs
            }
            
            if endlessHeight >= height04! && endlessHeight < height05! {
                switch endlessBrickMode01 {
                    case 1:
                        normalProb = several
                    case 2:
                        mHThreeProb = several
                        powerUpProbArray[18] = 0 // Reset Multi-Hit Bricks
                    case 3:
                        normalProb = several
                    case 4:
                        mHThreeProb = several
                        powerUpProbArray[18] = 0 // Reset Multi-Hit Bricks
                    default:
                        break
                }
            }
            
            if endlessHeight >= height05! && endlessHeight < height06! {
                normalProb = frequent
                mHThreeProb = few
                mHTwoProb = rare
                indestTwoProb = rare
                // Brick probs
                
                randRowProb = 4
                normalSemiRowProb = 50
                normalFullRowProb = 50
                // Row probs
            }
            
            if endlessHeight >= height06! && endlessHeight < height07! {
                normalProb = frequent
                mHThreeProb = few
                mHTwoProb = rare
                indestTwoProb = rare
                indestOneProb = rare
                // Brick probs
                
                randRowProb = 4
                normalSemiRowProb = 20
                normalFullRowProb = 20
                indestructible1SemiRowProb = 20
                indestructible2SemiRowProb = 20
                indestructibleMixSemiRowProb = 20
                // Row probs
            }
            
            if endlessHeight >= height07! && endlessHeight < height08! {
                normalProb = frequent
                mHThreeProb = few
                mHTwoProb = rare
                mHOneProb = rare
                indestTwoProb = rare
                indestOneProb = rare
                // Brick probs
                
                randRowProb = 2
                multiHitSemiRowProb = 100
                // Row probs
            }

            if endlessHeight >= height08! && endlessHeight < height09! {
                switch endlessBrickMode02 {
                    case 1:
                        normalProb = frequent
                    case 2:
                        mHThreeProb = frequent
                        powerUpProbArray[18] = 0 // Reset Multi-Hit Bricks
                    case 3:
                        mHTwoProb = frequent
                        powerUpProbArray[18] = 0 // Reset Multi-Hit Bricks
                    case 4:
                        mHThreeProb = frequent
                        powerUpProbArray[18] = 0 // Reset Multi-Hit Bricks
                    default:
                        break
                }
            }
            
            if endlessHeight >= height09! && endlessHeight < height10! {
                normalProb = frequent
                mHThreeProb = few
                mHTwoProb = rare
                mHOneProb = rare
                indestTwoProb = rare
                indestOneProb = rare
                invisiProb = few
                // Brick probs
                
                randRowProb = 4
                nullRowProb = 10
                normalSemiRowProb = 10
                normalFullRowProb = 10
                invisibleSemiRowProb = 10
                invisibleFullRowProb = 10
                multiHitSemiRowProb = 10
                multiHitFullRowProb = 10
                indestructible1SemiRowProb = 10
                indestructible2SemiRowProb = 10
                indestructibleMixSemiRowProb = 10
                // Row probs
            }
            
            if endlessHeight >= height10! && endlessHeight < height11! {
                normalProb = many
                mHThreeProb = few
                mHTwoProb = rare
                mHOneProb = rare
                indestTwoProb = rare
                indestOneProb = rare
                invisiProb = infrequent
                // Brick probs
                
                randRowProb = 8
                nullRowProb = 100
                // Row probs
            }
            
            if endlessHeight >= height11! && endlessHeight < height12! {
                normalProb = many
                mHThreeProb = few
                mHTwoProb = few
                mHOneProb = rare
                indestTwoProb = rare
                indestOneProb = rare
                invisiProb = infrequent
                // Brick probs
                
                randRowProb = 8
                nullRowProb = 10
                normalSemiRowProb = 10
                normalFullRowProb = 10
                invisibleSemiRowProb = 10
                invisibleFullRowProb = 10
                multiHitSemiRowProb = 10
                multiHitFullRowProb = 10
                indestructible1SemiRowProb = 10
                indestructible2SemiRowProb = 10
                indestructibleMixSemiRowProb = 10
                // Row probs
            }
            
            if endlessHeight >= height12! && endlessHeight < height13! {
                switch endlessBrickMode03 {
                    case 1:
                        normalProb = many
                    case 2:
                        mHTwoProb = many
                        powerUpProbArray[18] = 0 // Reset Multi-Hit Bricks
                    case 3:
                        invisiProb = many
                    case 4:
                        indestOneProb = infrequent
                        powerUpProbArray[7] = 0 // Gravity
                        powerUpProbArray[19] = 0 // Remove Indestructible Bricks
                        powerUpProbArray[21] = 0 // Undestructi-Ball
                        // Remove power-ups that aren't suited to indestructible only bricks
                    default:
                        break
                }
            }
            
            if endlessHeight >= height13! && endlessHeight < height14! {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = few
                mHOneProb = rare
                indestTwoProb = few
                indestOneProb = rare
                invisiProb = infrequent
                // Brick probs
                
                randRowProb = 4
                nullRowProb = 10
                normalSemiRowProb = 10
                normalFullRowProb = 10
                invisibleSemiRowProb = 10
                invisibleFullRowProb = 10
                multiHitSemiRowProb = 10
                multiHitFullRowProb = 10
                indestructible1SemiRowProb = 10
                indestructible2SemiRowProb = 10
                indestructibleMixSemiRowProb = 10
                // Row probs
            }
            
            if endlessHeight >= height14! && endlessHeight < height15! {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = few
                mHOneProb = few
                indestTwoProb = few
                indestOneProb = few
                invisiProb = infrequent
                // Brick probs
                
                randRowProb = 4
                nullRowProb = 10
                normalSemiRowProb = 10
                normalFullRowProb = 10
                invisibleSemiRowProb = 10
                invisibleFullRowProb = 10
                multiHitSemiRowProb = 10
                multiHitFullRowProb = 10
                indestructible1SemiRowProb = 10
                indestructible2SemiRowProb = 10
                indestructibleMixSemiRowProb = 10
                // Row probs
            }
            
            if endlessHeight >= height15! && endlessHeight < height16! {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = infrequent
                mHOneProb = few
                indestTwoProb = few
                indestOneProb = few
                invisiProb = frequent
                // Brick probs
                
                randRowProb = 2
                invisibleSemiRowProb = 50
                invisibleFullRowProb = 50
                // Row probs
            }
            
            if endlessHeight >= height16! && endlessHeight < height17! {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = infrequent
                mHOneProb = few
                indestTwoProb = few
                indestOneProb = infrequent
                invisiProb = frequent
                // Brick probs
                
                randRowProb = 4
                nullRowProb = 10
                normalSemiRowProb = 10
                normalFullRowProb = 10
                invisibleSemiRowProb = 10
                invisibleFullRowProb = 10
                multiHitSemiRowProb = 10
                multiHitFullRowProb = 10
                indestructible1SemiRowProb = 10
                indestructible2SemiRowProb = 10
                indestructibleMixSemiRowProb = 10
                // Row probs
            }
            
            if endlessHeight >= height17! && endlessHeight < height18! {
                normalProb = several
                mHThreeProb = infrequent
                mHTwoProb = infrequent
                mHOneProb = few
                indestTwoProb = infrequent
                indestOneProb = infrequent
                invisiProb = frequent
                // Brick probs
                
                randRowProb = 4
                nullRowProb = 10
                normalSemiRowProb = 10
                normalFullRowProb = 10
                invisibleSemiRowProb = 10
                invisibleFullRowProb = 10
                multiHitSemiRowProb = 10
                multiHitFullRowProb = 10
                indestructible1SemiRowProb = 10
                indestructible2SemiRowProb = 10
                indestructibleMixSemiRowProb = 10
                // Row probs
            }
            
            if endlessHeight >= height18! && endlessHeight < height19! {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = infrequent
                mHOneProb = infrequent
                indestTwoProb = infrequent
                indestOneProb = infrequent
                invisiProb = frequent
                // Brick probs
                
                randRowProb = 4
                nullRowProb = 10
                normalSemiRowProb = 10
                normalFullRowProb = 10
                invisibleSemiRowProb = 10
                invisibleFullRowProb = 10
                multiHitSemiRowProb = 10
                multiHitFullRowProb = 10
                indestructible1SemiRowProb = 10
                indestructible2SemiRowProb = 10
                indestructibleMixSemiRowProb = 10
                // Row probs
            }
            
            if endlessHeight >= height19! && endlessHeight < height20! {
                switch endlessBrickMode04 {
                    case 1:
                        normalProb = Int(round(Double(many)*1.5))
                    case 2:
                        mHOneProb = Int(round(Double(many)*1.5))
                        powerUpProbArray[18] = 0 // Reset Multi-Hit Bricks
                    case 3:
                        invisiProb = Int(round(Double(many)*1.5))
                    case 4:
                        indestOneProb = infrequent
                        powerUpProbArray[7] = 0 // Gravity
                        powerUpProbArray[19] = 0 // Remove Indestructible Bricks
                        powerUpProbArray[21] = 0 // Undestructi-Ball
                        // Remove power-ups that aren't suited to indestructible only bricks
                    default:
                        break
                }
            }
            
            if endlessHeight >= height20! {
                normalProb = many
                mHThreeProb = several
                mHTwoProb = infrequent
                mHOneProb = infrequent
                indestTwoProb = infrequent
                indestOneProb = infrequent
                invisiProb = several
                // Brick probs
                
                randRowProb = 4
                nullRowProb = 10
                normalSemiRowProb = 10
                normalFullRowProb = 10
                invisibleSemiRowProb = 10
                invisibleFullRowProb = 10
                multiHitSemiRowProb = 10
                multiHitFullRowProb = 10
                indestructible1SemiRowProb = 10
                indestructible2SemiRowProb = 10
                indestructibleMixSemiRowProb = 10
                // Row probs
            }
            
            brick.texture = brickNullTexture
            
            mHThreeProb = normalProb! + mHThreeProb!
            mHTwoProb = mHThreeProb! + mHTwoProb!
            mHOneProb = mHTwoProb! + mHOneProb!
            indestTwoProb = mHOneProb! + indestTwoProb!
            indestOneProb = indestTwoProb! + indestOneProb!
            invisiProb = indestOneProb! + invisiProb!
            
            if randRow >= randRowProb! {
                let randomBrick = Int.random(in: 1...100)
                if randomBrick <= normalProb! {
                    brick.texture = brickNormalTexture
                } else if randomBrick > normalProb! && randomBrick <= mHThreeProb! {
                    brick.texture = brickMultiHit3Texture
                } else if randomBrick > mHThreeProb! && randomBrick <= mHTwoProb! {
                    brick.texture = brickMultiHit2Texture
                } else if randomBrick > mHTwoProb! && randomBrick <= mHOneProb! {
                    brick.texture = brickMultiHit1Texture
                } else if randomBrick > mHOneProb! && randomBrick <= indestTwoProb! {
                    brick.texture = brickIndestructible2Texture
                } else if randomBrick > indestTwoProb! && randomBrick <= indestOneProb! {
                    brick.texture = brickIndestructible1Texture
                } else if randomBrick > indestOneProb! && randomBrick <= invisiProb! {
                    brick.texture = brickInvisibleTexture
                }
            } else {
                normalSemiRowProb = nullRowProb! + normalSemiRowProb!
                normalFullRowProb = normalSemiRowProb! + normalFullRowProb!
                invisibleSemiRowProb = normalFullRowProb! + invisibleSemiRowProb!
                invisibleFullRowProb = invisibleSemiRowProb! + invisibleFullRowProb!
                multiHitSemiRowProb = invisibleFullRowProb! + multiHitSemiRowProb!
                multiHitFullRowProb = multiHitSemiRowProb! + multiHitFullRowProb!
                indestructible1SemiRowProb = multiHitFullRowProb! + indestructible1SemiRowProb!
                indestructible2SemiRowProb = indestructible1SemiRowProb! + indestructible2SemiRowProb!
                indestructibleMixSemiRowProb = indestructible2SemiRowProb! + indestructibleMixSemiRowProb!
                
                if randRowSelect <= nullRowProb! {
                    brick.texture = brickNullTexture
                } else if randRowSelect > nullRowProb! && randRowSelect <= normalSemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickNormalTexture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > normalSemiRowProb! && randRowSelect <= normalFullRowProb! {
                    brick.texture = brickNormalTexture
                } else if randRowSelect > normalFullRowProb! && randRowSelect <= invisibleSemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickInvisibleTexture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > invisibleSemiRowProb! && randRowSelect <= invisibleFullRowProb! {
                    brick.texture = brickInvisibleTexture
                } else if randRowSelect > invisibleFullRowProb! && randRowSelect <= multiHitSemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickMultiHit1Texture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > multiHitSemiRowProb! && randRowSelect <= multiHitFullRowProb! {
                    brick.texture = brickMultiHit1Texture
                } else if randRowSelect > multiHitFullRowProb! && randRowSelect <= indestructible1SemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickIndestructible1Texture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > indestructible1SemiRowProb! && randRowSelect <= indestructible2SemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickIndestructible2Texture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > indestructible2SemiRowProb! && randRowSelect <= indestructibleMixSemiRowProb! {
                    if j == 0 || j == 4 || j == 8 {
                        brick.texture = brickIndestructible2Texture
                    } else if j == 2 || j == 6 || j == 10  {
                        brick.texture = brickIndestructible1Texture
                    } else {
                        brick.texture = brickNullTexture
                    }
                }
            }
            
            if milestoneRow {
                brick.texture = brickNullTexture
                // The row a hundred-metre line is about to arrive in, left empty so the line
                // can be read. Everything else about generation carries on around it
            } else if let setRow {
                brick.texture = endlessIISetRowTexture(setRow, column: j)
                brick.endlessIIStaysPlain = true
                // A designed row stays as designed. Styling it would be overwriting the one
                // thing that makes it different from the rows either side
            } else if gameMode == .endlessII {
                brick.texture = endlessIIBrickTexture()
            }
            // Endless 2.0 generates its own mix. The inherited height bands were built for a
            // mode that starts at its full density and only varies which bricks fill it;
            // this one has to start nearly empty and grow, and has its own idea of what a
            // deep field is made of

            if endlessII.skip.contains(j) {
                brick.texture = brickNullTexture
            }
            // Kept clear for a Big brick. Null bricks are already removed after the row's
            // animation and are not counted, so nothing else has to know why

            if brick.texture == brickNormalTexture {
                brick.color = brickWhite
                if endlessHeight >= 1000 {
                    brick.color = brickGreenGigaball
                }
            }

            if brick.texture == brickInvisibleTexture {
                brick.isHidden = true
            }
            
            brick.size.width = brickWidth
            brick.size.height = brickHeight
            brick.anchorPoint.x = 0.5
            brick.anchorPoint.y = 0.5
            brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffsetEndless)
            brick.physicsBody = SKPhysicsBody(rectangleOf: brick.frame.size)
            brick.physicsBody!.allowsRotation = false
            brick.physicsBody!.friction = 0.0
            brick.physicsBody!.affectedByGravity = false
            brick.physicsBody!.isDynamic = false
            brick.name = BrickCategoryName
            brick.physicsBody!.categoryBitMask = CollisionTypes.brickCategory.rawValue
            brick.physicsBody!.collisionBitMask = CollisionTypes.laserCategory.rawValue
            brick.physicsBody!.contactTestBitMask = CollisionTypes.laserCategory.rawValue
            brick.zPosition = 1
            brick.physicsBody!.usesPreciseCollisionDetection = true
            addChild(brick)
            brickArray.append(brick)

        }
        // Define brick properties

        if gameMode == .endlessII {
            endlessIIFillEmptyRowIfOverdue(brickArray)
        }
        // Checked before the two-row shapes are added, because those count as filling the row

        if let leftColumn = endlessII.dueAt {
            brickArray.append(endlessIIMakeBig(leftColumn: leftColumn, rowY: yBrickOffsetEndless))
        }

        if let column = endlessII.powerUpAt,
           let brick = endlessIIMakePowerUpBrick(column: column, rowY: yBrickOffsetEndless) {
            brickArray.append(brick)
        }
        // Appended with the rest so it animates in and is counted like any other brick

        let startingScale = SKAction.scale(to: 0.8, duration: 0)
        let startingFade = SKAction.fadeOut(withDuration: 0)
        let scaleUp = SKAction.scale(to: 1, duration: 0.05)
        let fadeIn = SKAction.fadeIn(withDuration: 0.05)
        let startingGroup = SKAction.group([startingScale, startingFade])
        let brickGroup = SKAction.group([scaleUp, fadeIn])
        // Setup brick animation
        
        for brick in brickArray {
            let brickCurrent = brick as! SKSpriteNode
            
            if brickCurrent.texture == brickNormalTexture {
                brickCurrent.colorBlendFactor = 1.0
            }
            
            brick.run(startingGroup)
            brick.alpha = 1.0
            // Pre animation setup
            
            if brickCurrent.texture == brickNullTexture {
                brickCurrent.isHidden = true
                brickCurrent.physicsBody = nil
            }
            // Hide and remove interaction for null bricks before animation down
            
            if brickCurrent.texture != self.brickNullTexture && brickCurrent.texture != self.brickIndestructible2Texture {
                self.bricksLeft += 1
            }
            // Add new bricks to brick count. Don't add non-active bricks
            
            brick.run(brickGroup, completion: {
                self.endlessMoveInProgress = false
                if brickCurrent.texture == self.brickNullTexture {
                    brickCurrent.removeFromParent()
                }
                // Remove null bricks after animation
            })
            // Run animation for each brick
        }

        if let column = endlessII.spinAt,
           let brick = brickArray.compactMap({ $0 as? SKSpriteNode })
            .first(where: { abs($0.position.x - (-gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(column))) < 1 }),
           endlessIICanTake(.spinning, brick) {
            makeSpinning(brick)
        }
        // The clearance around it was reserved two rows ago; whatever brick the generator
        // put here is the one that turns, whatever type it happens to be

        applyEndlessIIPowerUpSchedule()
        // After this row's own probability tweaks, so it damps the figures actually in use

        applyEndlessIISizes(to: &brickArray)
        applyEndlessIIBehaviours(to: brickArray)
        applyEndlessIIRoles(to: brickArray)
        // Endless 2.0 only, and after the animation above, which resets the colour blend

        if hapticsSetting {
            lightHaptic.impactOccurred()
        }
    }
    
}
