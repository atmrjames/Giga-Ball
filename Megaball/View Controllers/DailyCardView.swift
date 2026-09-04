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
    /// Opens the day's board. Set by the screen that owns the pager.
    var postedScoreTapped: (() -> Void)?
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

    private func build() {
        translatesAutoresizingMaskIntoConstraints = false

        for card in [detailsCard, resultCard] {
            card.backgroundColor = UIColor(white: 1, alpha: 0.07)
            card.layer.cornerRadius = 18
            SettingsTableViewCell.addGlass(behind: card, cornerRadius: 18)
            // These two were already translucent rather than light cards, so glass is a
            // change of material and not of scheme - the labels on them are white already
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
        [levelImageView, modeLabel, levelLabel, twistsStack]
            .forEach { stack.addArrangedSubview($0) }
        // **Icon above the mode's name** (James, round 214: "in the daily challenge container
        // which has the details for today's game, the game mode icon is below the game mode
        // title, which now mis-matches against the menu views"). The card was built before the
        // menus were turned round in rounds 210 and 211, and it is the same header in
        // miniature - so it reads the same way up
        stack.setCustomSpacing(18, after: levelLabel)
        detailsCard.addSubview(stack)
        // Tighter at the top than it was: the mode's name, its picture and the level's
        // line belong together as a heading, and only the twists below them need air

        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultCard.addSubview(resultLabel)

        detailsCard.translatesAutoresizingMaskIntoConstraints = false
        resultCard.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailsCard)
        addSubview(resultCard)

        let resultSitsAtTheBottom = resultCard.bottomAnchor.constraint(equalTo: bottomAnchor)
        resultSitsAtTheBottom.priority = .required - 1
        // **The day's rules hug the top and the day's score hugs the bottom** (play-test
        // round 126: "move the score container lower"). They used to be one stack, so the
        // score sat wherever the twists left it - halfway up a Vanilla day, further down a
        // three-twist one - and the reader's eye had to find it again on every swipe. Now
        // it lands just above the date, in the same place on every day.
        //
        // One priority below required so that a card too tall for its page - a long day on
        // a small phone - overflows rather than refusing to lay out, the gap above the
        // score being the constraint that holds

        NSLayoutConstraint.activate([
            detailsCard.topAnchor.constraint(equalTo: topAnchor),
            detailsCard.leadingAnchor.constraint(equalTo: leadingAnchor),
            detailsCard.trailingAnchor.constraint(equalTo: trailingAnchor),

            resultCard.topAnchor.constraint(greaterThanOrEqualTo: detailsCard.bottomAnchor,
                                            constant: 12),
            resultCard.leadingAnchor.constraint(equalTo: leadingAnchor),
            resultCard.trailingAnchor.constraint(equalTo: trailingAnchor),
            resultSitsAtTheBottom,

            stack.topAnchor.constraint(equalTo: detailsCard.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: detailsCard.bottomAnchor, constant: -18),

            resultLabel.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 14),
            resultLabel.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),
            resultLabel.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -14),

            levelImageView.heightAnchor.constraint(equalToConstant: 92),
            // Larger than the 72 it opened at (play-test round 85: "daily challenge level
            // previews slightly larger"). The picture is the day's identity on a card that
            // otherwise has room to spare, and a glimpse of a level from a pack the player
            // has not opened is the whole tasting-menu idea
        ])
    }

    /// Whether a twist name was tapped, and which one - the pause and briefing screens
    /// both explain a twist when it is touched (play-test round 15).
    var twistTapped: ((DailyTwist) -> Void)?

    /// Shows a day. Everything the card draws comes from these arguments, so the same card
    /// can be reused for any day the pager scrolls to.
    func show(key: String, isToday: Bool, record: DailyChallengeRecord?,
              standing: LeaderboardStanding?) {
        let challenge = DailyChallengeGenerator.challenge(forKey: key)

        modeLabel.text = challenge.mode.name.uppercased()
        if let level = challenge.classicLevel {
            let number = DailyChallengeGenerator.levelNumber(forClassicLevel: level)
            let pack = DailyChallengeGenerator.pack(forClassicLevel: level)
            let setup = LevelPackSetup()
            levelImageView.image = DailyTwist.presented(setup.levelImageArray[number],
                                                        under: challenge.twists)
            levelLabel.attributedText = DailyCardView.levelLine(
                level: setup.levelNameArray[number],
                pack: setup.levelPackNameArray[pack],
                icon: setup.packIcon(pack),
                font: levelLabel.font)
            // The level by its name, home and picture, not its number: a number says
            // nothing, and a glimpse of a level from a pack you have not opened is the
            // tasting menu.
            //
            // **The objective line is gone** (James, round 306: "remove the description under
            // the game modes. It's unnecessary. Just show the name of the game mode, the level
            // and pack if it's classic mode, and then the twists"). Round 90 added it to stop
            // the day reading as pass-or-fail, and the twists below it now carry the day's
            // character well enough that a sentence saying "high score on a single level" is
            // repeating what the mode name already says.
            //
            // **And the pack wears its own badge** ("is it possible to place the pack's icon
            // graphic near the pack name?"), from `packIcon` - the same picture the pack grid
            // and the mode menu draw, asked for rather than named, so a pack whose art changes
            // changes here too
        } else {
            levelImageView.image = GameMode.menuIcon(for: challenge.mode)
            levelLabel.attributedText = nil
            levelLabel.text = nil
            // Nothing under an endless day's mode name either, by the same instruction: the
            // mode name and the twists are the day (round 306). This line used to read "How
            // high can you get?" on both endless modes, which said the same thing twice on
            // two days that play very differently"
            // Through the one door rather than naming an asset (round 130): a Mayhem day now
            // wears Mayhem's own icon, and it did so the moment that icon existed, without
            // this screen being told about it
        }

        showTwists(challenge)
        showResult(record, mode: challenge.mode, isToday: isToday, standing: standing)
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
                            isToday: Bool, standing: LeaderboardStanding?) {
        guard let record, record.posted else {
            resultLabel.attributedText = nil
            resultCard.isHidden = true
            return
        }
        // **Posted, or nothing** (James, round 306: "for a Daily Challenge where a score is set
        // but not posted, just treat it as if no score was set").
        //
        // The card used to show any day that had been *attempted*, with a "Not posted" badge
        // and the best figure of whatever was played. That is honest and it is not what the
        // screen is for: this row is the leaderboard's own row, and a score that never reached
        // a board has nothing to say on it. The "waiting to post" case goes with it - a
        // pending post flips to `posted` the moment it lands, and until then there is nothing
        // to show
        resultCard.isHidden = false

        let unit = mode == .classic ? "" : "m"
        let score = record.posted
            ? record.firstAttemptScore
            : max(record.firstAttemptScore, record.bestPracticeScore)
        // Once a score is on the board, the board's number is the day's number - a free
        // play best beside it made no sense. Before then the best of whatever was played
        // is the honest summary

        // A posted score leads with the leaderboard's own mark and says what it is
        // (play-test round 21). The tick and "on the board" were two ways of saying the
        // same thing, and neither said the row could be pressed
        let symbol: String
        let title: String
        let tint: UIColor
        if record.posted {
            symbol = "list.number"
            title = "Posted Score:"
            tint = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        } else if record.isPending && isToday {
            symbol = "hourglass"
            title = "Waiting to post"
            tint = UIColor(white: 1, alpha: 0.6)
            // Earned in the window, not yet landed (§12.5) - the retry loop is carrying it,
            // and this flips to the posted look the moment it does
        } else {
            symbol = "clock.badge.xmark"
            title = "Not posted"
            tint = UIColor(white: 1, alpha: 0.45)
        }

        let line = NSMutableAttributedString()
        let badge = NSTextAttachment()
        badge.image = UIImage(systemName: symbol)?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        badge.bounds = CGRect(x: 0, y: -3, width: 18, height: 16)
        line.append(NSAttributedString(attachment: badge))
        line.append(NSAttributedString(
            string: "  \(title)  ",
            attributes: [.font: UIFont.systemFont(ofSize: 14),
                         .foregroundColor: tint]))

        line.append(NSAttributedString(
            string: String(score) + unit,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 16),
                         .foregroundColor: UIColor.white]))

        if record.posted, isToday, let standing {
            line.append(NSAttributedString(
                string: ", Rank: ",
                attributes: [.font: UIFont.systemFont(ofSize: 14),
                             .foregroundColor: tint]))
            line.append(NSAttributedString(
                string: standing.text,
                attributes: [.font: UIFont.boldSystemFont(ofSize: 16),
                             .foregroundColor: UIColor.white]))
            // **The score first, then the rank** (James, round 306): "put the player's posted
            // score between 'posted score' and the rank so it reads: Posted score: 115m,
            // Rank: 1/100". The placing used to lead, from round 126, and reading it before
            // the number it describes is what made the line hard to take in at a glance.
            //
            // Today only, and that is not a limitation to fix: the daily board is a
            // *recurring* leaderboard, so it resets at each deadline and a past day's placing
            // no longer exists to ask for (James, round 306, asking exactly this)
        }

        // **No free-play detail here** (James, round 306: "there's no need to show the details
        // of the free play game scores"). It was §8's posted-score container doing what §8
        // asked - a quieter second line counting the runs played after the attempt was spent -
        // and the card is better without it: the day's number is the one that counts, and a
        // second score beside it invited exactly the comparison it then had to explain away.
        // `freePlayLine` stays, tested, because the stats screens still have a use for it
        // **Free play goes in the same container** (§8's posted-score container, the last
        // clause of it: "free play attempts played after the post get listed in the same
        // container"). A second line under the day's own number, quieter than it, because a
        // free-play score is not on any board and must never read as though it might be
        resultLabel.numberOfLines = 0
        resultLabel.attributedText = line

        // The whole container opens the board, not a button on it - the score and the
        // placing are the leaderboard's own figures, so the row that shows them is the door
        resultCard.isUserInteractionEnabled = record.posted
        if record.posted, resultCard.gestureRecognizers?.isEmpty ?? true {
            resultCard.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(resultWasTapped)))
        }
    }

    /// "Tunnel - Space Pack", with the pack's own badge in front of its name.
    ///
    /// An attachment rather than a second label, because the two are one sentence and a label
    /// beside a label wraps independently of it - the pack name would have gone to its own
    /// line on a narrow window while the level name sat alone on the first.
    ///
    /// The badge is sized from the font's own line height, so it grows and shrinks with the
    /// text rather than being a fixed number of points that is right on one device.
    static func levelLine(level: String, pack: String, icon: UIImage?,
                          font: UIFont) -> NSAttributedString {
        let line = NSMutableAttributedString(
            string: level + " - ", attributes: [.font: font, .foregroundColor: UIColor.white])

        if let icon {
            let badge = NSTextAttachment()
            badge.image = icon
            let side = font.lineHeight*0.95
            badge.bounds = CGRect(x: 0, y: font.descender*0.6, width: side, height: side)
            line.append(NSAttributedString(attachment: badge))
            line.append(NSAttributedString(string: " ", attributes: [.font: font]))
        }

        line.append(NSAttributedString(string: pack,
                                       attributes: [.font: font,
                                                    .foregroundColor: UIColor.white]))
        return line
    }

    /// What free play after the day's attempt adds up to, or nil when there was none.
    ///
    /// **Only what was played *after* the attempt was spent**, which is what "free play" means
    /// here: the first attempt is the counting one and every attempt beyond it is free play, so
    /// the count is one fewer than the attempts recorded. A day played once has no free play to
    /// report, and saying "1 attempt" under its own score would be counting the same run twice.
    ///
    /// The best of them is worth showing beside the count because it is the thing a player who
    /// kept going wants to see - and it is shown even when it beats the posted score, since
    /// hiding it would be the summary quietly editing what happened. It says free play, which
    /// is the word the player reads everywhere else (round 12's rename from "practice").
    ///
    /// **Only drawn on a day that posted**, which is §8's own wording - "free play attempts
    /// played *after the post*". On a day that did not post, the headline number is already
    /// `max(firstAttemptScore, bestPracticeScore)`, so a free-play line under it would print
    /// the same figure twice. Drawn and looked at, round 269: the strings were right and the
    /// card said 8100m over 8100m.
    static func freePlayLine(_ record: DailyChallengeRecord, unit: String) -> String? {
        let extras = max(0, record.attemptCount - 1)
        guard extras > 0 else { return nil }

        let attempts = extras == 1 ? "1 free play" : "\(extras) free plays"
        guard record.bestPracticeScore > 0 else { return attempts }
        return attempts + ", best " + String(record.bestPracticeScore) + unit
    }

    /// What the result container is saying, for a test that would otherwise have to read a
    /// label through the view hierarchy.
    var resultTextForTesting: String {
        resultCard.isHidden ? "" : (resultLabel.attributedText?.string ?? "")
    }

    @objc private func resultWasTapped() {
        postedScoreTapped?()
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
