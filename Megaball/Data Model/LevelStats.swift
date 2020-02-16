//
//  LevelScores.swift
//  Megaball
//
//  Created by James Harding on 06/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import Foundation

class LevelStats: Codable {
    var scores: [Int] = []
    var scoreDates: [Date] = []
    var numberOfCompletes: Int = 0
}
