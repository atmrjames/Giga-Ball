//
//  DailyCardView.swift
//  Megaball
//
//  One day's challenge, as a card - the thing the briefing screen pages through.
//
//  This exists because the briefing screen spent three play-test rounds being asked to
//  browse days "like a normal list view", and could not: it owned exactly one card and
//  swapped its contents when the swipe finished, so the next day was never on screen
//  during the gesture. No amount of tuning the animation fixes that. More than one card
//  does, and more than one card means the card has to be a thing rather than a handful of
//  outlets on the screen.
//
//  So a card knows how to show any day, given the day's key and the player's record for
//  it. It holds no state about *which* day is current - that belongs to the pager.
//

import UIKit

final class DailyCardView: UIView {

    private let modeLabel = UILabel()
    private let levelImageView = UIImageView()
    private let levelLabel = UILabel()
    private let twistsStack = UIStackView()
    private let resultLabel = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    private let detailsCard = UIView()
    private let resultCard = UIView()
    private let column = UIStackView()

    private func build() {
        translatesAutoresizingMaskIntoConstraints = false

        for card in [detailsCard, resultCard] {
            card.backgroundColor = UIColor(white: 1, alpha: 0.07)
            card.layer.cornerRadius = 18
        }
        // Two containers, not one (play-test round 16): the day's rules are one thing to
        // read and what you scored on it is another. They travel together because they
        // are both this day's, which is what makes them one page of the pager

        for label in [modeLabel, levelLabel, resultLabel] {
            label.textAlignment = .center
            label.numberOfLines = 0
        }
        modeLabel.font = .systemFont(ofSize: 24, weight: .black)
        modeLabel.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        modeLabel.adjustsFontSizeToFitWidth = true
        modeLabel.applyGigaBallGlow(radius: GigaBallGlow.headingRadius)
        // The mode's own title, in the face and colour its menu gives it (play-test round
        // 17) - but at 24pt against the screen title's 35, so the day's mode reads as the
        // card's heading rather than competing with DAILY CHALLENGE above it
        levelLabel.font = .systemFont(ofSize: 17)
        levelLabel.textColor = UIColor(white: 1, alpha: 0.8)

        levelImageView.contentMode = .scaleAspectFit
        levelImageView.layer.masksToBounds = false
        levelImageView.layer.shadowOffset = .zero
        levelImageView.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1).cgColor
        levelImageView.layer.shadowOpacity = 0.5
        levelImageView.layer.shadowRadius = 6

        twistsStack.axis = .vertical
        twistsStack.spacing = 16
        twistsStack.alignment = .center

        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        [modeLabel, levelImageView, levelLabel, twistsStack]
            .forEach { stack.addArrangedSubview($0) }
        stack.setCustomSpacing(18, after: levelLabel)
        detailsCard.addSubview(stack)
        // Tighter at the top than it was: the mode's name, its picture and the level's
        // line belong together as a heading, and only the twists below them need air

        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultCard.addSubview(resultLabel)

        column.axis = .vertical
        column.spacing = 12
        column.translatesAutoresizingMaskIntoConstraints = false
        column.addArrangedSubview(detailsCard)
        column.addArrangedSubview(resultCard)
        addSubview(column)

        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: topAnchor),
            column.leadingAnchor.constraint(equalTo: leadingAnchor),
            column.trailingAnchor.constraint(equalTo: trailingAnchor),
            column.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),

            stack.topAnchor.constraint(equalTo: detailsCard.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: detailsCard.bottomAnchor, constant: -18),

            resultLabel.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 14),
            resultLabel.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),
            resultLabel.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -14),

            levelImageView.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    /// Whether a twist name was tapped, and which one - the pause and briefing screens
    /// both explain a twist when it is touched (play-test round 15).
    var twistTapped: ((DailyTwist) -> Void)?

    /// Shows a day. Everything the card draws comes from these arguments, so the same card
    /// can be reused for any day the pager scrolls to.
    func show(key: String, isToday: Bool, record: DailyChallengeRecord?, rank: Int?) {
        let challenge = DailyChallengeGenerator.challenge(forKey: key)

        modeLabel.text = challenge.mode.name.uppercased()
        if let level = challenge.classicLevel {
            let number = DailyChallengeGenerator.levelNumber(forClassicLevel: level)
            let pack = DailyChallengeGenerator.pack(forClassicLevel: level)
            let setup = LevelPackSetup()
            levelImageView.image = setup.levelImageArray[number]
            levelLabel.text = "\(setup.levelNameArray[number]) - \(setup.levelPackNameArray[pack])"
                + "\nA single level - clear it for the score"
            // The level by its name, home and picture, not its number: a number says
            // nothing, and a glimpse of a level from a pack you have not opened is the
            // tasting menu
        } else {
            levelImageView.image = UIImage(named: "EndlessIcon.png")
            levelLabel.text = "How high can you get?"
        }

        showTwists(challenge)
        showResult(record, mode: challenge.mode, isToday: isToday, rank: rank)
    }

    private func showTwists(_ challenge: DailyChallenge) {
        twistsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let listed: [(NSAttributedString, String, DailyTwist?)] = challenge.twists.isEmpty
            ? [(DailyTwist.vanillaLine(font: .boldSystemFont(ofSize: 16), colour: .white),
                DailyTwist.vanillaBlurb, nil)]
            : challenge.twists.map {
                ($0.titleLine(font: .boldSystemFont(ofSize: 16), colour: .white),
                 $0.blurb, $0)
            }
        // A day with no twists is Vanilla, named and badged like any other - the baseline
        // day is a kind of day, not the absence of one

        for (title, blurbText, twist) in listed {
            let name = UILabel()
            name.attributedText = title
            name.textAlignment = .center

            let blurb = UILabel()
            blurb.text = blurbText
            blurb.font = .systemFont(ofSize: 14)
            blurb.textColor = UIColor(white: 1, alpha: 0.7)
            blurb.textAlignment = .center
            blurb.numberOfLines = 0

            let pair = UIStackView(arrangedSubviews: [name, blurb])
            pair.axis = .vertical
            pair.spacing = 3
            pair.alignment = .center
            _ = twist
            // Not tappable here (play-test round 16): the blurb is already printed
            // underneath. It is the *pause* screen, which shows only icons and names,
            // where a twist needs explaining
            twistsStack.addArrangedSubview(pair)
        }
    }

    @objc private func twistWasTapped(_ recogniser: DailyTwistTap) {
        twistTapped?(recogniser.twist)
    }

    /// The day's own result, with a badge saying whether it reached the live board.
    ///
    /// Three states, because there are three: posted, played but not posted (free play, or
    /// a scoring run that could not reach Game Center), and not played at all.
    private func showResult(_ record: DailyChallengeRecord?, mode: GameMode,
                            isToday: Bool, rank: Int?) {
        guard let record, record.attemptCount > 0 else {
            resultLabel.attributedText = nil
            resultCard.isHidden = true
            return
        }
        resultCard.isHidden = false

        let unit = mode == .classic ? "" : "m"
        let headline = record.posted
            ? "Posted: \(record.firstAttemptScore)\(unit)   "
            : "Your best: \(max(record.firstAttemptScore, record.bestPracticeScore))\(unit)   "
        // Once a score is on the board, the board's number is the day's number - a free
        // play best beside it made no sense. Before then the best of whatever was played
        // is the honest summary
        let line = NSMutableAttributedString(
            string: headline,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 16),
                         .foregroundColor: UIColor.white])

        let symbol: String
        let caption: String
        let tint: UIColor
        if record.posted {
            symbol = "checkmark.seal.fill"
            if isToday, let rank {
                caption = "  #\(rank) on the board"
            } else {
                caption = "  on the board"
            }
            // The placing is only asked for today: the daily board is recurring, so it
            // resets at the deadline and a past day's rank no longer exists
            tint = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        } else if record.isPending && isToday {
            symbol = "hourglass"
            caption = "  waiting to post"
            tint = UIColor(white: 1, alpha: 0.6)
            // Earned in the window, not yet landed (§12.5) - the retry loop is carrying
            // it, and this badge flips to the green check the moment it does
        } else {
            symbol = "clock.badge.xmark"
            caption = "  not posted"
            tint = UIColor(white: 1, alpha: 0.45)
        }

        let badge = NSTextAttachment()
        badge.image = UIImage(systemName: symbol)?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        badge.bounds = CGRect(x: 0, y: -2, width: 17, height: 15)
        line.append(NSAttributedString(attachment: badge))
        line.append(NSAttributedString(
            string: caption,
            attributes: [.font: UIFont.systemFont(ofSize: 13),
                         .foregroundColor: tint]))
        resultLabel.attributedText = line
    }
}

/// A tap recogniser that remembers which twist it belongs to, so one handler serves them
/// all without the view having to keep a parallel list of what it drew.
final class DailyTwistTap: UITapGestureRecognizer {
    let twist: DailyTwist

    init(twist: DailyTwist, target: Any?, action: Selector?) {
        self.twist = twist
        super.init(target: target, action: action)
    }
}

/// The cell the pager puts a card in. One card per cell, filling it.
final class DailyCardCell: UICollectionViewCell {
    static let reuseID = "dailyCard"
    let card = DailyCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 26),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -26),
        ])
        // Hugging the top rather than filling the page: pinned top *and* bottom, the card
        // stretched to whatever height the page had and spread its contents down the
        // screen (play-test round 16's screenshot)
        // The inset lives on the cell rather than on the collection view, so each page is
        // a full screen wide - which is what makes paging land on whole days - while the
        // card inside it keeps the margins the screen has always had
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
