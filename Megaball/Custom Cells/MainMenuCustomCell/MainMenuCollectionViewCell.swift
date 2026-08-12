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
    func applyGlass(symbol: String) {
        guard #available(iOS 26.0, *) else { return }
        guard glassView == nil else { return }

        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = false
        // See `SettingsTableViewCell.applyGlass` for why: this view cannot receive touches,
        // and an interactive material that is pressed through something else stretches toward
        // the touch and leaves a white smear behind (round 64)
        effect.tintColor = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 0.24)

        let glass = UIVisualEffectView(effect: effect)
        glass.isUserInteractionEnabled = false
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.cornerConfiguration = .capsule()
        view.insertSubview(glass, at: 0)
        glassView = glass

        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: view.topAnchor),
            glass.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            glass.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        iconImage.image = UIImage(systemName: symbol,
                                  withConfiguration: UIImage.SymbolConfiguration(
                                      pointSize: 20, weight: .bold))?
            .withTintColor(UIColor(white: 0.92, alpha: 1), renderingMode: .alwaysOriginal)
        iconImage.contentMode = .center
        // **`.center`, not `.scaleAspectFit`** (round 61). Aspect-fit scales *up* as well as
        // down, so the symbol was being blown up to fill a 40pt image view whatever point size
        // it was made at - which is why round 59's drop from 17pt to 13pt changed nothing and
        // the mark still filled its disc. `.center` draws the image at its natural size, so
        // the point size above is finally the dial it looks like - and 15pt, which is what
        // the run before this asked for, turned out to be too *small* once it was honoured.
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
        // Highlighting scales the cell view and recolours it, and that state lives on the
        // cell rather than in the data - so without this a cell highlighted on one row
        // carries the scale and colour to whichever row it is reused for, and the wrong
        // row appears to animate.
        view.transform = .identity
    }

}
