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
    @IBOutlet var blurView: UIView!
    @IBOutlet var lockedImageView: UIImageView!
    
    var blurViewLayer: UIVisualEffectView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        setBlur()
        blurView.isHidden = true
        lockedImageView.image = UIImage(named:"LockedIcon.png")!
        lockedImageView.isHidden = true
        // Setup blur and lock icon for when item is locked
        
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
    
    func setBlur() {
        blurView.backgroundColor = .clear
        // 1: change the superview transparent
        let blurEffect = UIBlurEffect(style: .dark)
        // 2 Create a blur with a style. Other options include .extraLight .light, .dark, .regular, and .prominent.
        blurViewLayer = UIVisualEffectView(effect: blurEffect)
        // 3 Create a UIVisualEffectView with the new blur
        blurViewLayer!.translatesAutoresizingMaskIntoConstraints = false
        // 4 Disable auto-resizing into constrains. Constrains are setup manually.
        blurView.insertSubview(blurViewLayer!, at: 0)

        NSLayoutConstraint.activate([
        blurViewLayer!.heightAnchor.constraint(equalTo: blurView.heightAnchor),
        blurViewLayer!.widthAnchor.constraint(equalTo: blurView.widthAnchor),
        blurViewLayer!.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
        blurViewLayer!.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
        blurViewLayer!.topAnchor.constraint(equalTo: blurView.topAnchor),
        blurViewLayer!.bottomAnchor.constraint(equalTo: blurView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
    }
    
}
