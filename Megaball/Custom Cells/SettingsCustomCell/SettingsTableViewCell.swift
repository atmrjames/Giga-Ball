//
//  SettingsTableViewCell.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet var settingDescription: UILabel!
    @IBOutlet var settingState: UILabel!
    @IBOutlet var centreLabel: UILabel!
    @IBOutlet var viewBackground: UIView!
    @IBOutlet var cellView2: UIView!
    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var tickImage: UIImageView!
    @IBOutlet var blurView: UIView!
    @IBOutlet var lockedImageView: UIImageView!
    // Settings cell properties
    
    @IBOutlet var descriptionAndStateSharedWidthConstraint: NSLayoutConstraint!
    @IBOutlet var decriptionFullWidthConstraint: NSLayoutConstraint!
    @IBOutlet var descriptionTickWidthConstraint: NSLayoutConstraint!
    
    
    var blurViewLayer: UIVisualEffectView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setBlur()
        lockedImageView.image = UIImage(named:"LockedIcon.png")!
        blurView.isHidden = true
        lockedImageView.isHidden = true
        // Setup blur and lock icon for when item is locked
        
        tickImage.isHidden = true
        
        cellView2.layer.masksToBounds = false
        cellView2.layer.shadowOffset = CGSize(width: 0, height: 0)
        cellView2.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        cellView2.layer.shadowOpacity = 0.5
        cellView2.layer.shadowRadius = 4
        
        settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        settingDescription.font = settingDescription.font.withSize(18)
        
        descriptionAndStateSharedWidthConstraint.isActive = true
        decriptionFullWidthConstraint.isActive = false
        descriptionTickWidthConstraint.isActive = false
    
    }
    
    func setBlur() {
        blurView.backgroundColor = .clear
        // 1: change the superview transparent
        let blurEffect = UIBlurEffect(style: .regular)
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
