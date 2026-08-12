//
//  PackGridCell.swift
//  Megaball
//
//  One pack, as a square.
//
//  The pack screen used to be eleven full-width rows, which meant eleven screens' worth of
//  reading to find the one you wanted and no room for the mode's own title and logo above them.
//  As a grid of squares all eleven fit at once, and the screen looks like its two endless
//  siblings rather than like a settings list (play-test request).
//
//  Built in code rather than as a nib because it is small, because it is only used here, and
//  because a nib is a fifth place to register a file in the project - the sort of thing this
//  project has been bitten by.
//

import UIKit

final class PackGridCell: UICollectionViewCell {

    static let reuseIdentifier = "packGridCell"

    /// Tapped to open the pack's list of levels. The screen sets this; the cell does not know
    /// what a pack is.
    ///
    /// The button is the *list*, not the play, and that is the way round it should have been
    /// from the start (play-test round 33): the common thing is to play the pack, so the whole
    /// cell does that, and the less common thing - picking a level inside it - is what earns a
    /// control of its own.
    var onOpenList: (() -> Void)?

    private let card = UIView()
    /// The icon and the name, so the pair can be centred as one thing.
    private let block = UIStackView()
    private let icon = UIImageView()
    private let name = UILabel()
    private let tick = UIImageView()
    private let lock = UIImageView()
    /// Opens the pack's level list. Named for where it sits rather than for what it was.
    private let play = UIButton(type: .system)

    private static let cardColour = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
    private static let ink = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
    private static let pressed = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    /// Whether this cell wears glass, which every colour decision below has to ask.
    private var isGlass = false
    /// What a glass cell draws its marks in - the off-white the rest of the app's glass uses.
    private static let onGlass = UIColor(white: 0.92, alpha: 1)

    /// The colour a mark should be, given what it is sitting on.
    private func mark(_ alpha: CGFloat = 1) -> UIColor {
        (isGlass ? PackGridCell.onGlass : PackGridCell.ink).withAlphaComponent(alpha)
    }

    private func build() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 12
        contentView.addSubview(card)
        applyGlass()
        if isGlass == false {
            card.backgroundColor = PackGridCell.cardColour
        }

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit

        block.translatesAutoresizingMaskIntoConstraints = false
        block.axis = .vertical
        block.alignment = .center
        block.spacing = 6
        block.addArrangedSubview(icon)
        card.addSubview(block)

        name.translatesAutoresizingMaskIntoConstraints = false
        name.textAlignment = .center
        name.numberOfLines = 2
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.7
        name.font = .systemFont(ofSize: 13, weight: .semibold)
        name.textColor = mark()
        block.addArrangedSubview(name)

        tick.translatesAutoresizingMaskIntoConstraints = false
        tick.contentMode = .scaleAspectFit
        tick.image = UIImage(systemName: "checkmark.circle.fill",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 17,
                                                                            weight: .bold))
        tick.tintColor = mark()
        card.addSubview(tick)

        lock.translatesAutoresizingMaskIntoConstraints = false
        lock.contentMode = .scaleAspectFit
        lock.image = UIImage(systemName: "lock.fill",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 22,
                                                                            weight: .bold))
        lock.tintColor = mark(0.4)
        card.addSubview(lock)

        play.translatesAutoresizingMaskIntoConstraints = false
        play.setImage(UIImage(systemName: "list.bullet",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 15,
                                                                             weight: .bold)),
                      for: .normal)
        play.tintColor = mark()
        play.addTarget(self, action: #selector(listTapped), for: .touchUpInside)
        card.addSubview(play)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // The icon and the name are one block, centred in the card as a pair rather than
            // hung from the top - top-anchored they sat high with a pool of empty card under
            // them, which is what the play-test saw. `block` is what gets centred; the two
            // just fill it, so the pair moves together and neither has to know the other's
            // height. Sized as a fraction of the card rather than in points, because the grid
            // works its cell size out from the screen it finds itself on
            block.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            block.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: 5),
            // Nudged down off dead centre (play-test round 37): the two corner marks now sit
            // along the top edge, so true centre reads as slightly high against them
            block.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            block.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),

            icon.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.42),
            icon.heightAnchor.constraint(equalTo: icon.widthAnchor),

            lock.centerXAnchor.constraint(equalTo: icon.centerXAnchor),
            lock.centerYAnchor.constraint(equalTo: icon.centerYAnchor),

            // The two corner marks mirror each other - list top-left, tick top-right, the
            // same size - so the card reads as balanced rather than as a control and a
            // sticker (play-test round 36; the list button sat against the name before)
            tick.topAnchor.constraint(equalTo: card.topAnchor, constant: 7),
            tick.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -7),

            play.topAnchor.constraint(equalTo: card.topAnchor, constant: 1),
            play.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 1),
            play.widthAnchor.constraint(equalToConstant: 32),
            play.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    /// Fills the cell in. Everything it can show is set on every pass, including the things
    /// being switched off, because a reused cell arrives wearing the last pack's state.
    func show(name packName: String, icon packIcon: UIImage?,
              unlocked: Bool, completed: Bool) {
        name.text = packName
        icon.image = unlocked
            ? (isGlass ? packIcon?.withRenderingMode(.alwaysTemplate) : packIcon)
            : nil
        icon.tintColor = mark()
        // Template-rendered on glass. A pack icon is a flat mark in the app's dark purple,
        // drawn to sit on a light card, so on a dark one it has to be recoloured or the
        // square is a name with an empty space above it
        icon.isHidden = unlocked == false
        lock.isHidden = unlocked
        tick.isHidden = completed == false || unlocked == false
        play.isHidden = unlocked == false

        // A locked pack's name is the sentence saying how to unlock it, which is longer than a
        // pack name and needs the smaller type and the third line to fit the square
        name.font = .systemFont(ofSize: unlocked ? 13 : 10, weight: .semibold)
        name.numberOfLines = unlocked ? 2 : 3
        name.textColor = unlocked ? mark() : mark(0.4)
        card.alpha = unlocked ? 1 : 0.55
    }

    /// Dresses the card as Liquid Glass, iOS 26 and up.
    ///
    /// The grid's squares are the same kind of surface as the settings rows, so they get the
    /// same material and the same tint - and, like the rows, the pack icon has to be
    /// recoloured, because a pack icon is a flat single-colour glyph and not the picture its
    /// name suggests. That is the distinction round 66 got wrong on the Mode Select screen.
    private func applyGlass() {
        guard #available(iOS 26.0, *) else { return }
        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = false
        effect.tintColor = SettingsTableViewCell.glassTint

        let glass = UIVisualEffectView(effect: effect)
        glass.isUserInteractionEnabled = false
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.cornerConfiguration = .corners(radius: .fixed(12))
        card.insertSubview(glass, at: 0)
        isGlass = true

        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            glass.topAnchor.constraint(equalTo: card.topAnchor),
            glass.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])
    }

    @objc private func listTapped() {
        onOpenList?()
    }

    /// The press state the rows had, kept: the whole card lights up rather than a highlight
    /// appearing behind it, because the card *is* the button here.
    func setPressed(_ pressed: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.card.transform = pressed ? .init(scaleX: 0.96, y: 0.96) : .identity
            if self.isGlass == false {
                self.card.backgroundColor = pressed ? PackGridCell.pressed : PackGridCell.cardColour
            }
            // A glass card shrinks and nothing more. Painting the lime in would put an opaque
            // card back over the material for as long as the finger was down
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onOpenList = nil
        card.transform = .identity
        if isGlass == false {
            card.backgroundColor = PackGridCell.cardColour
        }
    }
}
