//
//  IAPTableViewCell.swift
//  Megaball
//
//  Created by James Harding on 25/07/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class IAPTableViewCell: UITableViewCell {

    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var tagLine: UILabel!
    @IBOutlet var premiumLabel: UILabel!
    @IBOutlet var cellView: UIView!
    @IBOutlet var centreLabel: UILabel!
    // Settings cell properties
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellView.layer.cornerRadius = 32
        cellView.layer.masksToBounds = false
        cellView.layer.shadowOffset = CGSize(width: 0, height: 0)
        cellView.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        cellView.layer.shadowOpacity = 0.5
        cellView.layer.shadowRadius = 4
    
    }
    
}
