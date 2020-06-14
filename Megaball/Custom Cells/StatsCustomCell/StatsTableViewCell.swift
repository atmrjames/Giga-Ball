//
//  StatsTableViewCell.swift
//  Megaball
//
//  Created by James Harding on 07/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class StatsTableViewCell: UITableViewCell {
    
    @IBOutlet var viewBackground: UIView!
    @IBOutlet var statDescription: UILabel!
    @IBOutlet var statValue: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
