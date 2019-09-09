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
        let blockGroup = SKAction.group([scaleUp, fadeIn])
        // Setup block animation
        
        var blockArray: [SKNode] = []
        // Array to store all blocks
        
        for i in 0..<numberOfBlockRows {
            for j in 0..<numberOfBlockColumns {
                let block = SKSpriteNode(imageNamed: "Block")
                if j == 0 || j == 4 {
                    // Normal blocks
                    block.texture = blockTexture
                }
                if j == 1 || j == 5 {
                    // Invisible blocks
                    block.texture = blockInvisibleTexture
                    block.isHidden = true
                }
                if j == 2 || j == 6 {
                    // Double blocks
                    block.texture = blockDouble1Texture
                }
                if j == 3 {
                    if i == 0 || i == 2 || i == 4 || i == 6 || i == 8 {
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
                block.position = CGPoint(x: -xBlockOffset + CGFloat(CGFloat(j) + 0.5) * blockWidth, y: (frame.height/2 * 0.6)-blockHeight*CGFloat(i))
                block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
                block.physicsBody!.allowsRotation = false
                block.physicsBody!.friction = 0.0
                block.physicsBody!.affectedByGravity = false
                block.physicsBody!.isDynamic = false
                block.name = BlockCategoryName
                block.physicsBody!.categoryBitMask = CollisionTypes.blockCategory.rawValue
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
        
        timeBonusPoints = level2TimeBonus
    }
}
