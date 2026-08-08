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

    /// The nib's pin holding the tick against the card's trailing edge.
    ///
    /// Found once, because deactivating a constraint removes it from the view's list and
    /// it could never be found again. The pack screen puts a play button on that edge and
    /// sits the tick beside it instead - and puts this back when a reused cell has no
    /// button, or the tick would be left with no horizontal position at all.
    lazy var tickTrailingEdgeConstraint: NSLayoutConstraint? = cellView2.constraints.first {
        $0.firstAttribute == .trailing && $0.secondItem === tickImage
            && $0.secondAttribute == .trailing
    }

    /// Pins the description label to the width of its own text, so whatever follows it
    /// sits against the words rather than against the cell's far edge.
    ///
    /// The nib lets the label fill the row, which is right for a settings row - its value
    /// is at the other end. A completion tick belongs *beside the name* (play-test round
    /// 3), and that needs the label to stop where the text does.
    private var descriptionHugsTextConstraint: NSLayoutConstraint?

    func hugDescriptionToText(_ hug: Bool) {
        descriptionHugsTextConstraint?.isActive = false
        descriptionHugsTextConstraint = nil
        settingDescription.numberOfLines = hug ? 1 : 0
        // One line while hugging, always: a multiline label's intrinsic width remembers
        // whatever narrow wrap the last layout pass gave it, so measuring it here could
        // pin the label at its *wrapped* width - which is exactly how the pack names
        // ended up folded onto two lines (play-test round 5)
        guard hug else { return }

        let width = (settingDescription.text ?? "")
            .size(withAttributes: [.font: settingDescription.font as Any]).width
        let constraint = settingDescription.widthAnchor.constraint(
            equalToConstant: ceil(width))
        constraint.priority = UILayoutPriority(rawValue: 998)
        constraint.isActive = true
        descriptionHugsTextConstraint = constraint
        // Measured from the text itself, after it is set, and torn down on reuse - a
        // stale width from another row's name would truncate this one. Just below
        // required, so an impossibly long name truncates instead of breaking the
        // tick-and-button chain beside it
    }

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

        settingState.numberOfLines = 1
        settingState.adjustsFontSizeToFitWidth = true
        settingState.minimumScaleFactor = 0.7
        // The state column is sized for "on" and "x1.50". A longer value - "Gradient" -
        // wrapped onto a second line rather than being allowed to shrink
        
        decriptionFullWidthConstraint.isActive = false
        descriptionTickWidthConstraint.isActive = false
        descriptionAndStateSharedWidthConstraint.isActive = true
    
    }
    
    func setBlur() {
        blurView.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .regular)
        blurViewLayer = UIVisualEffectView(effect: blurEffect)
        blurViewLayer!.translatesAutoresizingMaskIntoConstraints = false
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
    

    override func prepareForReuse() {
        super.prepareForReuse()
        // Highlighting scales cellView2 and recolours it, and that state lives on the
        // cell rather than in the data - so without this a cell highlighted on one row
        // carries the scale and colour to whichever row it is reused for, and the wrong
        // row appears to animate.
        cellView2.transform = .identity
        cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
    }

}
