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
        levelImage.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        levelImage.layer.shadowOpacity = 0.5
        levelImage.layer.shadowRadius = 4
        
        cellView3.layer.masksToBounds = false
        cellView3.layer.shadowOffset = CGSize(width: 0, height: 0)
        cellView3.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        cellView3.layer.shadowOpacity = 0.5
        cellView3.layer.shadowRadius = 4

        isGlass = SettingsTableViewCell.addGlass(behind: cellView3, cornerRadius: 14) != nil
        if isGlass {
            cellView3.layer.shadowOpacity = 0
            for label in [levelLabel, levelNameLabel, highScoreLabel] {
                label?.textColor = SettingsTableViewCell.glassForeground
            }
            highScoreTitleLabel?.textColor =
                SettingsTableViewCell.glassForeground.withAlphaComponent(0.6)
            // The "high score" caption was already the quieter of the pair and stays quieter.
            // The level thumbnail is a picture of the level and is left alone
        }
    }

    /// Whether this cell wears glass, which the level list's press feedback has to ask.
    private(set) var isGlass = false

    /// Colours the level's name, keeping the quarter-alpha fade that means locked.
    ///
    /// The screen sets this per row - full purple for a level you can play, a quarter of it
    /// for the sentence saying how to unlock one - so the cell cannot simply decide once in
    /// `awakeFromNib` the way the other labels can.
    func setNameColour(_ colour: UIColor) {
        guard isGlass else {
            levelNameLabel.textColor = colour
            return
        }
        var white: CGFloat = 0, alpha: CGFloat = 0
        colour.getWhite(&white, alpha: &alpha)
        levelNameLabel.textColor = SettingsTableViewCell.glassForeground
            .withAlphaComponent(max(0.4, alpha))
    }

    /// The press feedback, which cannot be a colour on a glass row.
    func setPressed(_ pressed: Bool, colour: UIColor) {
        UIView.animate(withDuration: 0.1) {
            self.cellView3.transform = pressed ? .init(scaleX: 0.98, y: 0.98) : .identity
            if self.isGlass == false {
                self.cellView3.backgroundColor = colour
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setBlur() {
        blurView.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .dark)
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
        // Highlighting scales cellView3 and recolours it, and that state lives on the
        // cell rather than in the data - so without this a cell highlighted on one row
        // carries the scale and colour to whichever row it is reused for, and the wrong
        // row appears to animate.
        cellView3.transform = .identity
        if isGlass == false {
            cellView3.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
    }

}
