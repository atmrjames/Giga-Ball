//
//  BrickCreation.swift
//  Megaball
//
//  Created by James Harding on 22/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func brickCreation(brickArray: [SKNode]) {
        
        var brickBuildArray: [SKNode] = []
        // Array to store all bricks
        
        for brick in brickArray {
            let brick = brick as! SKSpriteNode
            
            brick.size.width = brickWidth
            brick.size.height = brickHeight
            
            brick.anchorPoint.x = 0.5
            brick.anchorPoint.y = 0.5
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
            brickBuildArray.append(brick)
        }
        // Define brick properties

        for brick in brickBuildArray {
            let brickCurrent = brick as! SKSpriteNode
            
            bricksLeft += 1
            
            if brickCurrent.texture == brickInvisibleTexture {
                brick.isHidden = true
            }

            if brickCurrent.texture == brickNullTexture || brickCurrent.texture == brickIndestructible2Texture {
                if brickCurrent.texture == brickNullTexture {
                    brickCurrent.removeFromParent()
                }
                bricksLeft -= 1
            }
            // Remove null bricks & discount indestructible bricks
            
            let startingScale = SKAction.scale(to: 0.8, duration: 0)
            let startingFade = SKAction.fadeOut(withDuration: 0)
            let scaleUp = SKAction.scale(to: 1, duration: 0.25)
            let fadeIn = SKAction.fadeIn(withDuration: 0.25)
            let wait = SKAction.wait(forDuration: 0.25)
            let startingGroup = SKAction.group([startingScale, startingFade])
            let brickGroup = SKAction.group([scaleUp, fadeIn])
            let brickSequence = SKAction.sequence([wait, brickGroup])
            // Setup brick animation
            
            brick.run(startingGroup)
            brick.run(brickSequence)
            // Run animation for each brick
            
        }
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
    }
}
