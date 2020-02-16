//
//  LevelPackSetup.swift
//  Megaball
//
//  Created by James Harding on 07/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import Foundation
import UIKit

class LevelPackSetup {
    let numberOfLevels: [Int] = [1, 10, 2]
    let startLevelNumber: [Int] = [1, 1, 11]
    let packTitles: [String] = [
        "Tutorial",
        "Starter Pack",
        "Space Pack"
    ]
    let levelImageArray: [UIImage] = [
        UIImage(named:"Level001.png")!,
        UIImage(named: "Level002.png")!,
        UIImage(named: "Level003.png")!,
        UIImage(named: "Level004.png")!,
        UIImage(named: "Level005.png")!,
        UIImage(named: "Level006.png")!,
        UIImage(named: "Level007.png")!,
        UIImage(named: "Level008.png")!,
        UIImage(named: "Level009.png")!,
        UIImage(named: "Level010.png")!,
        UIImage(named: "Level011.png")!,
        UIImage(named: "Level012.png")!
    ]
    let levelNameArray: [String] = [
        "Beginner",
        "Block Test Vertical",
        "Block Test Horizontal",
        "Electric Fence",
        "Surfer's Paradise",
        "Gateway",
        "MegaBall",
        "Sundae",
        "X Marks The Spot",
        "Comet",
        "Cresent Moon",
        "Space Invader"
    ]
}
