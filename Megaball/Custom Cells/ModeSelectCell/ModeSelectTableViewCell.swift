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
        cellView1.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        cellView1.layer.shadowOpacity = 0.25
        cellView1.layer.shadowRadius = 4

        isGlass = SettingsTableViewCell.addGlass(behind: cellView1,
                                                 cornerRadius: 37.5) != nil
        if isGlass {
            cellView1.layer.shadowOpacity = 0
            modeTextLabel.textColor = SettingsTableViewCell.glassForeground
        }
        // The mode icons are pictures - a purple ball, a lime infinity, a calendar - so they
        // are left exactly as they are. Only the name has to move off the app's dark purple
    }

    /// Whether this cell wears glass, which the menu's press feedback has to ask.
    private(set) var isGlass = false

    /// The press feedback, which cannot be a colour on a glass row.
    func setPressed(_ pressed: Bool, colour: UIColor) {
        UIView.animate(withDuration: 0.1) {
            self.cellView1.transform = pressed ? .init(scaleX: 0.98, y: 0.98) : .identity
            if self.isGlass == false {
                self.cellView1.backgroundColor = colour
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

    override func prepareForReuse() {
        super.prepareForReuse()
        // Highlighting scales cellView1 and recolours it, and that state lives on the
        // cell rather than in the data - so without this a cell highlighted on one row
        // carries the scale and colour to whichever row it is reused for, and the wrong
        // row appears to animate.
        cellView1.transform = .identity
        if isGlass == false {
            cellView1.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
    }

}
