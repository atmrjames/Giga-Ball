//
//  EndlessRowCreation.swift
//  Megaball
//
//  Created by James Harding on 19/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    
    func buildNewEndlessRow() {

        var brickArray: [SKNode] = []
        // Array to store all bricks
        
//        let randomRow = Int.random(in: 0...99)
        
        let rare = Int.random(in: 1...3)
        let few = Int.random(in: 2...6)
        let infrequent = Int.random(in: 4...10)
        let several = Int.random(in: 7...15)
        let frequent = Int.random(in: 15...25)
        let many = Int.random(in: 25...35)
        // Set brick frequency limits
        
        var normalProb: Int?
        var mHThreeProb: Int?
        var mHTwoProb: Int?
        var mHOneProb: Int?
        var indestTwoProb: Int?
        var indestOneProb: Int?
        var invisiProb: Int?
        // Setup individual brick probability variables
        
        var randRowProb: Int?
        var nullRowProb: Int?
        var normalSemiRowProb: Int?
        var normalFullRowProb: Int?
        var invisibleSemiRowProb: Int?
        var invisibleFullRowProb: Int?
        var multiHitSemiRowProb: Int?
        var multiHitFullRowProb: Int?
        var indestructible1SemiRowProb: Int?
        var indestructible2SemiRowProb: Int?
        var indestructibleMixSemiRowProb: Int?
        // Setup random row brick probability variables
        
        
        for j in 0..<numberOfBrickColumns {
            let brick = SKSpriteNode(imageNamed: "BrickNormal")
            
            if endlessHeight < 25 {
                normalProb = several
                mHThreeProb = rare
                mHTwoProb = 0
                mHOneProb = 0
                indestTwoProb = 0
                indestOneProb = 0
                invisiProb = 0
                
                randRowProb = 0
                nullRowProb = 0
                normalSemiRowProb = 0
                normalFullRowProb = 100
                invisibleSemiRowProb = 0
                invisibleFullRowProb = 0
                multiHitSemiRowProb = 0
                multiHitFullRowProb = 0
                indestructible1SemiRowProb = 0
                indestructible2SemiRowProb = 0
                indestructibleMixSemiRowProb = 0
            }
            
            if endlessHeight >= 25 && endlessHeight < 50 {
                normalProb = several
                mHThreeProb = rare
                mHTwoProb = 0
                mHOneProb = 0
                indestTwoProb = rare
                indestOneProb = 0
                invisiProb = 0
            }
            
            if endlessHeight >= 50 && endlessHeight < 75 {
                normalProb = several
                mHThreeProb = few
                mHTwoProb = 0
                mHOneProb = 0
                indestTwoProb = rare
                indestOneProb = 0
                invisiProb = 0
            }
            
            if endlessHeight >= 75 && endlessHeight < 100 {
                normalProb = several
                mHThreeProb = few
                mHTwoProb = rare
                mHOneProb = 0
                indestTwoProb = rare
                indestOneProb = 0
                invisiProb = 0
            }
            
            if endlessHeight >= 100 && endlessHeight < 150 {
                normalProb = frequent
                mHThreeProb = few
                mHTwoProb = rare
                mHOneProb = 0
                indestTwoProb = rare
                indestOneProb = 0
                invisiProb = 0
            }
            
            if endlessHeight >= 150 && endlessHeight < 200 {
                normalProb = frequent
                mHThreeProb = few
                mHTwoProb = rare
                mHOneProb = 0
                indestTwoProb = rare
                indestOneProb = rare
                invisiProb = 0
            }
            
            if endlessHeight >= 200 && endlessHeight < 250 {
                normalProb = frequent
                mHThreeProb = few
                mHTwoProb = rare
                mHOneProb = rare
                indestTwoProb = rare
                indestOneProb = rare
                invisiProb = 0
            }
            
            if endlessHeight >= 250 && endlessHeight < 300 {
                normalProb = frequent
                mHThreeProb = few
                mHTwoProb = rare
                mHOneProb = rare
                indestTwoProb = rare
                indestOneProb = rare
                invisiProb = few
            }
            
            if endlessHeight >= 300 && endlessHeight < 375 {
                normalProb = many
                mHThreeProb = few
                mHTwoProb = rare
                mHOneProb = rare
                indestTwoProb = rare
                indestOneProb = rare
                invisiProb = infrequent
            }
            
            if endlessHeight >= 375 && endlessHeight < 450 {
                normalProb = many
                mHThreeProb = few
                mHTwoProb = few
                mHOneProb = rare
                indestTwoProb = rare
                indestOneProb = rare
                invisiProb = infrequent
            }
            
            if endlessHeight >= 450 && endlessHeight < 525 {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = few
                mHOneProb = rare
                indestTwoProb = few
                indestOneProb = rare
                invisiProb = infrequent
            }
            
            if endlessHeight >= 525 && endlessHeight < 600 {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = few
                mHOneProb = few
                indestTwoProb = few
                indestOneProb = few
                invisiProb = infrequent
            }
            
            if endlessHeight >= 600 && endlessHeight < 700 {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = infrequent
                mHOneProb = few
                indestTwoProb = few
                indestOneProb = few
                invisiProb = frequent
            }
            
            if endlessHeight >= 700 && endlessHeight < 800 {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = infrequent
                mHOneProb = few
                indestTwoProb = few
                indestOneProb = infrequent
                invisiProb = frequent
            }
            
            if endlessHeight >= 800 && endlessHeight < 900 {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = infrequent
                mHOneProb = infrequent
                indestTwoProb = infrequent
                indestOneProb = infrequent
                invisiProb = frequent
            }
            
            if endlessHeight >= 900 && endlessHeight < 1000 {
                normalProb = many
                mHThreeProb = infrequent
                mHTwoProb = infrequent
                mHOneProb = several
                indestTwoProb = infrequent
                indestOneProb = several
                invisiProb = frequent
            }
            
            brick.texture = brickNullTexture
            let randomBrick = Int.random(in: 1...100)
            
            mHThreeProb = normalProb! + mHThreeProb!
            mHTwoProb = mHThreeProb! + mHTwoProb!
            mHOneProb = mHTwoProb! + mHOneProb!
            indestTwoProb = mHOneProb! + indestTwoProb!
            indestOneProb = indestTwoProb! + indestOneProb!
            invisiProb = indestOneProb! + invisiProb!
            
            if randomBrick <= normalProb! {
                brick.texture = brickNormalTexture
            } else if randomBrick > normalProb! && randomBrick <= mHThreeProb! {
                brick.texture = brickMultiHit3Texture
            } else if randomBrick > mHThreeProb! && randomBrick <= mHTwoProb! {
                brick.texture = brickMultiHit2Texture
            } else if randomBrick > mHTwoProb! && randomBrick <= mHOneProb! {
                brick.texture = brickMultiHit1Texture
            } else if randomBrick > mHOneProb! && randomBrick <= indestTwoProb! {
                brick.texture = brickIndestructible2Texture
            } else if randomBrick > indestTwoProb! && randomBrick <= indestOneProb! {
                brick.texture = brickIndestructible1Texture
            } else if randomBrick > indestOneProb! && randomBrick <= invisiProb! {
                brick.texture = brickInvisibleTexture
            }
            
            let randRow = Int.random(in: 1...100)
            if randRow < randRowProb! {
                let randRowSelect = Int.random(in: 1...100)
                
                normalSemiRowProb = nullRowProb! + normalSemiRowProb!
                normalFullRowProb = normalSemiRowProb! + normalFullRowProb!
                invisibleSemiRowProb = normalFullRowProb! + invisibleSemiRowProb!
                invisibleFullRowProb = invisibleSemiRowProb! + invisibleFullRowProb!
                multiHitSemiRowProb = invisibleFullRowProb! + multiHitSemiRowProb!
                multiHitFullRowProb = multiHitSemiRowProb! + multiHitFullRowProb!
                indestructible1SemiRowProb = multiHitFullRowProb! + indestructible1SemiRowProb!
                indestructible2SemiRowProb = indestructible1SemiRowProb! + indestructible2SemiRowProb!
                indestructibleMixSemiRowProb = indestructible2SemiRowProb! + indestructibleMixSemiRowProb!
                
                if randRowSelect <= nullRowProb! {
                    brick.texture = brickNullTexture
                } else if randRowSelect > nullRowProb! && randRowSelect <= normalSemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickNormalTexture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > normalSemiRowProb! && randRowSelect <= normalFullRowProb! {
                    brick.texture = brickNormalTexture
                } else if randRowSelect > normalFullRowProb! && randRowSelect <= invisibleSemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickInvisibleTexture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > invisibleSemiRowProb! && randRowSelect <= invisibleFullRowProb! {
                    brick.texture = brickInvisibleTexture
                } else if randRowSelect > invisibleFullRowProb! && randRowSelect <= multiHitSemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickMultiHit1Texture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > multiHitSemiRowProb! && randRowSelect <= multiHitFullRowProb! {
                    brick.texture = brickMultiHit1Texture
                } else if randRowSelect > multiHitFullRowProb! && randRowSelect <= indestructible1SemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickIndestructible1Texture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > indestructible1SemiRowProb! && randRowSelect <= indestructible2SemiRowProb! {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickIndestructible2Texture
                    } else {
                        brick.texture = brickNullTexture
                    }
                } else if randRowSelect > indestructible2SemiRowProb! && randRowSelect <= indestructibleMixSemiRowProb! {
                    if j == 0 || j == 4 || j == 8 {
                        brick.texture = brickIndestructible2Texture
                    } else if j == 2 || j == 6 || j == 10  {
                        brick.texture = brickIndestructible1Texture
                    } else {
                        brick.texture = brickNullTexture
                    }
                }
            }
            
            if brick.texture == brickNormalTexture {
                brick.color = brickWhite
            }
            
            if brick.texture == brickInvisibleTexture {
                brick.isHidden = true
            }
            
            brick.size.width = brickWidth
            brick.size.height = brickHeight
            brick.anchorPoint.x = 0.5
            brick.anchorPoint.y = 0.5
            brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffsetEndless)
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
        // Define brick properties
        
        let startingScale = SKAction.scale(to: 0.8, duration: 0)
        let startingFade = SKAction.fadeOut(withDuration: 0)
        let scaleUp = SKAction.scale(to: 1, duration: 0.05)
        let fadeIn = SKAction.fadeIn(withDuration: 0.05)
        let startingGroup = SKAction.group([startingScale, startingFade])
        let brickGroup = SKAction.group([scaleUp, fadeIn])
        // Setup brick animation
        
        for brick in brickArray {
            let brickCurrent = brick as! SKSpriteNode
            
            if brickCurrent.texture == brickNormalTexture {
                brickCurrent.colorBlendFactor = 1.0
            }
            
            brick.run(startingGroup)
            brick.alpha = 1.0
            // Pre animation setup
            
            brick.run(brickGroup, completion: {
                self.endlessMoveInProgress = false
            })
            // Run animation for each brick

            if brickCurrent.texture == self.brickNullTexture || brickCurrent.texture == self.brickIndestructible2Texture {
                if brickCurrent.texture == self.brickNullTexture {
                    brickCurrent.removeFromParent()
                }
            } else {
                self.bricksLeft += 1
            }
            // Remove null bricks & discount indestructible bricks
        }
        
        if hapticsSetting! {
            lightHaptic.impactOccurred()
        }
    }
    
}
