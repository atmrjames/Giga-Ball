//
//  SettingsTableViewCell.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet var settingDescription: UILabel!
    @IBOutlet var settingState: UILabel!
    @IBOutlet var centreLabel: UILabel!
    @IBOutlet var viewBackground: UIView!
    @IBOutlet var cellView2: UIView!
    @IBOutlet var iconImage: UIImageView!
    // Settings cell properties
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code goes here
    }
}
