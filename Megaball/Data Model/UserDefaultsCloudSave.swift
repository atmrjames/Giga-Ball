//
//  UserDefaultsCloudSave.swift
//  
//
//  Created by James Harding on 04/07/2020.
//

import Foundation

class UserDefaultsCloudSave: Codable {
    
    // Commented out properties are intentionally not sync'ed between devices
    
    var premiumSetting: Bool?
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
//    var paddleSensitivitySetting: Int?
//    var gameCenterSetting: Bool?
//    var ballSetting: Int?
//    var paddleSetting: Int?
//    var brickSetting: Int?
//    var appIconSetting: Int?
    var statsCollapseSetting: Bool?
    var swipeUpPause: Bool?
    // User settings
    var saveGameSaveArray: [Int]?
    var saveMultiplier: Double?
    var saveBrickTextureArray: [Int]?
    var saveBrickColourArray: [Int]?
    var saveBrickXPositionArray: [Int]?
    var saveBrickYPositionArray: [Int]?
    var saveBallPropertiesArray: [Double]?
    
    var savePowerUpFallingXPositionArray: [Int]?
    var savePowerUpFallingYPositionArray: [Int]?
    var savePowerUpFallingArray: [Int]?
    var savePowerUpActiveArray: [String]?
    var savePowerUpActiveDurationArray: [Double]?
    var savePowerUpActiveTimerArray: [Double]?
    var savePowerUpActiveMagnitudeArray: [Int]?

    // Game save settings
}
