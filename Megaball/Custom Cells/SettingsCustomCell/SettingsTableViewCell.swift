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
    @IBOutlet var tickImage: UIImageView!
    // Settings cell properties
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tickImage.isHidden = true
        
        cellView2.layer.masksToBounds = false
        cellView2.layer.shadowOffset = CGSize(width: 0, height: 2)
        cellView2.layer.shadowColor = UIColor.black.cgColor
        cellView2.layer.shadowOpacity = 0.5
        cellView2.layer.shadowRadius = 4
        
    }
}
