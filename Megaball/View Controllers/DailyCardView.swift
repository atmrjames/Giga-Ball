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
import SpriteKit

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
    private let boardCard = UIView()
    private let boardTitle = UILabel()
    private let boardRows = UIStackView()
    private let lowerStack = UIStackView()

    private func build() {
        translatesAutoresizingMaskIntoConstraints = false

        for card in [detailsCard, resultCard, boardCard] {
            card.backgroundColor = UIColor(white: 1, alpha: 0.07)
            card.layer.cornerRadius = 18
            let glass = SettingsTableViewCell.addGlass(behind: card, cornerRadius: 18)
            if card === resultCard { resultGlass = glass }
            if card === boardCard { boardGlass = glass }
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
        twistsStack.spacing = 8
        twistsStack.alignment = .center
        twistsStack.isUserInteractionEnabled = true
        twistsStack.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(twistsBlockTapped)))
        // Sixteen points of gap separated a name from its own blurb; with the blurbs gone
        // (round 308) it separated two names from each other, which is a list with holes in it

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
        stack.setCustomSpacing(DailyCardView.twistsGap, after: levelLabel)
        detailsCard.addSubview(stack)
        // Tighter at the top than it was: the mode's name, its picture and the level's
        // line belong together as a heading, and only the twists below them need air

        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultCard.addSubview(resultLabel)

        boardTitle.text = "LEADERBOARD"
        boardTitle.font = .boldSystemFont(ofSize: 11)
        boardTitle.textColor = UIColor(white: 1, alpha: 0.5)
        boardTitle.textAlignment = .center
        boardRows.axis = .vertical
        boardRows.spacing = 4
        let boardStack = UIStackView(arrangedSubviews: [boardTitle, boardRows])
        boardStack.axis = .vertical
        boardStack.spacing = 6
        boardStack.translatesAutoresizingMaskIntoConstraints = false
        boardCard.addSubview(boardStack)
        boardCard.isHidden = true
        boardCard.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(resultWasTapped)))
        // The whole card opens Game Center's own board, as the posted score's does: this is a
        // few places of it, and the rest is one tap away

        lowerStack.axis = .vertical
        lowerStack.spacing = 12
        lowerStack.translatesAutoresizingMaskIntoConstraints = false
        [boardCard, resultCard].forEach { lowerStack.addArrangedSubview($0) }
        // **The day's board sits above the player's own line** (round 354), and the two stand
        // together at the bottom of the page. A stack, so a day with no board to show - any
        // day older than yesterday, or a signed-out player - closes up as if it were never there

        detailsCard.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailsCard)
        addSubview(lowerStack)

        let resultSitsAtTheBottom = lowerStack.bottomAnchor.constraint(equalTo: bottomAnchor)
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

            lowerStack.topAnchor.constraint(greaterThanOrEqualTo: detailsCard.bottomAnchor,
                                            constant: 12),
            lowerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            lowerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            resultSitsAtTheBottom,

            boardStack.topAnchor.constraint(equalTo: boardCard.topAnchor, constant: 10),
            boardStack.leadingAnchor.constraint(equalTo: boardCard.leadingAnchor, constant: 18),
            boardStack.trailingAnchor.constraint(equalTo: boardCard.trailingAnchor, constant: -18),
            boardStack.bottomAnchor.constraint(equalTo: boardCard.bottomAnchor, constant: -12),

            stack.topAnchor.constraint(equalTo: detailsCard.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: detailsCard.bottomAnchor,
                                          constant: -DailyCardView.twistsGap),

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

    /// The air above the twists, and the card's own inset below them.
    ///
    /// **One number, because they are the same gap** (James, round 313: "on endless mode or
    /// endless mayhem in the daily challenge menu view, centre the twists in the gap between
    /// the game mode heading and the bottom of the container. It looks a bit awkward").
    ///
    /// A classic day carries a pack-and-level line under its mode name and the twists sit this
    /// far below that. An endless day has no such line - "the mode name and the twists are the
    /// day" (round 306) - and the label was left in place holding an empty string: not hidden,
    /// so zero tall but still taking the stack's spacing on *both* sides. Measured before this,
    /// on an endless day: the mode name ended at 148 and the card at 218, with the twists at
    /// 178 to 200 - thirty points of air above them and eighteen below.
    static let twistsGap: CGFloat = 18

    /// Puts the twists the same distance below whatever is above them as the card's own edge is
    /// below the twists, whether or not there is a level line in between.
    private func spaceTheTwists(underALevelLine hasLevelLine: Bool) {
        levelLabel.isHidden = hasLevelLine == false
        stack.setCustomSpacing(hasLevelLine ? stack.spacing : DailyCardView.twistsGap,
                               after: modeLabel)
        // Hidden rather than merely empty, so the stack stops giving it any spacing at all -
        // and a hidden view is also the one thing that makes `setCustomSpacing(_:after:)` skip
        // its entry, which is why the gap after the *mode* name is the one being set here. The
        // classic day's is put back to the stack's ordinary spacing rather than left at
        // whatever the last day set, since one card is reused by the pager for every day.

    }

    /// Whether a twist name was tapped, and which one - the pause and briefing screens
    /// both explain a twist when it is touched (play-test round 15).
    var twistTapped: ((DailyTwist) -> Void)?
    /// Asked when the day's twists are tapped, so the screen can put up the explainer.
    var twistsExplainerTapped: (() -> Void)?

    /// Shows a day. Everything the card draws comes from these arguments, so the same card
    /// can be reused for any day the pager scrolls to.
    func show(key: String, isToday: Bool, record: DailyChallengeRecord?,
              standing: LeaderboardStanding?, boardBest: Int? = nil,
              board: [DailyBoardRow] = []) {
        let challenge = DailyChallengeGenerator.challenge(forKey: key)

        modeLabel.text = challenge.mode.name.uppercased()
        if let level = challenge.classicLevel {
            let number = DailyChallengeGenerator.levelNumber(forClassicLevel: level)
            let pack = DailyChallengeGenerator.pack(forClassicLevel: level)
            let setup = LevelPackSetup()
            let retroDay = DailyTwist.forcedTheme(for: challenge) == LevelPackSetup.retroThemeIndex
            let picture = retroDay
                ? DailyRetroLevelPreview.image(forLevel: number) ?? setup.levelImageArray[number]
                : setup.levelImageArray[number]
            levelImageView.image = DailyTwist.presented(picture, under: challenge.twists)
            // **A Retro day shows the level in Retro's bricks** (James, round 340: "show the
            // level preview with the theme applied ... same for retro"), built once per level
            // (`DailyRetroLevelPreview`). Every other theme only dresses the ball and paddle,
            // which the picture does not show, so theirs is already the right picture
            levelLabel.attributedText = DailyCardView.levelLine(
                level: setup.levelNameArray[number],
                pack: setup.levelPackNameArray[pack],
                icon: setup.packIcon(pack),
                font: levelLabel.font,
                colour: levelLabel.textColor ?? .white)
            spaceTheTwists(underALevelLine: true)
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
            spaceTheTwists(underALevelLine: false)
            // Nothing under an endless day's mode name either, by the same instruction: the
            // mode name and the twists are the day (round 306). This line used to read "How
            // high can you get?" on both endless modes, which said the same thing twice on
            // two days that play very differently"
            // Through the one door rather than naming an asset (round 130): a Mayhem day now
            // wears Mayhem's own icon, and it did so the moment that icon existed, without
            // this screen being told about it
        }

        showTwists(challenge)
        showBoard(board, unit: challenge.mode == .classic ? "" : "m")
        if board.isEmpty {
            showResult(record, mode: challenge.mode, isToday: isToday, standing: standing,
                       boardBest: boardBest)
        } else {
            resultCard.isHidden = true
        }
        // **The board or the posted score, never both** (James, round 357: "there's no need to
        // show the top scores section and the posted score section together. If the top score
        // section is available to show, hide the posted score section"). The board already
        // holds everything the posted-score card said - the player's own score and place, and
        // the leader's figure as its first row - so the second card was the same facts twice
    }

    /// The day's leading places, one row each (round 354).
    ///
    /// Rank, name and score in three columns so the scores line up down the right, and the
    /// player's own row in lime - which is also how a player placed below the rows shown finds
    /// themselves, added under them by `DailyBoardRow.shown`.
    private func showBoard(_ rows: [DailyBoardRow], unit: String) {
        boardRows.arrangedSubviews.forEach { $0.removeFromSuperview() }
        boardCard.isHidden = rows.isEmpty
        let lime = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        let leading = rows.first?.isLocalPlayer == true
        DailyCardView.dress(boardCard, glass: boardGlass, lime: leading)
        boardTitle.textColor = leading ? DailyCardView.onLime : UIColor(white: 1, alpha: 0.5)
        // **Lime when the player leads** (James, round 357: "If the current user is the top
        // scorer make the top score section background colour giga-ball yellow/green with the
        // text and icons dark purple") - the look the posted-score card wore for a leader in
        // round 350, moved to the card that now stands in for it
        for (position, row) in rows.enumerated() {
            let own = leading ? DailyCardView.onLime : lime
            let colour = row.isLocalPlayer ? own : (leading ? DailyCardView.onLime : UIColor.white)
            let rank = UILabel()
            rank.text = "\(row.rank)"
            rank.font = UIViewController.gameScoreFont(ofSize: 14)
            rank.textColor = row.isLocalPlayer || leading
                ? colour : UIColor(white: 1, alpha: 0.55)
            rank.widthAnchor.constraint(equalToConstant: 26).isActive = true
            let name = UILabel()
            name.text = row.name
            name.font = .systemFont(ofSize: 15, weight: row.isLocalPlayer ? .bold : .regular)
            name.textColor = colour
            name.lineBreakMode = .byTruncatingTail
            name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let score = UILabel()
            score.text = "\(row.score)" + unit
            score.font = UIViewController.gameScoreFont(ofSize: 15)
            score.textColor = colour
            score.textAlignment = .right
            score.setContentHuggingPriority(.required, for: .horizontal)
            score.setContentCompressionResistancePriority(.required, for: .horizontal)
            let line = UIStackView(arrangedSubviews: [rank, name, score])
            line.axis = .horizontal
            line.spacing = 8
            line.alignment = .firstBaseline
            line.isAccessibilityElement = true
            line.accessibilityLabel = "\(row.rank), \(row.name), \(score.text ?? "")"
            // One element a row, read the way it is laid out: place, player, score
            line.accessibilityTraits = .button
            line.accessibilityHint = "Opens the day's leaderboard"
            // The card under the row is the door to Game Center's board, so the row says so
            boardRows.addArrangedSubview(line)
            if position > 0, row.isLocalPlayer, row.rank > rows[position - 1].rank + 1,
               let above = boardRows.arrangedSubviews.dropLast().last {
                boardRows.setCustomSpacing(14, after: above)
            }
            // **Set apart when the player is below the leaders** (round 357: "show them at the
            // bottom of the leaderboard section with a little gap, showing their position and
            // score"). The gap is what says the places between are not shown
        }
    }

    private var boardGlass: UIVisualEffectView?

    /// A card's two looks: ordinary glass, and lime for the day's leader (rounds 350 and 357).
    static func dress(_ card: UIView, glass: UIVisualEffectView?, lime leading: Bool) {
        let lime = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        if #available(iOS 26.0, *), let glass {
            let effect = UIGlassEffect(style: .regular)
            effect.isInteractive = false
            effect.tintColor = leading ? lime.withAlphaComponent(0.85)
                                       : SettingsTableViewCell.glassTint
            glass.effect = effect
            card.backgroundColor = .clear
        } else {
            card.backgroundColor = leading ? lime : UIColor(white: 1, alpha: 0.07)
        }
    }

    /// The result container's glass, kept so it can wear lime for a day the player leads.
    private var resultGlass: UIVisualEffectView?

    /// The result container's two looks: the ordinary one, and lime for the day's leader.
    ///
    /// **James, round 350: "If it happens that the player is the hi scorer for the day, colour
    /// that container giga-ball yellow/green and keep the glassy Liquid Glass style to the
    /// container - make the text within the dark purple colour so it is still legible."** The
    /// glass is tinted rather than replaced, so it stays glass; without glass (before iOS 26)
    /// the card itself is filled.
    private func dressTheResultCard(leading: Bool) {
        DailyCardView.dress(resultCard, glass: resultGlass, lime: leading)
    }

    /// The dark purple the lime card's words are set in.
    static let onLime = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)

    private func showTwists(_ challenge: DailyChallenge) {
        twistsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let listed: [(NSAttributedString, String, DailyTwist?)] = challenge.twists.isEmpty
            ? [(DailyTwist.vanillaLine(font: .boldSystemFont(ofSize: 16), colour: .white),
                DailyTwist.vanillaBlurb, nil)]
            : challenge.twists.map {
                ($0.titleLine(font: .boldSystemFont(ofSize: 16), colour: .white,
                              dateKey: challenge.dateKey),
                 $0.blurb(forKey: challenge.dateKey), $0)
            }
        // A day with no twists is Vanilla, named and badged like any other - the baseline
        // day is a kind of day, not the absence of one

        for (title, blurbText, twist) in listed {
            let name = UILabel()
            name.attributedText = title
            name.textAlignment = .center
            twistsStack.addArrangedSubview(name)
            _ = (blurbText, twist)
        }
        // **Icon and name only, and the whole list answers a tap** (James, round 308: "twists
        // on the daily challenge screen shouldn't show the descriptions, just the icon and name
        // of the twist. like on the pause screen, if a user wants more details, they can click
        // to show a pop up with the description of the twists for the day's challenge").
        //
        // This is play-test round 16 turned around, and its reasoning is worth keeping because
        // it was right about the *pause* screen and is being overruled about this one: the
        // blurbs were printed here so a tap was not needed, and printing them made the card a
        // wall of text on a two-twist day. The pop-up is the same one the pause menu shows -
        // `DailyTwist.explainer` builds it for both - so a player who wants the detail asks for
        // it in the same way on either screen.
        //
        // `blurbText` is still gathered above rather than dropped from the list, because the
        // pop-up needs exactly it and the list is where the Vanilla case is handled.
    }

    @objc private func twistWasTapped(_ recogniser: DailyTwistTap) {
        twistTapped?(recogniser.twist)
    }

    /// The day's twists want explaining, and the whole block is the button.
    ///
    /// One tap target rather than one per twist: the pop-up lists every twist the day has, so
    /// tapping the second name to be told about the first as well would be a control that does
    /// not do what it looks like.
    @objc private func twistsBlockTapped() {
        twistsExplainerTapped?()
    }

    /// The day's own result, with a badge saying whether it reached the live board.
    ///
    /// Three states, because there are three: posted, played but not posted (free play, or
    /// a scoring run that could not reach Game Center), and not played at all.
    private func showResult(_ record: DailyChallengeRecord?, mode: GameMode,
                            isToday: Bool, standing: LeaderboardStanding?,
                            boardBest: Int? = nil, saysTheBest: Bool = true) {
        let unit = mode == .classic ? "" : "m"
        guard let record, record.posted else {
            dressTheResultCard(leading: false)
            guard saysTheBest, let boardBest, boardBest > 0 else {
                resultLabel.attributedText = nil
                resultCard.isHidden = true
                return
            }
            resultCard.isHidden = false
            resultLabel.attributedText = DailyCardView.hiScoreLine(boardBest, unit: unit,
                                                                  onLime: false)
            resultCard.isUserInteractionEnabled = true
            if resultCard.gestureRecognizers?.isEmpty ?? true {
                resultCard.addGestureRecognizer(
                    UITapGestureRecognizer(target: self, action: #selector(resultWasTapped)))
            }
            return
            // **The day's leader before you have played** (James, round 350): the number to
            // beat, where Game Center can say - today and yesterday - and nothing otherwise
        }
        let leading = record.leads(rank: isToday ? standing?.rank : nil, boardBest: boardBest)
        dressTheResultCard(leading: leading)
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
            .withTintColor(leading ? DailyCardView.onLime : tint, renderingMode: .alwaysOriginal)
        // **Purple on the lime card too** (James, round 351, with a screenshot: "the posted
        // score icon is the wrong colour"). An attachment is a picture with its colour baked
        // in, so the recolouring of the whole line further down never reached it: the badge
        // stayed lime on lime
        badge.bounds = CGRect(x: 0, y: -3, width: 18, height: 16)
        line.append(NSAttributedString(attachment: badge))
        line.append(NSAttributedString(
            string: "  \(title)  ",
            attributes: [.font: UIFont.systemFont(ofSize: 14),
                         .foregroundColor: tint]))

        line.append(NSAttributedString(
            string: "\(score)" + unit,
            // **Ungrouped, like the Global Hi-Score line under it** (James, round 354: "posted
            // score has no comma thousands separator, global hi score does", and round 356:
            // "scores in the daily challenge screen still aren't consistent"). The two agree by
            // following the game's rule - a score is never grouped (play-test round 126, see
            // `PauseMenuViewController`) - which the hi-score line had broken in round 350, and
            // which round 354 followed the wrong way
            attributes: [.font: UIViewController.gameScoreFont(ofSize: 16),
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
        if saysTheBest, let boardBest, boardBest > 0 {
            line.append(NSAttributedString(string: "\n"))
            line.append(DailyCardView.hiScoreLine(boardBest, unit: unit, onLime: leading))
        }
        // **And the day's leader under it** (round 350), so a posted score is read against the
        // number at the top of the board as well as its place on it
        if leading {
            line.addAttribute(.foregroundColor, value: DailyCardView.onLime,
                              range: NSRange(location: 0, length: line.length))
        }
        // Dark purple on lime throughout, the leaderboard badge included, so every word stays
        // legible on the lime card
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

    /// "Global Hi-Score: 3,400", with the leaderboard's own mark in front (round 350).
    static func hiScoreLine(_ best: Int, unit: String, onLime: Bool) -> NSAttributedString {
        let tint = onLime ? DailyCardView.onLime : UIColor(white: 1, alpha: 0.6)
        let line = NSMutableAttributedString()
        let badge = NSTextAttachment()
        badge.image = UIImage(systemName: "trophy.fill")?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        badge.bounds = CGRect(x: 0, y: -3, width: 17, height: 16)
        line.append(NSAttributedString(attachment: badge))
        line.append(NSAttributedString(string: "  Global Hi-Score:  ",
                                       attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                    .foregroundColor: tint]))
        line.append(NSAttributedString(
            string: "\(best)" + unit,
            attributes: [.font: UIViewController.gameScoreFont(ofSize: 16),
                         .foregroundColor: onLime ? DailyCardView.onLime : UIColor.white]))
        return line
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
                          font: UIFont, colour: UIColor = .white) -> NSAttributedString {
        let line = NSMutableAttributedString()

        if let icon {
            let badge = NSTextAttachment()
            badge.image = icon.withTintColor(colour, renderingMode: .alwaysOriginal)
            let side = font.lineHeight*0.95
            badge.bounds = CGRect(x: 0, y: font.descender*0.6, width: side, height: side)
            line.append(NSAttributedString(attachment: badge))
            line.append(NSAttributedString(string: " ", attributes: [.font: font]))
        }
        // **Tinted to the text it sits in** (James, round 310: "for the pack icon, can you
        // match its colour to the text colour"). A text attachment carries its own image and
        // ignores the run's `foregroundColor`, so the tint has to be baked into the picture -
        // `.alwaysOriginal` is what stops UIKit tinting it a second time on top.

        line.append(NSAttributedString(string: pack + " - " + level,
                                       attributes: [.font: font, .foregroundColor: colour]))
        // **Pack first, then the level** (James, round 310: "put the pack name before the level
        // name"). It read level-then-pack from round 306, which puts the specific before the
        // general - fine in a sentence, wrong in a list, where the pack is what a reader scans
        // for and the level is what they find once they are in the right place
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

    /// The page's own scroll, for a window too short to show the whole card.
    ///
    /// **James, round 351, from an iPad: "the daily challenge menu struggles when being resized.
    /// Elements shift around, disappear, move partially off the screen, get truncated ... allow
    /// page to scroll similar to the other game mode menu views if needed to fit content".** The
    /// card hung from the top of its page and could be no taller than it, so a short window had
    /// to squeeze it - and a stack squeezed drops whatever gives first, which on an iPhone SE was
    /// the level line and both twists. Now the card is always its full height and the page
    /// scrolls when that is more than it has. It scrolls vertically inside a pager that pages
    /// sideways, and the two never compete for a drag.
    let scroll = UIScrollView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = false
        scroll.contentInsetAdjustmentBehavior = .never
        contentView.addSubview(scroll)
        scroll.addSubview(card)
        let content = scroll.contentLayoutGuide
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: contentView.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            card.topAnchor.constraint(equalTo: content.topAnchor),
            card.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 26),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -26),
        ])
        // Hugging the top rather than filling the page: pinned top *and* bottom, the card
        // stretched to whatever height the page had and spread its contents down the
        // screen (play-test round 16's screenshot)
        // The inset lives on the cell rather than on the collection view, so each page is
        // a full screen wide - which is what makes paging land on whole days - while the
        // card inside it keeps the margins the screen has always had
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        scroll.contentOffset = .zero
        // A day scrolled to its foot does not hand that scroll to the next day shown
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// A Classic level's preview in Retro's bricks, for a Theme day that drew Retro.
///
/// James, round 340: "Daily twist monochromatic - show the level preview with the theme
/// applied. Same for retro." The monochrome half is a filter over the picture
/// (`DailyTwist.presented`). Retro cannot be: the level pictures are drawn assets in the
/// ordinary bricks, and Retro's are different art rather than a different colour. It is the
/// only theme with bricks of its own - every other theme dresses the ball and the paddle,
/// which the preview does not show - so it is the only one that needs this.
///
/// **The level is built, not re-drawn.** The levels are a hundred and ten functions placing
/// bricks with `if` statements, and building one is the only way to read it (`loadLevel`
/// says why, and `DailyLayoutFlipTests` does the same). A scene is made with Retro's bricks
/// swapped in exactly as `didMove` swaps them, the level is built into it, and its bricks are
/// copied - picture, colour, place - into a small scene of their own and rendered. Each level
/// is drawn once and kept.
enum DailyRetroLevelPreview {

    private static var drawn: [Int: UIImage] = [:]

    static func image(forLevel number: Int) -> UIImage? {
        if let kept = drawn[number] { return kept }
        guard let made = render(level: number) else { return nil }
        drawn[number] = made
        return made
    }

    private static func render(level number: Int) -> UIImage? {
        let session = DailyChallengeSession.shared
        let held = session.active
        session.active = nil
        defer { session.active = held }
        // Built as a level, not as a daily: with a daily active the build would turn the level
        // over itself, and the card turns the picture over again afterwards (`presented`)

        let screen = CGSize(width: 402, height: 874)
        let layout = GameSceneLayout(screen: screen)
        let scene = GameScene(size: screen)
        scene.gameMode = .classic
        scene.totalStatsArray = [TotalStats()]
        scene.numberOfBrickRows = GameSceneLayout.brickRows
        scene.numberOfBrickColumns = GameSceneLayout.brickColumns
        scene.brickWidth = layout.brickWidth
        scene.brickHeight = layout.brickHeight
        scene.gameWidth = layout.gameWidth
        scene.yBrickOffset = 0
        scene.brickNormalTexture = scene.retroBrickNormalTexture
        scene.brickInvisibleTexture = scene.retroBrickInvisibleTexture
        scene.brickMultiHit1Texture = scene.retroBrickMultiHit1Texture
        scene.brickMultiHit2Texture = scene.retroBrickMultiHit2Texture
        scene.brickMultiHit3Texture = scene.retroBrickMultiHit3Texture
        scene.brickMultiHit4Texture = scene.retroBrickMultiHit4Texture
        // The six `didMove` swaps for `brickSetting == 1`, and only those
        scene.levelNumber = number
        scene.loadLevel(number)

        let side = layout.gameWidth
        let brick = CGSize(width: layout.brickWidth, height: layout.brickHeight)
        let picture = SKNode()
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let placed = node as? SKSpriteNode, placed.isHidden == false,
                  let texture = placed.texture, texture != scene.brickNullTexture else { return }
            let copy = SKSpriteNode(texture: texture, size: brick)
            copy.color = placed.color
            copy.colorBlendFactor = placed.colorBlendFactor
            copy.position = CGPoint(x: placed.position.x + side/2,
                                    y: placed.position.y + side - brick.height/2)
            picture.addChild(copy)
        }
        // The grid is twenty-two rows of half-width bricks, so the whole field is square -
        // which is the shape every level picture is drawn in. Row 0's centre sits at
        // `yBrickOffset`, so its top is half a brick above it and at the square's top edge
        guard picture.children.isEmpty == false else { return nil }

        let margin = brick.height
        let frame = CGRect(x: -margin, y: -margin, width: side + margin*2, height: side + margin*2)
        let view = SKView(frame: CGRect(origin: .zero, size: frame.size))
        guard let texture = view.texture(from: picture, crop: frame) else { return nil }
        // A brick's height of margin all round, which is how the drawn level pictures are
        // framed - measured off Level05Image, whose first brick starts one row in from the edge
        return UIImage(cgImage: texture.cgImage())
    }
}

extension DailyResultReport {

    /// The board as the pop-up prints it: the leaders, a gap where the player's place is
    /// further down, the player's own row picked out, and the finish line under it all.
    func body() -> NSAttributedString {
        let ink = won ? DailyCardView.onLime : UIColor(white: 1, alpha: 0.8)
        let mine = won ? DailyCardView.onLime : SettingsTableViewCell.prominentTint
        let text = NSMutableAttributedString()
        for (position, row) in rows.enumerated() {
            if position > 0 {
                let gap = row.isLocalPlayer && row.rank > rows[position - 1].rank + 1
                text.append(NSAttributedString(string: gap ? "\n\n" : "\n"))
            }
            text.append(NSAttributedString(string: row.line(unit: unit), attributes: [
                .font: row.isLocalPlayer ? UIFont.boldSystemFont(ofSize: 16)
                                         : UIFont.systemFont(ofSize: 15),
                .foregroundColor: row.isLocalPlayer ? mine : ink]))
        }
        text.append(NSAttributedString(string: "\n\n" + finishLine, attributes: [
            .font: UIFont.boldSystemFont(ofSize: won ? 18 : 15),
            .foregroundColor: won ? DailyCardView.onLime : UIColor.white]))
        let centred = NSMutableParagraphStyle()
        centred.alignment = .center
        text.addAttribute(.paragraphStyle, value: centred,
                          range: NSRange(location: 0, length: text.length))
        return text
    }
}
