//
//  Playing.swift
//  Megaball
//
//  Created by James Harding on 22/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

class Playing: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        
        scene.gameStateLabel.text = "Playing"
        
        if previousState is PreGame {
            levelBuild()
            
            scene.ball.isHidden = false
            scene.paddle.isHidden = false
            scene.ballIsOnPaddle = true
            
            scene.paddle.position.x = 0
            scene.paddle.position.y = (-self.scene.frame.height/2 + scene.paddleGap)
            
            let startingScale = SKAction.scale(to: 0, duration: 0)
            let startingFade = SKAction.fadeIn(withDuration: 0)
            let scaleUp = SKAction.scale(to: 1, duration: 0.5)
            let ballSequence = SKAction.sequence([startingScale, startingFade, scaleUp])
            let paddleSequence = SKAction.sequence([startingScale, startingFade, scaleUp])
            scene.ball.run(ballSequence)
            scene.paddle.run(paddleSequence)
            // Animate paddle and ball in
        }
        
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    func levelBuild() {
    // TODO: Add level to build as an input to this function
        
        let startingScale = SKAction.scale(to: 0, duration: 0)
        let startingFade = SKAction.fadeOut(withDuration: 0)
        let scaleUp = SKAction.scale(to: 1, duration: 0.5)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let startingGroup = SKAction.group([startingScale, startingFade])
        let blockGroup = SKAction.group([scaleUp, fadeIn])
        // Setup block animation
        
        var blockArray: [SKNode] = []
        // Array to store all blocks
        
        for i in 0..<scene.numberOfBlockRows {
            for j in 0..<scene.numberOfBlockColumns {
                let block = SKSpriteNode(imageNamed: "Block")
                if i == 0 || i == 8 {
                    // Normal blocks
                    block.texture = scene.blockTexture
                }
                if i == 1 || i == 7 {
                    // Invisible blocks
                    block.texture = scene.blockInvisibleTexture
                    block.isHidden = true
                }
                if i == 2 || i == 6 {
                    // Double blocks
                    block.texture = scene.blockDouble1Texture
                }
                if i == 3 || i == 5 {
                    // Null blocks
                    block.texture = scene.blockNullTexture
                    block.isHidden = true
                }
                if i == 4 {
                    if j == 0 || j == 2 || j == 4 || j == 6 {
                        // Indestructible blocks
                        block.texture = scene.blockIndestructibleTexture
                    } else {
                        // Null blocks
                        block.texture = scene.blockNullTexture
                        block.isHidden = true
                    }
                    
                }
                block.size.width = scene.blockWidth
                block.size.height = scene.blockHeight
                block.position = CGPoint(x: -scene.xBlockOffset + CGFloat(CGFloat(j) + 0.5) * scene.blockWidth, y: (scene.frame.height/2 * 0.6)-scene.blockHeight*CGFloat(i))
                block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
                block.physicsBody!.allowsRotation = false
                block.physicsBody!.friction = 0.0
                block.physicsBody!.affectedByGravity = false
                block.physicsBody!.isDynamic = false
                block.name = BlockCategoryName
                block.physicsBody!.categoryBitMask = CollisionTypes.blockCategory.rawValue
                block.zPosition = 0
                scene.addChild(block)
                blockArray.append(block)
            }
        }
        // Define block properties
        
        for block in blockArray {
            let blockCurrent = block as! SKSpriteNode
            block.run(startingGroup)
            block.run(blockGroup)
            if blockCurrent.texture == scene.blockNullTexture || blockCurrent.texture == scene.blockIndestructibleTexture {
                if blockCurrent.texture == scene.blockNullTexture {
                    blockCurrent.removeFromParent()
                }
            } else {
                scene.blocksLeft += 1
            }
        }
        // Run animation for each block
        
        scene.blocksLeftLabel.text = String(scene.blocksLeft)
    
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is GameOver.Type:
            return true
        case is BallOnPaddle.Type:
            return true
        case is Paused.Type:
            return true
            
        default:
            return false
        }
    }
}

