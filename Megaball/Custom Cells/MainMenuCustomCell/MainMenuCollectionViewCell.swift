//
//  MainMenuCollectionViewCell.swift
//  Megaball
//
//  Created by James Harding on 10/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class MainMenuCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var view: UIView!
    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var widthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        iconImage.layer.masksToBounds = false
        iconImage.layer.shadowOffset = CGSize(width: 0, height: 2)
        iconImage.layer.shadowColor = UIColor.black.cgColor
        iconImage.layer.shadowOpacity = 0.33
        iconImage.layer.shadowRadius = 4
    }

}
