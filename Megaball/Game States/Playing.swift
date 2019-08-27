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
        scene.ball.isHidden = false
        scene.paddle.isHidden = false
        levelBuild()
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    func levelBuild() {
    // TODO: Add level to build as an input to this function
        
        for i in 0..<scene.numberOfBlockRows {
            for j in 0..<scene.numberOfBlockColumns {
                let block = SKSpriteNode(imageNamed: "Block")
                if i == 0 || i == 3 {
                    // Normal blocks
                    block.texture = scene.blockTexture
                }
                if i == 1 || i == 4 {
                    // Double blocks
                    block.texture = scene.blockDouble1Texture
                }
                if i == 2 || i == 5 {
                    // Invisible blocks
                    block.texture = scene.blockInvisibleTexture
                    block.isHidden = true
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
                block.physicsBody!.categoryBitMask = BlockCategory
                block.zPosition = 2
                scene.addChild(block)
            }
        }
        // Define block properties
        
        scene.enumerateChildNodes(withName: BlockCategoryName) { (node, _) in
            self.scene.blocksLeft += 1
        }
        scene.blocksLeftLabel.text = String(scene.blocksLeft)
    
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
//        return stateClass is BallOnPaddle.Type
        return stateClass is GameOver.Type
    }
}

