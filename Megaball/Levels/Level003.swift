//
//  Level003.swift
//  Megaball
//
//  Created by James Harding on 28/11/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel3() {
        let startingScale = SKAction.scale(to: 0, duration: 0)
        let startingFade = SKAction.fadeOut(withDuration: 0)
        let scaleUp = SKAction.scale(to: 1, duration: 0.5)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let startingGroup = SKAction.group([startingScale, startingFade])
        let blockGroup = SKAction.group([scaleUp, fadeIn])
        // Setup block animation

        var blockArray: [SKNode] = []
        // Array to store all blocks

        for i in 0..<numberOfBlockRows {
            for j in 0..<numberOfBlockColumns {
                let block = SKSpriteNode(imageNamed: "Block")
                if i == 0 || i == 1 || i == 18 || i == 19 {
                    // Normal blocks
                    block.texture = blockTexture
                }
                if i == 2 || i == 4 || i == 15 || i == 17 {
                    // Invisible blocks
                    block.texture = blockInvisibleTexture
                    block.isHidden = true
                }
                if i == 3 || i == 6 || i == 13 || i == 16 {
                    // Double blocks
                    block.texture = blockDouble1Texture
                }
                if i == 5 || i == 7 || i == 9 || i == 10 || i == 12 || i == 14 {
                    // Null blocks
                    block.texture = blockNullTexture
                    block.isHidden = true
                }
                if i == 8 || i == 11 {
                    if j == 0 || j == 1 || j == 3 || j == 6 || j == 8 || j == 9 {
                        // Indestructible blocks
                        block.texture = blockIndestructibleTexture
                    } else {
                        // Null blocks
                        block.texture = blockNullTexture
                        block.isHidden = true
                    }
                }
                block.size.width = blockWidth
                block.size.height = blockHeight
                block.anchorPoint.x = 0.5
                block.anchorPoint.y = 0.5
                block.position = CGPoint(x: -xBlockOffset + blockWidth*CGFloat(j), y: yBlockOffset - blockHeight*CGFloat(i))
                block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
                block.physicsBody!.allowsRotation = false
                block.physicsBody!.friction = 0.0
                block.physicsBody!.affectedByGravity = false
                block.physicsBody!.isDynamic = false
                block.name = BlockCategoryName
                block.physicsBody!.categoryBitMask = CollisionTypes.blockCategory.rawValue
                block.physicsBody!.collisionBitMask = CollisionTypes.laserCategory.rawValue
                block.physicsBody!.contactTestBitMask = CollisionTypes.laserCategory.rawValue
                block.zPosition = 0
                addChild(block)
                blockArray.append(block)
            }
        }
        // Define block properties

        for block in blockArray {
            let blockCurrent = block as! SKSpriteNode
            block.run(startingGroup)
            block.run(blockGroup)
            // Run animation for each block

            if blockCurrent.texture == blockNullTexture || blockCurrent.texture == blockIndestructibleTexture {
                if blockCurrent.texture == blockNullTexture {
                    blockCurrent.removeFromParent()
                }
            } else {
                blocksLeft += 1
            }
            // Remove null blocks & discount indestructible blocks
        }

        timeBonusPoints = level3TimeBonus
    }
}

