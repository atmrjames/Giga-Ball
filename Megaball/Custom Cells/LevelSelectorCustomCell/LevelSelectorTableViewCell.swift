//
//  LevelSelectorTableViewCell.swift
//  Megaball
//
//  Created by James Harding on 07/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class LevelSelectorTableViewCell: UITableViewCell {
    
    @IBOutlet var cellView: UIView!
    @IBOutlet var levelImage: UIImageView!
    @IBOutlet var levelLabel: UILabel!
    @IBOutlet var levelNameLabel: UILabel!
    @IBOutlet var highScoreTitleLabel: UILabel!
    @IBOutlet var highScoreLabel: UILabel!
    @IBOutlet var statsButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
//        levelImage.layer.cornerRadius = 10.0
        levelImage.layer.masksToBounds = false
        levelImage.layer.shadowColor = UIColor.black.cgColor
        levelImage.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        levelImage.layer.shadowRadius = 5.0
        levelImage.layer.shadowOpacity = 0.25
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
