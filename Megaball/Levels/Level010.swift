//
//  Level010.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel10() {
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
                    if j == 2 || j == 3 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 19 || i == 20 {
                    if j >= 1 && j <= 4 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i >= 15 && i <= 18 {
                    if j >= 0 && j <= 5 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i >= 12 && i <= 14 {
                    if j >= 1 && j <= 5 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 11 {
                    if j >= 2 && j <= 6 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 10 {
                    if j >= 3 && j <= 6 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 9 || i == 8 {
                    if j >= 4 && j <= 7 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 7 {
                    if j >= 5 && j <= 8 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 6 {
                    if j >= 6 && j <= 8 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 5 {
                    if j >= 7 && j <= 10 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 4 {
                    if j >= 8 && j <= 10 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 3 {
                    if j >= 9 && j <= 10 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 2 {
                    if j == 10 {
                        brick.texture = brickNormalTexture
                    }
                }
                // Normal bricks
                
                if i == 17 || i == 18 {
                    if j == 2 || j == 3 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 12 || i == 13 {
                    if j == 3 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 10 || i == 11 {
                    if j == 4 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 9 {
                    if j == 5 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 7 || i == 8 {
                    if j == 6 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 6 {
                    if j == 7 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 4 || i == 5 {
                    if j == 8 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 4 {
                    if j == 9 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 3 {
                    if j == 10 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                // Indestructible bricks
                
                if i == 15 && j == 6 {
                    brick.texture = brickInvisibleTexture
                }
                if i == 12 && j == 7 {
                    brick.texture = brickInvisibleTexture
                }
                if i == 11 && j == 1 {
                    brick.texture = brickInvisibleTexture
                }
                if i == 9 && j == 8 {
                    brick.texture = brickInvisibleTexture
                }
                if i == 8 && j == 2 {
                   brick.texture = brickInvisibleTexture
                }
                if i == 7 && j == 10 {
                   brick.texture = brickInvisibleTexture
                }
                if i == 5 && j == 3 {
                   brick.texture = brickInvisibleTexture
                }
                if i == 3 && j == 5 {
                   brick.texture = brickInvisibleTexture
                }
                if i == 1 && j == 7 {
                   brick.texture = brickInvisibleTexture
                }
                if i == 0 && j == 10 {
                   brick.texture = brickInvisibleTexture
                }
                // Invisible bricks
                
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
