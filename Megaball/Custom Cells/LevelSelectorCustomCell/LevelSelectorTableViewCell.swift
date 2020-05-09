//
//  LevelSelectorTableViewCell.swift
//  Megaball
//
//  Created by James Harding on 07/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class LevelSelectorTableViewCell: UITableViewCell {
    
    @IBOutlet var cellView3: UIView!
    @IBOutlet var levelImage: UIImageView!
    @IBOutlet var levelLabel: UILabel!
    @IBOutlet var levelNameLabel: UILabel!
    @IBOutlet var highScoreTitleLabel: UILabel!
    @IBOutlet var highScoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        levelImage.layer.masksToBounds = false
        levelImage.layer.shadowOffset = CGSize(width: 0, height: 0)
        levelImage.layer.shadowColor = UIColor.black.cgColor
        levelImage.layer.shadowOpacity = 0.5
        levelImage.layer.shadowRadius = 4
        
        cellView3.layer.masksToBounds = false
        cellView3.layer.shadowOffset = CGSize(width: 0, height: 2)
        cellView3.layer.shadowColor = UIColor.black.cgColor
        cellView3.layer.shadowOpacity = 0.5
        cellView3.layer.shadowRadius = 4
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
