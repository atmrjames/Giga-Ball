//
//  ModeSelectTableViewCell.swift
//  Megaball
//
//  Created by James Harding on 10/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class ModeSelectTableViewCell: UITableViewCell {
    
    @IBOutlet var cellView1: UIView!
    @IBOutlet var modeImageIcon: UIImageView!
    @IBOutlet var modeTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellView1.layer.cornerRadius = 37.5
        
        cellView1.layer.masksToBounds = false
        cellView1.layer.shadowOffset = CGSize(width: 0, height: 2)
        cellView1.layer.shadowColor = UIColor.black.cgColor
        cellView1.layer.shadowOpacity = 0.5
        cellView1.layer.shadowRadius = 4
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
