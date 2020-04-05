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
        
        let randomRow = Int.random(in: 0...99)
        
        for j in 0..<numberOfBrickColumns {
            
            let brick = SKSpriteNode(imageNamed: "BrickNormal")
            brick.alpha = 0.0
            
            if randomRow >= 0 && randomRow <= 90 {
            // Fully random row
                
                let randomBrick = Int.random(in: 0...99)
                
                if randomBrick >= 0 && randomBrick <= 39 {
                    brick.texture = brickNormalTexture
                }
                else if randomBrick >= 40 && randomBrick <= 74 {
                    brick.texture = brickNullTexture
                }
                else if randomBrick >= 75 && randomBrick <= 84 {
                    brick.texture = brickInvisibleTexture
                }
                else if randomBrick >= 85 && randomBrick <= 91 {
                    brick.texture = brickMultiHit1Texture
                }
                else if randomBrick == 92 {
                    brick.texture = brickMultiHit2Texture
                }
                else if randomBrick == 93 {
                    brick.texture = brickMultiHit3Texture
                }
                else if randomBrick == 94 {
                    brick.texture = brickMultiHit4Texture
                }
                else if randomBrick >= 95 && randomBrick <= 96 {
                    brick.texture = brickIndestructible1Texture
                }
                else if randomBrick >= 97 && randomBrick <= 99 {
                    brick.texture = brickIndestructible2Texture
                } else {
                    brick.texture = brickNullTexture
                }
                // Chose a brick at random
            }
            
            if randomRow == 91 || randomRow == 92 {
            // Full row of normal bricks
                brick.texture = brickNormalTexture
            }
            
            if randomRow == 93 || randomRow == 94 {
            // Full row of null bricks
                brick.texture = brickNullTexture
            }
            
            if randomRow == 95 || randomRow == 96 {
            // Full row of invisible bricks
                brick.texture = brickInvisibleTexture
            }
            
            if randomRow == 97 || randomRow == 98 {
            // Full row of multihit bricks
                brick.texture = brickMultiHit1Texture
            }
            
            if randomRow == 99 {
            // Full row of indestructible bricks, with gaps
                if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                // Indestructible bricks
                    brick.texture = brickIndestructible2Texture
                } else {
                    brick.texture = brickNullTexture
                }
            }
            
            if brick.texture == brickInvisibleTexture {
                brick.isHidden = true
            }
            // Hide invisible and null bricks
            
            if brick.texture == brickNormalTexture {
                brick.color = brickWhite
            }
            
            brick.size.width = brickWidth
            brick.size.height = brickHeight
            brick.anchorPoint.x = 0.5
            brick.anchorPoint.y = 0.5
            brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset)
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
            
            brick.run(brickGroup, completion: {
                self.endlessMoveInProgress = false
            })
            // Run animation for each brick

            if brickCurrent.texture == self.brickNullTexture || brickCurrent.texture == self.brickIndestructible2Texture {
                if brickCurrent.texture == self.brickNullTexture {
                    brickCurrent.removeFromParent()
                }
            } else {
                self.bricksLeft += 1
            }
            // Remove null bricks & discount indestructible bricks
        }
        
        if hapticsSetting! {
            lightHaptic.impactOccurred()
        }
    }
    
}
