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

        centreTheCardInItsRow()
    }

    /// The card's full height, and the least it may shrink to in a short window.
    static let fullCard: CGFloat = 75
    static let smallestCard: CGFloat = 54
    /// The least room a row takes: the smallest card and a gap under it.
    static let smallestRow: CGFloat = smallestCard + 6

    private var cardHeight: NSLayoutConstraint?
    private var iconWidth: NSLayoutConstraint?

    /// **Centred in its row, not hung from the top of it** (James, round 351: "main menu cells
    /// not centred between bottom icons and giga-ball logo"). The nib pins the card to the top
    /// of the cell, so every row's spare height gathered under its card and the four read as a
    /// block sitting high in the room they were given - by half a gap, which on an iPad is
    /// twenty points.
    private func centreTheCardInItsRow() {
        for constraint in contentView.constraints
        where (constraint.firstItem === cellView1 && constraint.firstAttribute == .top)
            || (constraint.secondItem === cellView1 && constraint.secondAttribute == .top) {
            constraint.isActive = false
        }
        cellView1.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        cardHeight = cellView1.constraints.first {
            $0.firstAttribute == .height && $0.secondItem == nil
        }
        iconWidth = modeImageIcon.constraints.first {
            $0.firstAttribute == .width && $0.secondItem == nil
        }
    }

    /// Shrinks the card, and the icon inside it, to the row it has been given.
    ///
    /// **A short window could not hold four full cards** (James, round 351, with an iPad
    /// window: the rows bunched and the last was cut off above the buttons). The rows could
    /// crowd no closer than the card itself, seventy-five points, so four needed three hundred;
    /// now the card gives up to twenty of its own before anything is lost.
    func fitCard(toRow rowHeight: CGFloat) {
        let card = min(ModeSelectTableViewCell.fullCard,
                       max(ModeSelectTableViewCell.smallestCard, rowHeight - 6))
        cardHeight?.constant = card
        iconWidth?.constant = card - 15
        cellView1.layer.cornerRadius = card/2
        (cellView1.subviews.first { $0 is UIVisualEffectView } as? UIVisualEffectView)
            .map { glass in
                if #available(iOS 26.0, *) {
                    glass.cornerConfiguration = .corners(radius: .fixed(card/2))
                }
            }
    }

    /// Whether this cell wears glass, which the menu's press feedback has to ask.
    private(set) var isGlass = false

    // MARK: - Straight in, and today's dot (round 346)

    /// What the play button does. Nil hides it.
    ///
    /// James, round 346: "On the main menu, add a play button on the Endless Mode, Endless
    /// Mayhem and Daily Challenge cells to instantly start playing a game of that mode", then
    /// Classic too, and "only clicking the play button should start the game, clicking within
    /// the body of the cell away from the play button should take the user through to the menu
    /// view for that game mode like it does now". A real button, so a press on it is the
    /// button's and never the row's.
    var onPlay: (() -> Void)? {
        didSet { playButton.isHidden = onPlay == nil }
    }

    /// **The level rows' own play button** ("use the same play button style that's on the
    /// classic mode pack level view"): `play.fill`, heavy, in the row's foreground colour,
    /// 44 points to press, at the card's trailing edge.
    private(set) lazy var playButton: UIButton = {
        let play = UIButton(type: .system)
        play.setImage(UIImage(systemName: "play.fill",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 17,
                                                                             weight: .heavy)),
                      for: .normal)
        play.tintColor = isGlass ? SettingsTableViewCell.glassForeground
                                 : #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        play.accessibilityLabel = "Play"
        play.translatesAutoresizingMaskIntoConstraints = false
        play.addTarget(self, action: #selector(playPressed), for: .touchUpInside)
        play.isHidden = true
        cellView1.addSubview(play)
        // In the card rather than `contentView`, so a press that scales the card scales the
        // button with it (James, round 348: "when I press the cell, it and its content
        // animate, but the play button remains static")
        NSLayoutConstraint.activate([
            play.trailingAnchor.constraint(equalTo: cellView1.trailingAnchor, constant: -16),
            play.centerYAnchor.constraint(equalTo: cellView1.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 44),
            play.heightAnchor.constraint(equalToConstant: 44),
            modeTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: play.leadingAnchor,
                                                    constant: -4),
        ])
        for constraint in cellView1.constraints
        where constraint.secondItem === modeTextLabel && constraint.secondAttribute == .trailing {
            constraint.isActive = false
        }
        modeTextLabel.numberOfLines = 1
        modeTextLabel.adjustsFontSizeToFitWidth = true
        modeTextLabel.minimumScaleFactor = 0.6
        // **The name stops at the arrow** (James, round 351: "play button encroaching on text
        // at narrowest size"). The nib ends the label ten points from the card's edge, which
        // was right before the card had a button there; now it ends at the button and shrinks
        // its type rather than run underneath it
        return play
    }()

    @objc private func playPressed() {
        onPlay?()
    }

    /// The red dot on the mode's icon: something new to play (James, round 346: "when there
    /// is a new daily challenge for today that is unplayed, add a red notification circle dot
    /// icon to the top right of the game mode icon").
    var showsNotification = false {
        didSet { notificationDot.isHidden = showsNotification == false }
    }

    private lazy var notificationDot: UIView = {
        let dot = UIView()
        dot.backgroundColor = .systemRed
        dot.layer.cornerRadius = 10
        dot.layer.borderWidth = 2.5
        dot.layer.borderColor = UIColor.white.cgColor
        dot.isUserInteractionEnabled = false
        dot.isAccessibilityElement = false
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.isHidden = true
        cellView1.addSubview(dot)
        // In the card, for the same reason as the play button
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 20),
            dot.heightAnchor.constraint(equalToConstant: 20),
            // Twenty rather than fourteen (James, round 350: "make the notification dot on daily
            // challenge larger")
            dot.centerXAnchor.constraint(equalTo: modeImageIcon.trailingAnchor, constant: -9),
            dot.centerYAnchor.constraint(equalTo: modeImageIcon.topAnchor, constant: 9),
        ])
        // The badge place on an app icon: the top right, sitting on the circle's edge rather
        // than inside it. White-ringed so it reads against the lime icon it overlaps
        return dot
    }()

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
        onPlay = nil
        showsNotification = false
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
