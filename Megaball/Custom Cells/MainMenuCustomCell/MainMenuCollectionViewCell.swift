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


    /// Dresses this round button as Liquid Glass with an SF Symbol on it.
    ///
    /// The round buttons are PNGs with the circle and the glyph welded into one opaque disc,
    /// and glass cannot sit behind that - so a button becomes glass by giving up its artwork
    /// for a system glyph. `xmark` is the easiest of them to give up: it carries no identity
    /// worth keeping, where a pack icon or the Giga-Ball play would.
    ///
    /// Same recipe as the big return-to-game play (`applyRoundGlass`), and deliberately the
    /// same numbers, with one exception: **the tint is lighter at this size**. A 40pt disc has
    /// proportionally far more rim than material than a 75pt one, so the same tint reads as a
    /// bolder edge on the smaller button - the constant has to scale with the shape or the two
    /// look like different materials.
    /// Which system glyph stands in for each of the PNG buttons.
    ///
    /// A button can only be glass if its mark can be drawn separately from its disc, and the
    /// artwork welds the two together - so this table is the whole roll-out. A name absent
    /// from it keeps its PNG, which is how `ButtonNull` stays the invisible spacer it is
    /// rather than acquiring a disc of its own.
    static let systemGlyph: [String: String] = [
        "ButtonClose": "xmark",
        "ButtonInfo": "info",
        "ButtonSettings": "gearshape.fill",
        "ButtonPlay": "play.fill",
        "ButtonRestart": "arrow.clockwise",
        "ButtonHome": "house.fill",
        "ButtonLeaderboard": "trophy.fill",
    ]

    /// Sets a button by its artwork name, glassing it where a system glyph will stand in.
    ///
    /// The PNG is assigned first and then replaced, so a device below iOS 26 keeps exactly
    /// the button it has always had. A cell already wearing glass ignores the call entirely,
    /// which is what makes the pressed-state artwork a no-op without every screen having to
    /// remember that - and forgetting it is precisely what painted a 210pt image across the
    /// screen for three rounds.
    /// The point size a big glass button's glyph is drawn at.
    ///
    /// **34, where `applyRoundGlass` gets the same apparent size out of 28.** Rounds 68-70
    /// matched the point size, then the weight, then the shadow, and the play test measured
    /// the cell's glyph smaller every time - on the pack, level, endless, mayhem and pause
    /// screens, all of which come through here, while the four screens using
    /// `applyRoundGlass` were right. Three reports with screenshots beat an explanation I
    /// cannot find, so this is the size that matches by measurement. If the cause ever
    /// surfaces, this constant is where to undo it.
    static let bigGlyphPointSize: CGFloat = 34

    /// How wide a small round button is.
    ///
    /// 50, which is what the main menu's information and settings buttons have always been -
    /// every other screen used 40 and the play test read the difference as the rest of the
    /// app being cramped (round 75). One constant rather than the number written out at
    /// twenty call sites, so the next opinion about it is one edit.
    static let smallButtonSize: CGFloat = 50

    func setButton(_ named: String, pointSize: CGFloat = 20, rimmed: Bool = false) {
        guard isGlass == false else { return }
        iconImage.image = UIImage(named: named)
        let base = named.replacingOccurrences(of: ".png", with: "")
                        .replacingOccurrences(of: "Highlighted", with: "")
        guard let symbol = MainMenuCollectionViewCell.systemGlyph[base] else { return }
        applyGlass(symbol: symbol, pointSize: pointSize, rimmed: rimmed)
    }

    func applyGlass(symbol: String, pointSize: CGFloat = 20, rimmed: Bool = false) {
        guard #available(iOS 26.0, *) else { return }
        guard glassView == nil else { return }

        let effect = UIGlassEffect(style: rimmed ? .clear : .regular)
        effect.isInteractive = false
        // See `SettingsTableViewCell.applyGlass` for why: this view cannot receive touches,
        // and an interactive material that is pressed through something else stretches toward
        // the touch and leaves a white smear behind (round 64)
        effect.tintColor = rimmed
            ? SettingsTableViewCell.prominentTint
            : UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 0.24)
        // `rimmed` is only ever the big play, so it is also the flag for "this is the
        // positive action" - lime in clear glass, where the small buttons stay purple

        let glass = UIVisualEffectView(effect: effect)
        glass.isUserInteractionEnabled = false
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.cornerConfiguration = .capsule()
        if rimmed {
            glass.layer.cornerRadius = 37.5
            glass.layer.borderWidth = 2.5
            glass.layer.borderColor = UIColor(white: 1, alpha: 0.20).cgColor
        }
        // The explicit rim the big return-to-game play wears, and only at that size: a 75pt
        // disc has proportionally little edge for the material's own highlight to show on,
        // where a 40pt one has plenty (rounds 60-61 are the argument, this is the reuse)
        view.insertSubview(glass, at: 0)
        glassView = glass

        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: iconImage.topAnchor),
            glass.bottomAnchor.constraint(equalTo: iconImage.bottomAnchor),
            glass.leadingAnchor.constraint(equalTo: iconImage.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: iconImage.trailingAnchor),
        ])
        // **The icon's footprint, not the cell's** (round 68). `view` fills the cell, and the
        // pause screen hands every cell a 75pt square regardless of which button it holds -
        // the artwork was what made the side buttons look small, because `widthConstraint`
        // sizes `iconImage` to 40 and the PNG was drawn inside that. Pinning the material to
        // the cell made all three the size of the play button. Bound to the icon it is
        // exactly as big as the disc it replaces, on every screen, and it follows
        // `widthConstraint` automatically whenever a caller sets it after this runs

        iconImage.image = UIImage(systemName: symbol,
                                  withConfiguration: UIImage.SymbolConfiguration(
                                      pointSize: pointSize,
                                      weight: rimmed ? .black : .bold))?
            .withTintColor(rimmed ? UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1)
                                  : UIColor(white: 0.92, alpha: 1),
                           renderingMode: .alwaysOriginal)
        iconImage.contentMode = .center
        iconImage.layer.masksToBounds = false
        iconImage.layer.shadowColor = UIColor.black.cgColor
        iconImage.layer.shadowOpacity = 0.45
        iconImage.layer.shadowRadius = 4
        iconImage.layer.shadowOffset = .zero
        // **The clip is gone again, and the shadow is why** (round 70). Round 66 turned
        // `masksToBounds` on as insurance against a screen assigning `iconImage.image`
        // directly and painting the 210pt close artwork across the screen. A masked layer
        // cannot draw a shadow outside its own bounds, so the insurance silently took the
        // glyph's soft dark halo away - and a glyph with no halo reads *smaller*, which is
        // what the play test kept seeing and what two rounds of matching point sizes and
        // weights could never have explained. The insurance is no longer needed: every call
        // site goes through `setButton` now, and that returns early on a glass cell.
        //
        // The shadow is black at 0.45, the same as the big return-to-game play's, so the two
        // are now identical in every respect rather than merely in point size
        // **`.center`, not `.scaleAspectFit`** (round 61). Aspect-fit scales *up* as well as
        // down, so the symbol was being blown up to fill a 40pt image view whatever point size
        // it was made at - which is why round 59's drop from 17pt to 13pt changed nothing and
        // the mark still filled its disc. `.center` draws the image at its natural size, so
        // the point size above is finally the dial it looks like - and 15pt, which is what
        // the run before this asked for, turned out to be too *small* once it was honoured.
        //
        // `.black` on the big buttons, `.bold` on the small ones. The point size matched the
        // return-to-game play all along and the glyph still read smaller, because that one is
        // drawn at `.black` - a heavier play.fill is visibly wider as well as thicker, and
        // weight was the difference the point size could not explain (round 69)
        //
        // Off-white rather than pure white, matching the discs the other round buttons wear:
        // white was right when the glyph had to fight a tinted material for attention, and
        // reads as harsh now the rim carries the contrast
        // Baked white for the same reason the big one is: a tint is a request the material can
        // reinterpret, and this glyph sits on a surface whose brightness is whatever is behind
        // it. The shadow `awakeFromNib` already puts on every icon does the rest
    }

    private var glassView: UIVisualEffectView?

    /// Whether this button is wearing glass, which the pressed-state artwork has to know.
    var isGlass: Bool { glassView != nil }

    /// Swaps in the pressed artwork, unless the button is glass.
    ///
    /// The PNG buttons show a darker disc while held. A glass button has no disc to swap -
    /// its artwork is a system glyph over a material - so handing it `ButtonCloseHighlighted`
    /// would put the old opaque disc straight back on top of the glass for the length of the
    /// press. The 0.95 shrink every one of these already does is the feedback (round 64).
    func setPressedArtwork(_ image: UIImage?) {
        guard isGlass == false else { return }
        iconImage.image = image
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        glassView?.removeFromSuperview()
        glassView = nil
        // The glass goes with the reuse. These cells serve every round button on the screen
        // and only some of them are glass - a leftover disc behind a PNG would be a halo
        // round a button that never asked for one
        iconImage.contentMode = .scaleAspectFit
        iconImage.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        iconImage.layer.shadowOpacity = 0.5
        // Back to the nib's purple halo, since a reused cell may be a PNG button next
        // **The nib's mode, put back** (round 65). `applyGlass` switches this to `.center` so
        // the SF Symbol draws at its own point size - and `.center` draws *any* image at its
        // natural size. `ButtonNull` is a 210pt asset, `clipsToBounds` is off on this cell for
        // the big play button's sake, and so the moment the close cell was reused for one of
        // the blank buttons beside it the artwork was drawn five times too big and spilled
        // across the screen. That is the white shape that kept appearing next to the close
        // button on a press - not the material at all, which is where two rounds went looking
        // Highlighting scales the cell view and recolours it, and that state lives on the
        // cell rather than in the data - so without this a cell highlighted on one row
        // carries the scale and colour to whichever row it is reused for, and the wrong
        // row appears to animate.
        view.transform = .identity
    }

}
