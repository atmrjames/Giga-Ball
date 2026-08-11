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

    private func build() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = PackGridCell.cardColour
        card.layer.cornerRadius = 12
        contentView.addSubview(card)

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        card.addSubview(icon)

        name.translatesAutoresizingMaskIntoConstraints = false
        name.textAlignment = .center
        name.numberOfLines = 2
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.7
        name.font = .systemFont(ofSize: 13, weight: .semibold)
        name.textColor = PackGridCell.ink
        card.addSubview(name)

        tick.translatesAutoresizingMaskIntoConstraints = false
        tick.contentMode = .scaleAspectFit
        tick.image = UIImage(systemName: "checkmark.circle.fill",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 15,
                                                                            weight: .bold))
        tick.tintColor = PackGridCell.ink
        card.addSubview(tick)

        lock.translatesAutoresizingMaskIntoConstraints = false
        lock.contentMode = .scaleAspectFit
        lock.image = UIImage(systemName: "lock.fill",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 22,
                                                                            weight: .bold))
        lock.tintColor = PackGridCell.ink.withAlphaComponent(0.4)
        card.addSubview(lock)

        play.translatesAutoresizingMaskIntoConstraints = false
        play.setImage(UIImage(systemName: "list.bullet",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 13,
                                                                             weight: .bold)),
                      for: .normal)
        play.tintColor = PackGridCell.ink
        play.addTarget(self, action: #selector(listTapped), for: .touchUpInside)
        card.addSubview(play)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // The icon hangs from the top and the name follows it, so the pair reads as one
            // block. Sized as a fraction of the card rather than in points, because the grid
            // works its cell size out from the screen it finds itself on
            icon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            icon.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.42),
            icon.heightAnchor.constraint(equalTo: icon.widthAnchor),

            name.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            name.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            name.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 4),

            lock.centerXAnchor.constraint(equalTo: icon.centerXAnchor),
            lock.centerYAnchor.constraint(equalTo: icon.centerYAnchor),

            tick.topAnchor.constraint(equalTo: card.topAnchor, constant: 5),
            tick.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -5),

            play.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -1),
            play.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -1),
            play.widthAnchor.constraint(equalToConstant: 30),
            play.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    /// Fills the cell in. Everything it can show is set on every pass, including the things
    /// being switched off, because a reused cell arrives wearing the last pack's state.
    func show(name packName: String, icon packIcon: UIImage?,
              unlocked: Bool, completed: Bool) {
        name.text = packName
        icon.image = unlocked ? packIcon : nil
        icon.isHidden = unlocked == false
        lock.isHidden = unlocked
        tick.isHidden = completed == false || unlocked == false
        play.isHidden = unlocked == false

        // A locked pack's name is the sentence saying how to unlock it, which is longer than a
        // pack name and needs the smaller type and the third line to fit the square
        name.font = .systemFont(ofSize: unlocked ? 13 : 10, weight: .semibold)
        name.numberOfLines = unlocked ? 2 : 3
        name.textColor = unlocked ? PackGridCell.ink : PackGridCell.ink.withAlphaComponent(0.4)
        card.alpha = unlocked ? 1 : 0.55
    }

    @objc private func listTapped() {
        onOpenList?()
    }

    /// The press state the rows had, kept: the whole card lights up rather than a highlight
    /// appearing behind it, because the card *is* the button here.
    func setPressed(_ pressed: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.card.transform = pressed ? .init(scaleX: 0.96, y: 0.96) : .identity
            self.card.backgroundColor = pressed ? PackGridCell.pressed : PackGridCell.cardColour
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onOpenList = nil
        card.transform = .identity
        card.backgroundColor = PackGridCell.cardColour
    }
}
