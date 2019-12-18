//
//  Level008.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel8() {
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
                
                if i == 21 {
                    if j >= 3 && j <= 7 {
                        brick.texture = brickIndestructibleTexture
                    }
                }
                if i == 20 || i == 15 {
                    if j >= 4 && j <= 6 {
                        brick.texture = brickIndestructibleTexture
                    }
                }
                if i >= 16 && i <= 19 {
                    if j == 5 {
                        brick.texture = brickIndestructibleTexture
                    }
                }
                if i == 13 || i == 14 {
                    if j >= 3 && j <= 7 {
                        brick.texture = brickIndestructibleTexture
                    }
                }
                if i >= 10 && i <= 12 {
                    if j >= 2 && j <= 8 {
                        brick.texture = brickIndestructibleTexture
                    }
                }
                if i >= 5 && i <= 9 {
                    if j >= 1 && j <= 9 {
                        brick.texture = brickIndestructibleTexture
                    }
                }
                // Indestructible bricks
                
                if i == 1 || i == 13 {
                    if j == 4 || j == 5 || j == 6 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 2 || i == 3 || (i >= 10 && i <= 12) {
                    if j >= 3 && j <= 7 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i >= 4 && i <= 9 {
                    if j >= 2 && j <= 8 {
                        brick.texture = brickNormalTexture
                    }
                }
                // Normal bricks
                
                if i == 0 {
                    if j == 5 {
                        brick.texture = brickMultiHit1Texture
                    }
                }
                if i == 14 {
                    if j >= 4 && j <= 6 {
                        brick.texture = brickMultiHit1Texture
                    }
                }
                // Multi-hit bricks (1)
                
                if brick.texture == brickInvisibleTexture || brick.texture == brickNullTexture {
                    brick.isHidden = true
                }
                // Hide invisible and null bricks

                brick.size.width = brickWidth
                brick.size.height = brickHeight
                brick.anchorPoint.x = 0.5
                brick.anchorPoint.y = 0.5
                brick.position = CGPoint(x: -xBrickOffset + (brickWidth+objectSpacing)*CGFloat(j), y: yBrickOffset - (brickHeight+objectSpacing)*CGFloat(i))
                brick.physicsBody = SKPhysicsBody(rectangleOf: brick.frame.size)
                brick.physicsBody!.allowsRotation = false
                brick.physicsBody!.friction = 0.0
                brick.physicsBody!.affectedByGravity = false
                brick.physicsBody!.isDynamic = false
                brick.name = BrickCategoryName
                brick.physicsBody!.categoryBitMask = CollisionTypes.brickCategory.rawValue
                brick.physicsBody!.collisionBitMask = CollisionTypes.laserCategory.rawValue
                brick.physicsBody!.contactTestBitMask = CollisionTypes.laserCategory.rawValue
                brick.zPosition = 0
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

            if brickCurrent.texture == brickNullTexture || brickCurrent.texture == brickIndestructibleTexture {
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