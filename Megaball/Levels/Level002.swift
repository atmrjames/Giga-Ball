//
//  Level002.swift
//  Megaball
//
//  Created by James Harding on 08/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel2() {
        let startingScale = SKAction.scale(to: 0, duration: 0)
        let startingFade = SKAction.fadeOut(withDuration: 0)
        let scaleUp = SKAction.scale(to: 1, duration: 0.5)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let startingGroup = SKAction.group([startingScale, startingFade])
        let brickGroup = SKAction.group([scaleUp, fadeIn])
        // Setup brick animation
        
        var brickArray: [SKNode] = []
        // Array to store all bricks
        
        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                if j == 0 || j == 8 {
                    // Normal bricks
                    brick.texture = brickNormalTexture
                }
                if j == 1 || j == 7 {
                    // Invisible bricks
                    brick.texture = brickInvisibleTexture
                    brick.isHidden = true
                }
                if j == 2 || j == 6 {
                    // Double bricks
                    brick.texture = brickMultiHit1Texture
                }
                if j == 4 {
                    if i == 1 || i == 4 || i == 7 || i == 10 || i == 13 || i == 16 {
                        // Indestructible bricks
                        brick.texture = brickIndestructibleTexture
                    } else {
                        // Null bricks
                        brick.texture = brickNullTexture
                        brick.isHidden = true
                    }
                }
                if j == 3 || j == 5 {
                    // Null bricks
                    brick.texture = brickNullTexture
                    brick.isHidden = true
                }
                brick.size.width = brickWidth
                brick.size.height = brickHeight
                brick.anchorPoint.x = 0.5
                brick.anchorPoint.y = 0.5
                brick.position = CGPoint(x: -xBrickOffset + (brickWidth+brickSpacing)*CGFloat(j), y: yBrickOffset - (brickHeight+brickSpacing)*CGFloat(i))   
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
                addChild(brick)
                brickArray.append(brick)
            }
        }
        // Define brick properties
        
        for brick in brickArray {
            let brickCurrent = brick as! SKSpriteNode
            brick.run(startingGroup)
            brick.run(brickGroup)
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
    }
}
