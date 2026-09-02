//
//  Level000.swift
//  Megaball
//
//  Created by James Harding on 05/03/2020.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel000() {

        showEndlessIIBest()
        // The original endless mode gets its best height under the live one too. It is the
        // thing a run is measured against, and it was only ever missing here because the
        // display was written for the mode that came second

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                
                brick.texture = brickNormalTexture
                brick.color = brickBlue

                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
                
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


extension GameScene {

    /// Builds the level with this number.
    ///
    /// **The one place a level number becomes a level.** This switch lived in `Playing`, which
    /// is a game state and not a catalogue - and being there meant nothing but the running game
    /// could ask for a level. Round 294 needed exactly that: whether a level looks different
    /// flipped is a fact about the level, and the only way to know it is to build the level and
    /// look (`DailyLayoutFlip`).
    ///
    /// Moved rather than copied, for the reason a second copy of anything is wrong here: a
    /// hundred and ten cases written twice would disagree the first time a level was added.
    func loadLevel(_ number: Int) {
        switch number {
            
        // Endless mode
        case 0:
            loadLevel999()
            
        // Classic Pack
        case 1:
            loadLevel1()
        case 2:
            loadLevel2()
        case 3:
            loadLevel3()
        case 4:
            loadLevel4()
        case 5:
            loadLevel5()
        case 6:
            loadLevel6()
        case 7:
            loadLevel7()
        case 8:
            loadLevel8()
        case 9:
            loadLevel9()
        case 10:
            loadLevel10()
            
        // Space Pack
        case 11:
            loadLevel11()
        case 12:
            loadLevel12()
        case 13:
            loadLevel13()
        case 14:
            loadLevel14()
        case 15:
            loadLevel15()
        case 16:
            loadLevel16()
        case 17:
            loadLevel17()
        case 18:
            loadLevel18()
        case 19:
            loadLevel19()
        case 20:
            loadLevel20()
            
        // Nature Pack
        case 21:
            loadLevel21()
        case 22:
            loadLevel22()
        case 23:
            loadLevel23()
        case 24:
            loadLevel24()
        case 25:
            loadLevel25()
        case 26:
            loadLevel26()
        case 27:
            loadLevel27()
        case 28:
            loadLevel28()
        case 29:
            loadLevel29()
        case 30:
            loadLevel30()
            
        // Nature Pack
        case 31:
            loadLevel31()
        case 32:
            loadLevel32()
        case 33:
            loadLevel33()
        case 34:
            loadLevel34()
        case 35:
            loadLevel35()
        case 36:
            loadLevel36()
        case 37:
            loadLevel37()
        case 38:
            loadLevel38()
        case 39:
            loadLevel39()
        case 40:
            loadLevel40()
            
        // Food Pack
        case 41:
            loadLevel41()
        case 42:
            loadLevel42()
        case 43:
            loadLevel43()
        case 44:
            loadLevel44()
        case 45:
            loadLevel45()
        case 46:
            loadLevel46()
        case 47:
            loadLevel47()
        case 48:
            loadLevel48()
        case 49:
            loadLevel49()
        case 50:
            loadLevel50()
            
        // Computer Pack
        case 51:
            loadLevel51()
        case 52:
            loadLevel52()
        case 53:
            loadLevel53()
        case 54:
            loadLevel54()
        case 55:
            loadLevel55()
        case 56:
            loadLevel56()
        case 57:
            loadLevel57()
        case 58:
            loadLevel58()
        case 59:
            loadLevel59()
        case 60:
            loadLevel60()
        
        // Body Pack
        case 61:
            loadLevel61()
        case 62:
            loadLevel62()
        case 63:
            loadLevel63()
        case 64:
            loadLevel64()
        case 65:
            loadLevel65()
        case 66:
            loadLevel66()
        case 67:
            loadLevel67()
        case 68:
            loadLevel68()
        case 69:
            loadLevel69()
        case 70:
            loadLevel70()
        
        // Geography Pack
        case 71:
            loadLevel71()
        case 72:
            loadLevel72()
        case 73:
            loadLevel73()
        case 74:
            loadLevel74()
        case 75:
            loadLevel75()
        case 76:
            loadLevel76()
        case 77:
            loadLevel77()
        case 78:
            loadLevel78()
        case 79:
            loadLevel79()
        case 80:
            loadLevel80()

        // Emoji Pack
        case 81:
            loadLevel81()
        case 82:
            loadLevel82()
        case 83:
            loadLevel83()
        case 84:
            loadLevel84()
        case 85:
            loadLevel85()
        case 86:
            loadLevel86()
        case 87:
            loadLevel87()
        case 88:
            loadLevel88()
        case 89:
            loadLevel89()
        case 90:
            loadLevel90()

        // Numbers Pack
        case 91:
            loadLevel91()
        case 92:
            loadLevel92()
        case 93:
            loadLevel93()
        case 94:
            loadLevel94()
        case 95:
            loadLevel95()
        case 96:
            loadLevel96()
        case 97:
            loadLevel97()
        case 98:
            loadLevel98()
        case 99:
            loadLevel99()
        case 100:
            loadLevel100()

        // Challenge Pack
        case 101:
            loadLevel101()
        case 102:
            loadLevel102()
        case 103:
            loadLevel103()
        case 104:
            loadLevel104()
        case 105:
            loadLevel105()
        case 106:
            loadLevel106()
        case 107:
            loadLevel107()
        case 108:
            loadLevel108()
        case 109:
            loadLevel109()
        case 110:
            loadLevel110()
            
        default:
            break
        }
    }
}
