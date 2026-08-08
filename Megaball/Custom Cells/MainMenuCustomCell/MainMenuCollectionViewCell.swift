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

        clipsToBounds = false
        contentView.clipsToBounds = false
        // The nib clips both, which is invisible while every button is the 50pt the cell
        // is sized for - and crops the big 75pt play button to a *square* the moment a
        // flow layout hands this cell the smaller size. That is the play-test's "the play
        // button turns square", and it is a clip rather than a wrong image: the square is
        // the middle of the circle with its edges cut off

        iconImage.layer.masksToBounds = false
        iconImage.layer.shadowOffset = CGSize(width: 0, height: 0)
        iconImage.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        iconImage.layer.shadowOpacity = 0.5
        iconImage.layer.shadowRadius = 4
    }


    override func prepareForReuse() {
        super.prepareForReuse()
        // Highlighting scales the cell view and recolours it, and that state lives on the
        // cell rather than in the data - so without this a cell highlighted on one row
        // carries the scale and colour to whichever row it is reused for, and the wrong
        // row appears to animate.
        view.transform = .identity
    }

}
