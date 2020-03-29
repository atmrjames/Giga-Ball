//
//  TotalStats.swift
//  Megaball
//
//  Created by James Harding on 13/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import Foundation
import GameKit

class TotalStats: Codable {
    var cumulativeScore: Int = 0
    var levelsPlayed: Int = 0
    var levelsCompleted: Int = 0
    var ballHits: Int = 0
    var ballsLost: Int = 0
    var powerupsCollected: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var powerupsGenerated: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var playTime: Int = 0
    var bricksHit: [Int] = [0, 0, 0, 0, 0, 0, 0, 0]
    var bricksDestroyed: [Int] = [0, 0, 0, 0, 0, 0, 0, 0]
    var lasersFired: Int = 0
    var lasersHit: Int = 0
    
    var endlessModeHeight: [Int] = []
    var endlessModeHeightDate: [Date] = [] 
    
}
