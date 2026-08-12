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

    /// Puts a Liquid Glass panel *behind* a view rather than inside it.
    ///
    /// For a scrolling table, where a backing added as a subview would scroll away with the
    /// content. This one goes into the table's superview, underneath it, pinned to its
    /// frame - so the panel stays put and the rows travel over it.
    @discardableResult
    static func addGlass(under view: UIView, cornerRadius: CGFloat,
                         inset: CGFloat = 0) -> UIVisualEffectView? {
        guard #available(iOS 26.0, *), let parent = view.superview else { return nil }

        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = false
        effect.tintColor = SettingsTableViewCell.glassTint

        let glass = UIVisualEffectView(effect: effect)
        glass.isUserInteractionEnabled = false
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.cornerConfiguration = .corners(radius: .fixed(cornerRadius))
        glass.tag = SettingsTableViewCell.glassPanelTag
        parent.insertSubview(glass, belowSubview: view)
        view.backgroundColor = .clear

        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            glass.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            glass.topAnchor.constraint(equalTo: view.topAnchor),
            glass.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        return glass
    }

    /// How a panel added by `addGlass(under:)` is found again.
    static let glassPanelTag = 8802

    /// Shrinks a table's panel to the height of the rows actually in it.
    ///
    /// A table laid out to fill the page leaves the panel filling the page too, so four
    /// facts sat at the top of an empty card the height of the screen. The panel now stops
    /// where the content does - and when the content is taller than the table it fills the
    /// table exactly as before, because the slack is clamped at zero.
    ///
    /// Call it from `viewDidLayoutSubviews`: content size is not known until the table has
    /// laid its rows out, and it changes whenever the data does.
    static func fitGlassPanel(under view: UIScrollView) {
        guard let parent = view.superview else { return }
        guard let glass = parent.subviews.first(where: {
            $0 is UIVisualEffectView && $0.tag == glassPanelTag
        }) else { return }
        guard let bottom = parent.constraints.first(where: {
            $0.firstItem === glass && $0.firstAttribute == .bottom
        }) else { return }

        let slack = max(0, view.bounds.height - view.contentSize.height)
        guard abs(bottom.constant + slack) > 0.5 else { return }
        // Only when it actually moves. This runs on every layout pass, and changing a
        // constant unconditionally would ask for another one straight back
        bottom.constant = -slack
    }

    /// Whether this device draws the app's surfaces as glass.
    ///
    /// For the handful of marks that are neither a cell's own nor made by `addGlass` - the
    /// play arrow the level list draws into its rows is the one - and so have to ask.
    static var glassIsAvailable: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    /// Puts a Liquid Glass backing behind a view's contents, iOS 26 and up.
    ///
    /// Returns the effect view when it made one and `nil` below iOS 26, so a caller can ask
    /// unconditionally and use the answer as its "am I glass?" flag.
    ///
    /// **Why it lives on a table cell.** This is where the tint and the foreground colour
    /// already are, and six unrelated types now want the same three lines. Its proper home is
    /// a file of its own; adding one means four hand-edits to `project.pbxproj`, so that is
    /// queued rather than done in the middle of a visual pass.
    @discardableResult
    static func addGlass(behind host: UIView, cornerRadius: CGFloat,
                         tint: UIColor? = nil) -> UIVisualEffectView? {
        guard #available(iOS 26.0, *) else { return nil }

        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = false
        effect.tintColor = tint ?? SettingsTableViewCell.glassTint

        let glass = UIVisualEffectView(effect: effect)
        glass.isUserInteractionEnabled = false
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.cornerConfiguration = .corners(radius: .fixed(cornerRadius))
        host.insertSubview(glass, at: 0)
        host.backgroundColor = .clear

        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            glass.topAnchor.constraint(equalTo: host.topAnchor),
            glass.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        return glass
    }

    /// How tall a glass row is: 78 rather than the 70 the flat cards use.
    ///
    /// The card's bottom is pinned 20pt above the row's, so the extra height all goes into
    /// the card. It is needed because the material draws an outline the flat grey never had,
    /// and the same content inside a frame you can actually see reads as crammed against it
    /// (round 63). Every screen that glasses its rows wants it, so it lives here.
    static let glassRowHeight: CGFloat = 78

    private var glassView: UIVisualEffectView?

    /// Whether this cell is currently wearing glass, which its icon and its tap feedback
    /// both need to know.
    var isGlass: Bool { glassView != nil }

    /// Turns the row's light card into a glass one. iOS 26 and later; a no-op before that,
    /// so a caller can ask unconditionally and older devices keep the card they have.
    func applyGlass(cornerRadius: CGFloat = 14) {
        guard #available(iOS 26.0, *) else { return }
        guard glassView == nil else { return }

        cellView2.backgroundColor = .clear
        cellView2.layer.shadowOpacity = 0
        // A clear layer casts no shadow anyway, and leaving the purple one set would only
        // wait to reappear the moment something gave the layer a path

        cellView2.layer.cornerRadius = cornerRadius
        // Rounded only here. The nib's rows are square-cornered, which is right for an
        // opaque card butted against its neighbours and wrong for glass - the material's
        // own edge highlight needs a curve to run along or it reads as a grey rectangle

        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = false
        // **Off, deliberately** (round 64). Interactive glass reacts to touches by stretching
        // toward whatever it is being pulled at, and these effect views cannot receive touches
        // at all - the row and the button both take their taps through the control underneath.
        // Asking a material to respond to a press it never sees is how the close button ended
        // up smearing a white blob across the screen on a long press. The app draws its own
        // press feedback, so nothing is lost
        effect.tintColor = SettingsTableViewCell.glassTint

        let glass = UIVisualEffectView(effect: effect)
        glass.isUserInteractionEnabled = false
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.cornerConfiguration = .corners(radius: .fixed(cornerRadius))
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

        tickImage.image = tickImage.image?.withRenderingMode(.alwaysTemplate)
        tickImage.tintColor = SettingsTableViewCell.glassForeground
        // The completion tick comes from the nib in the same dark purple as everything else,
        // and it is the one mark on these pages that says "you have this" - the last thing
        // that should be invisible
    }

    /// Sets the row's glyph, recoloured if the row is glass.
    ///
    /// The artwork is a flat dark-purple shape, drawn for a light card. Template rendering
    /// throws its colour away and keeps its silhouette, which is the only reason the same
    /// PNGs can be reused on a dark row at all - without it every icon would be a purple
    /// hole in the glass.
    /// - Parameter recolour: whether the artwork is a flat glyph that should be redrawn in
    ///   the row's foreground colour. **True only for the interface glyphs.** Pack icons,
    ///   theme swatches, app icons, brick art and power-up icons are pictures, and template
    ///   rendering would flatten every one of them to a white silhouette. There is no safe
    ///   default here, so every caller has to say which kind of image it is holding.
    func setIcon(_ image: UIImage?, recolour: Bool) {
        iconImage.image = (isGlass && recolour)
            ? image?.withRenderingMode(.alwaysTemplate) : image
    }

    /// Colours the row's name, keeping the locked/unlocked distinction on a glass row.
    ///
    /// The unlock pages say "you cannot have this yet" by dropping the label to a quarter
    /// alpha of the same purple. The purple has to go on glass, but the *fading* is the
    /// message and it stays - floored at 0.4, because a quarter-opacity off-white on a dark
    /// row is nearly gone where a quarter-opacity purple on white was merely faint.
    func setLabelColour(_ colour: UIColor) {
        guard isGlass else {
            settingDescription.textColor = colour
            return
        }
        var white: CGFloat = 0, alpha: CGFloat = 0
        colour.getWhite(&white, alpha: &alpha)
        settingDescription.textColor = SettingsTableViewCell.glassForeground
            .withAlphaComponent(max(0.4, alpha))
    }

    /// Colours the state column, inverting the scheme on a glass row.
    ///
    /// The flat card encoded meaning in *darkness*: the app's near-black purple for "on", mid
    /// grey for "off", and for paddle speed a four-step grey ramp where darker meant faster.
    /// Every one of those is invisible on a dark row, and simply forcing them all to off-white
    /// would throw the meaning away with the colour. So the scale is turned over - the darker
    /// the row wanted it, the more opaque it becomes - and the ramp survives the move.
    func setStateColour(_ colour: UIColor) {
        guard isGlass else {
            settingState.textColor = colour
            return
        }
        var white: CGFloat = 0, alpha: CGFloat = 0
        colour.getWhite(&white, alpha: &alpha)
        settingState.textColor = SettingsTableViewCell.glassForeground
            .withAlphaComponent(min(1, max(0.42, 1.05 - white)))
    }

    /// Presses or releases the row's card.
    ///
    /// Six screens each wrote this animation out twice, once to highlight and once to let go.
    /// It is one method now because glass changed the rules: **the colour has to be skipped on
    /// a glass row.** Painting into `cellView2` paints *over* the material, so a press that
    /// flashed the app's lime put the flat card back for as long as the touch lasted - which
    /// the Information screen was doing from the moment it went glass. A glass row shrinks and
    /// nothing else.
    func setPressed(_ pressed: Bool, colour: UIColor, duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            self.cellView2.transform = pressed ? .init(scaleX: 0.98, y: 0.98) : .identity
            if self.isGlass == false {
                self.cellView2.backgroundColor = colour
            }
        }
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
        tickImage.image = tickImage.image?.withRenderingMode(.alwaysOriginal)
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
