//
//  PowerUpTableViewCell.swift
//  Megaball
//
//  Created by James Harding on 22/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class PowerUpTableViewCell: UITableViewCell {
    
    @IBOutlet var cellView4: UIView!
    @IBOutlet var powerUpImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var chevronButton: UIButton!
    @IBOutlet var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
