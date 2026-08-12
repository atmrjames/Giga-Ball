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
    

    // MARK: - Liquid Glass

    /// The tint every glass surface in the app is given: the app's purple, well under half
    /// opacity, so the material still reads as glass rather than as tinted plastic.
    static let glassTint = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 0.24)

    /// What a glass row's text and glyphs are drawn in.
    ///
    /// The same off-white the round buttons wear. A glass row is dark - it is the game
    /// behind it, dimmed - so the nib's dark purple would be near-invisible on it, which is
    /// the whole reason this is a decision and not just a background swap.
    static let glassForeground = UIColor(white: 0.92, alpha: 1)

    private var glassView: UIVisualEffectView?

    /// Whether this cell is currently wearing glass, which its icon and its tap feedback
    /// both need to know.
    var isGlass: Bool { glassView != nil }

    /// Turns the row's light card into a glass one. iOS 26 and later; a no-op before that,
    /// so a caller can ask unconditionally and older devices keep the card they have.
    func applyGlass() {
        guard #available(iOS 26.0, *) else { return }
        guard glassView == nil else { return }

        cellView2.backgroundColor = .clear
        cellView2.layer.shadowOpacity = 0
        // A clear layer casts no shadow anyway, and leaving the purple one set would only
        // wait to reappear the moment something gave the layer a path

        cellView2.layer.cornerRadius = 14
        // Rounded only here. The nib's rows are square-cornered, which is right for an
        // opaque card butted against its neighbours and wrong for glass - the material's
        // own edge highlight needs a curve to run along or it reads as a grey rectangle

        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = true
        effect.tintColor = SettingsTableViewCell.glassTint

        let glass = UIVisualEffectView(effect: effect)
        glass.isUserInteractionEnabled = false
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.cornerConfiguration = .corners(radius: .fixed(14))
        cellView2.insertSubview(glass, at: 0)
        glassView = glass

        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: cellView2.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: cellView2.trailingAnchor),
            glass.topAnchor.constraint(equalTo: cellView2.topAnchor),
            glass.bottomAnchor.constraint(equalTo: cellView2.bottomAnchor),
        ])

        settingDescription.textColor = SettingsTableViewCell.glassForeground
        settingState.textColor = SettingsTableViewCell.glassForeground
        centreLabel.textColor = SettingsTableViewCell.glassForeground
        iconImage.tintColor = SettingsTableViewCell.glassForeground
    }

    /// Sets the row's glyph, recoloured if the row is glass.
    ///
    /// The artwork is a flat dark-purple shape, drawn for a light card. Template rendering
    /// throws its colour away and keeps its silhouette, which is the only reason the same
    /// PNGs can be reused on a dark row at all - without it every icon would be a purple
    /// hole in the glass.
    func setIcon(_ image: UIImage?) {
        iconImage.image = isGlass ? image?.withRenderingMode(.alwaysTemplate) : image
    }

    /// The press feedback, which cannot be a colour change on a glass row.
    ///
    /// An opaque card goes a shade darker. Painting a colour into `cellView2` on a glass
    /// row would paint *over* the material and put the light card back for as long as the
    /// touch lasted, so a glass row shrinks and does nothing else - which is what the
    /// material's own interactive response is there for.
    func showTapFeedback() {
        UIView.animate(withDuration: 0.2) {
            self.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            if self.isGlass == false {
                self.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        glassView?.removeFromSuperview()
        glassView = nil
        cellView2.layer.cornerRadius = 0
        cellView2.layer.shadowOpacity = 0.5
        settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        centreLabel.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        // Every screen shares this nib, so a glass row reused by a screen that has not
        // asked for glass has to come back as the card it was born as - all of it, not
        // just the background, or a settings row inherits an off-white label it cannot
        // be read against
        // Highlighting scales cellView2 and recolours it, and that state lives on the
        // cell rather than in the data - so without this a cell highlighted on one row
        // carries the scale and colour to whichever row it is reused for, and the wrong
        // row appears to animate.
        cellView2.transform = .identity
        cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
    }

}
