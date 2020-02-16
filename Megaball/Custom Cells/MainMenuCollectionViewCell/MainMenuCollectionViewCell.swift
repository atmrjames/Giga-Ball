//
//  MainMenuCollectionViewCell.swift
//  Megaball
//
//  Created by James Harding on 04/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class MainMenuCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var subView: UIView!
    @IBOutlet var cellLabel: UILabel!
    @IBOutlet var highscoreLabel: UILabel!
    @IBOutlet var purchaseLabel: UILabel!
    @IBOutlet var playButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        subView.layer.cornerRadius = 20.0
        subView.layer.shadowColor = UIColor.black.cgColor
        subView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        subView.layer.shadowRadius = 7.5
        subView.layer.shadowOpacity = 0.75
    }
}
