//
//  StatsTableViewCell.swift
//  Megaball
//
//  Created by James Harding on 07/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class StatsTableViewCell: UITableViewCell {
    
    @IBOutlet var viewBackground: UIView!
    @IBOutlet var statDescription: UILabel!
    @IBOutlet var statValue: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        guard SettingsTableViewCell.addGlass(behind: viewBackground,
                                             cornerRadius: 14) != nil else { return }
        statDescription.textColor = SettingsTableViewCell.glassForeground
        statValue.textColor = SettingsTableViewCell.glassForeground
        // The gutter icon takes its tint from `statDescription` on every pass, so it follows
        // this without being told - which is the reason it was written that way
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - The icon gutter

    private var iconView: UIImageView?
    private var descriptionLeading: NSLayoutConstraint?
    private var leadingWithoutIcon: CGFloat = 0

    /// The width the label gives up so that every icon lines up with the one above it.
    ///
    /// A fixed gutter rather than each icon sitting against its own label: the symbols are
    /// different widths, and left to themselves they make a ragged edge down the page.
    private static let gutter: CGFloat = 26

    /// Puts a symbol to the left of the row, or takes one away.
    ///
    /// Called on every pass including the passes with nothing to show, because these cells are
    /// reused: a row with no icon that lands on a cell which had one keeps the gap and the
    /// picture unless it is told otherwise.
    ///
    /// The label's own leading constraint is found rather than replaced, so the nib keeps
    /// owning where the text starts and this only borrows the difference. The stats screen is
    /// not the only user of this cell - the reference pages' fact tables use it too, and they
    /// pass nothing, which is why the no-icon case has to put things back exactly.
    func showIcon(_ symbol: String?) {
        if descriptionLeading == nil {
            descriptionLeading = statDescription.superview?.constraints.first {
                ($0.firstItem === statDescription && $0.firstAttribute == .leading)
                    || ($0.secondItem === statDescription && $0.secondAttribute == .leading)
            }
            leadingWithoutIcon = descriptionLeading?.constant ?? 0
        }

        guard let symbol, let image = UIImage(systemName: symbol) else {
            iconView?.isHidden = true
            descriptionLeading?.constant = leadingWithoutIcon
            return
        }

        if iconView == nil, let host = statDescription.superview {
            let view = UIImageView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.contentMode = .scaleAspectFit
            view.tintColor = statDescription.textColor
            host.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: statDescription.leadingAnchor,
                                              constant: -StatsTableViewCell.gutter),
                view.centerYAnchor.constraint(equalTo: statDescription.centerYAnchor),
                view.widthAnchor.constraint(equalToConstant: 18),
                view.heightAnchor.constraint(equalToConstant: 18),
            ])
            // Hung off the label rather than off the cell, so it moves with the text when the
            // gutter opens instead of needing its own constant kept in step
            iconView = view
        }

        iconView?.image = image
        iconView?.isHidden = false
        iconView?.tintColor = statDescription.textColor
        descriptionLeading?.constant = leadingWithoutIcon + StatsTableViewCell.gutter
    }
}
