//
//  Level004.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel4() {
        let startingScale = SKAction.scale(to: 0.8, duration: 0)
        let startingFade = SKAction.fadeOut(withDuration: 0)
        let scaleUp = SKAction.scale(to: 1, duration: 0.25)
        let fadeIn = SKAction.fadeIn(withDuration: 0.25)
        let wait = SKAction.wait(forDuration: 0.25)
        let startingGroup = SKAction.group([startingScale, startingFade])
        let brickGroup = SKAction.group([scaleUp, fadeIn])
        let brickSequence = SKAction.sequence([wait, brickGroup])
        // Setup brick animation

        var brickArray: [SKNode] = []
        // Array to store all bricks
        
        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                // set default brick texture
                
                if i == 0 || i == 16 {
                    if j >= 1 && j <= 9 {
                        brick.texture = brickInvisibleTexture
                    }
                }
                if i >= 1 && i <= 15 {
                    if j == 1 || j == 9 {
                        brick.texture = brickInvisibleTexture
                    }
                }
                // Invisible bricks

                if i == 13 {
                    if j >= 3 && j <= 7 {
                        brick.texture = brickNormalTexture
                    }
                }
                // Normal bricks
                
                if i == 3 {
                    if j == 3 || j == 5 || j == 7 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                // Indestructible bricks
                
                if i >= 4 && i <= 6 {
                    if j == 3 || j == 7 {
                        brick.texture = brickMultiHit1Texture
                    }
                }
                if i == 8 {
                    if j == 5 {
                        brick.texture = brickMultiHit1Texture
                    }
                }
                // Multi-hit bricks (1)
                
                if i >= 7 && i <= 9 {
                    if j == 3 || j == 7 {
                        brick.texture = brickMultiHit2Texture
                    }
                }
                if i == 7 || i == 9 {
                    if j == 5 {
                        brick.texture = brickMultiHit2Texture
                    }
                }
                // Multi-hit bricks (2)
                
                if i >= 10 && i <= 12 {
                    if j == 3 || j == 7 {
                        brick.texture = brickMultiHit3Texture
                    }
                }
                if i == 6 || i == 10 {
                    if j == 5 {
                        brick.texture = brickMultiHit3Texture
                    }
                }
                if i == 3 {
                    if j == 4 || j == 6 {
                        brick.texture = brickMultiHit3Texture
                    }
                }
                // Multi-hit bricks (3)
                
                if brick.texture == brickInvisibleTexture || brick.texture == brickNullTexture {
                    brick.isHidden = true
                }
                // Hide invisible and null bricks
                
                brick.size.width = brickWidth
                brick.size.height = brickHeight
                brick.centerRect = CGRect(x: 6.0/16.0, y: 6.0/16.0, width: 4.0/16.0, height: 4.0/16.0)
                brick.scale(to:CGSize(width: brickWidth, height: brickHeight))
                // Set brick size without stretching edges
                
                brick.anchorPoint.x = 0.5
                brick.anchorPoint.y = 0.5
                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
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
        }
        // Define brick properties

        for brick in brickArray {
            let brickCurrent = brick as! SKSpriteNode
            brick.run(startingGroup)
            brick.run(brickSequence)
            // Run animation for each brick

            if brickCurrent.texture == brickNullTexture || brickCurrent.texture == brickIndestructible2Texture {
                if brickCurrent.texture == brickNullTexture {
                    brickCurrent.removeFromParent()
                }
            } else {
                bricksLeft += 1
            }
            // Remove null bricks & discount indestructible bricks
        }
        mediumHaptic.impactOccurred()
    }
}
