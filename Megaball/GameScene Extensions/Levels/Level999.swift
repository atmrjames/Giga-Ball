//
//  Level999.swift
//  Megaball
//
//  Created by James Harding on 19/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    
    func prepEndlessMode(height: Int) {
        endlessMode = true
        endlessMoveInProgress = false
        endlessHeight = height

        life.isHidden = true
        livesLabel.isHidden = true
        multiplierLabel.isHidden = true
        // Remove classic mode labels
        
        scoreLabel.fontSize = fontSize*1.5
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position.y = life.position.y-2
        scoreLabel.text = "\(endlessHeight) m"
        // Setup score label for endless mode
        
        if screenSize != "X" {
            scoreBacker.isHidden = false
        }
                
        height01 = Int.random(in: 0...25)
        height02 = Int.random(in: height01!...50)
        height03 = Int.random(in: height02!...75)
        height04 = Int.random(in: height03!...100)
        height05 = Int.random(in: height04!...150)
        height06 = Int.random(in: height05!...200)
        height07 = Int.random(in: height06!...250)
        height08 = Int.random(in: height07!...300)
        height09 = Int.random(in: height08!...350)
        height10 = Int.random(in: height09!...400)
        height11 = Int.random(in: height10!...450)
        height12 = Int.random(in: height11!...500)
        height13 = Int.random(in: height12!...550)
        height14 = Int.random(in: height13!...600)
        height15 = Int.random(in: height14!...650)
        height16 = Int.random(in: height15!...700)
        height17 = Int.random(in: height16!...775)
        height18 = Int.random(in: height17!...850)
        height19 = Int.random(in: height18!...925)
        height20 = Int.random(in: height19!...1000)
        // Random height boundaries within limits
        
        endlessBrickMode01 = Int.random(in: 1...4)
        endlessBrickMode02 = Int.random(in: 1...4)
        endlessBrickMode03 = Int.random(in: 1...4)
        endlessBrickMode04 = Int.random(in: 1...4)
    }
    
    func loadLevel999() {
        
        prepEndlessMode(height: 0)
        
        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                let randomBrick = Int.random(in: 1...100)
                if randomBrick <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                } else if randomBrick > 5 && randomBrick <= 6 {
                    brick.texture = brickMultiHit3Texture
                }
                
                if i >= 19 {
                    brick.texture = brickNullTexture
                }
                if i == 21 && j == 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenGigaball
                }

                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffsetEndless - brickHeight*CGFloat(i))
                
                if brick.texture == brickInvisibleTexture {
                    brick.isHidden = true
                }
                
                brickArray.append(brick)
            }
        }
        // Set brick textures and positions
        
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }
}
