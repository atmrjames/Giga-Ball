//
//  MenuLayout.swift
//  Megaball
//
//  Keeps the menu screens to a readable column on large screens.
//
//  The menus were built at a fixed 414x736 and centred, which is why they survived iPad
//  at all. Once that fixed size was removed so they could use the whole of an iPhone,
//  they filled an iPad too - full-width rows on an 11-inch screen, which is a lot of
//  nothing between an icon and its label.
//
//  Rather than constrain each screen's contents, this insets the safe area the contents
//  are already pinned to. Every menu lays its title, table and close button out against
//  the container's safe area guide, so insetting it moves all of them at once - and the
//  container itself, which carries the blurred backdrop, still fills the screen.
//

import UIKit

/// The heading that sits over a reference page's grid - BEHAVIOURS, CLASSIC GAME MODES.
///
/// One recipe, because there are two of these pages and they had drifted: the bricks page's
/// headings were 15pt black at a 24pt inset in a 34pt band, and the power-ups page's were 13pt
/// bold, indented with two spaces in the string itself, in a 30pt band (play-test round 145:
/// "the text on the power-ups and bricks info screen sticky headers is different - make them
/// the same"). Two screens showing the same kind of heading in two sizes reads as one of them
/// being wrong, which it was.
enum ReferenceHeading {

    /// How tall the band is, which is also how much of the top the scroll fade must leave
    /// alone - see `stickyHeaderBand`.
    static let height: CGFloat = 34

    /// How far in from the band's own edge the title starts.
    static let titlePadding: CGFloat = 12

    /// Fills a dequeued supplementary view in: a dark blur, and the title over it.
    ///
    /// The blur is what lets the heading pin: squares travelling under it disappear behind it
    /// rather than showing through the bare label.
    ///
    /// - Parameter inset: how far in from each side the band starts, which is the grid's own
    ///   inset. **The band runs as wide as the squares and no wider** (James, round 326, on an
    ///   iPad: the Power-Ups sticky header "is slightly wider than the tiles below it"). A
    ///   header is as wide as its collection view and the squares sit `gridInset` in from each
    ///   side - the flow layout spreads a full row to exactly that width - so the band stuck
    ///   twenty points out past the tiles at both ends, on every device; an iPad's larger,
    ///   emptier screen is simply where it showed. The title keeps `titlePadding` inside the band.
    static func fill(_ header: UICollectionReusableView, title: String, inset: CGFloat = 0) {
        header.subviews.forEach { $0.removeFromSuperview() }
        // Reused like a cell, so last time's label has to go or they stack up

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = header.bounds.insetBy(dx: inset, dy: 0)
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.addSubview(blur)

        let label = UILabel()
        label.text = title.uppercased()
        label.font = .systemFont(ofSize: 15, weight: .black)
        label.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor,
                                           constant: inset + ReferenceHeading.titlePadding),
            label.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor,
                                            constant: -(inset + ReferenceHeading.titlePadding)),
            label.centerYAnchor.constraint(equalTo: header.centerYAnchor),
        ])
        // Measured from the band rather than from the header (round 326). The title sat 24 in
        // from a band that reached the screen's edge; with the band pulled in to the tiles, the
        // same 24 left four points between the band's edge and the first letter, which looked
        // like the words had been pushed up against a wall
    }
}

extension UIViewController {

    /// The squarest a menu is allowed to be: width divided by height.
    ///
    /// **The shape is what is capped, not the size** (James, round 182: "for the iPad, it's
    /// not the overall size that should be capped, it's the ratio of width to height. It's ok
    /// to make the app slightly more square than the phone is, but not much more square").
    ///
    /// Phones run from 0.46 (iPhone 17 Pro) to 0.56 (the SE); a 13-inch iPad in portrait is
    /// 0.75, which is a different-shaped app rather than the same one bigger. This sits just
    /// past the squarest phone - recognisably the same layout, with the extra width an iPad
    /// has to spare, and none of the height given away.
    ///
    /// Round 180's `menuMaximumSize` of 500x820 capped both directions, which centred a
    /// phone-sized box in the middle of a 13-inch screen and left 40% of the height empty
    /// while the pack grid scrolled with two packs hidden. Its *ratio* was 0.61, so the shape
    /// was never the problem - only the absolute cap on height was.
    static let menuMaximumAspectRatio: CGFloat = 0.62

    /// And how wide a menu's contents may ever run, in points, whatever shape the window is.
    ///
    /// **The ratio alone is not enough on a large iPad** (James, round 314: "can we limit how
    /// tall and wide the UI elements become. It should really just look like the phone app
    /// with everything centred on the larger background"). A 13-inch iPad in portrait is 1032
    /// by 1376, and 0.62 of that height is 853 points - narrower than the window and still
    /// twice a phone. The run list on the endless screens ran the full width of it, with the
    /// sort control at the far left edge and the run count at the far right.
    ///
    /// Round 180 capped 500 by 820 and round 181 took it out again, and its note is the reason
    /// this is safe: "its *ratio* was 0.61, so the shape was never the problem - only the
    /// absolute cap on height was". The height cap is what left 40% of a 13-inch screen empty
    /// with two packs scrolled out of sight. **Nothing is ever taken off the height here**, so
    /// that cannot come back.
    ///
    /// 460 because the widest phone the app supports is about 440 across, so no phone is ever
    /// clamped by this - on every one of them the inset is zero and the layout is exactly what
    /// it was - and an iPad gets a column the width of a large phone rather than a stretched
    /// copy of one.
    static let menuMaximumWidth: CGFloat = 460

    /// The tallest a menu's content is allowed to be, in points, whatever the window's height.
    ///
    /// James, round 320: "it also needs a height limit. to match similar to the largest iPhone,
    /// or maybe slightly larger". The largest phone is 956 tall; a thousand is slightly larger,
    /// and keeps the capped box the same shape as that phone (460 by 1000 is 0.46, a Pro Max is
    /// 0.46), so an iPad's menu is a Pro Max's menu with a little air around it.
    static let menuMaximumHeight: CGFloat = 1000

    /// How large a mode's own logo is at the head of its menu.
    ///
    /// The three mode menus are a set and their logos should be the same size (play-test
    /// round 126: the classic pack screen's "should match the size on the endless mode menu
    /// views"). The endless screens set it at 190 when a run list is under it, and this is
    /// that number, in one place, so the set stays a set.
    /// The face every menu screen's title wears.
    ///
    /// The storyboard sets it on each scene's own label; these are the numbers, for the
    /// screens built in code. Round 212 found `PaddleSpeedViewController` wearing Helvetica
    /// Neue Bold at 40 instead, and the music screen had copied it - which is how a face
    /// nobody chose ends up on two screens.
    static var menuTitleFont: UIFont { .systemFont(ofSize: 35, weight: .black) }

    /// The face the game's own numbers are set in: the HUD's score, its height, its multiplier.
    ///
    /// Fugaz One, the one custom face the app registers. James, round 312: "on the game over /
    /// completion screen for the scores, use the same font as the game." The number on that
    /// screen is the number the HUD was showing a moment earlier, so it should look like it.
    ///
    /// Falls back to the black system face, because a screen with no score on it would be worse
    /// than one in the wrong face.
    static func gameScoreFont(ofSize size: CGFloat) -> UIFont {
        UIFont(name: "FugazOne-Regular", size: size) ?? .systemFont(ofSize: size, weight: .black)
    }

    /// The near-white the About screen's credits are written in.
    static let menuCreditColour = UIColor(white: 0.8706, alpha: 1)

    /// The air between a menu's icon and the name under it.
    ///
    /// Ten rather than four (James, round 211: "maybe a tiny bit more space between the big
    /// icon and game mode header"). The icons carry a glow that reaches a little past their
    /// own edge, so four points of layout read as almost none.
    static let menuHeaderIconGap: CGFloat = 10

    static let menuModeLogoSize: CGFloat = 190

    /// What that logo shrinks to on a screen with no room for it.
    ///
    /// **James, round 339: "reduce the size of the game mode logo as needed to allow content
    /// to fit better when the window is small - do this across other views as needed."** On a
    /// 320 by 568 phone the daily's badge took the top third of the screen and the card under
    /// it was clipped to its own icon: no mode name, no twists, and the buttons cut off at the
    /// bottom. The badge is the least important thing on that screen and it was taking the
    /// most room.
    ///
    /// Measured against the height a 402 by 874 phone has, and never grown: an iPad has plenty
    /// of room and a 190-point badge is already the size it was drawn for.
    static func menuModeLogoSize(forHeight height: CGFloat) -> CGFloat {
        guard height > 0, height < menuModeLogoFullHeight else { return menuModeLogoSize }
        let share = max(0.55, (height/menuModeLogoFullHeight*100).rounded()/100)
        return (menuModeLogoSize*share).rounded()
    }

    /// The screen height the 190-point badge was drawn for.
    static let menuModeLogoFullHeight: CGFloat = 874

    /// The mode's icon on the two screens the *game* shows: the level intro and the pause
    /// and game-over screen.
    ///
    /// James, round 233: "make the game mode logos bigger on the level splash screen
    /// animations and pause screens." They were 56 and 42, set separately, and the smaller of
    /// the two sat under a wordmark and a heading and read as a bullet point rather than as
    /// the thing naming what you are playing. One number for both now, because they are the
    /// same badge doing the same job on two screens a player sees seconds apart - and a menu
    /// wears the same artwork at 190, so there is a long way to grow before it is large.
    static let inGameModeIconSize: CGFloat = 84

    /// The three numbers the pause screen and the level intro have to agree on.
    ///
    /// **James, round 312: "add giga-ball logo on the level intro splash screen to the same
    /// position as where it is on the pause view. Align the game mode logo and header between
    /// the level intro splash screen and the pause menu too so these views match up better."**
    ///
    /// They are the two screens a player sees seconds apart - the intro on the way into a level
    /// and the pause menu on the way out of it - and until now the intro had no wordmark at all
    /// and set its icon six points above the name where the pause menu set it four. Written
    /// down once so the two cannot drift again, which is the whole reason `inGameModeIconSize`
    /// is here: round 233 found the same badge at 56 on one screen and 42 on the other.
    static let inGameLogoTopInset: CGFloat = 46
    static let inGameLogoHeight: CGFloat = 36
    static let inGameModeIconGap: CGFloat = 4

    /// The air between the wordmark and the mode's badge, on every screen the game shows.
    ///
    /// **James, round 339, against all five: "make the gap between the giga-ball logo and game
    /// mode / level info larger", and on two of them "the giga-ball logo and game mode / level
    /// info should sit more towards the centre of the screen".** Sixteen put the badge directly
    /// under the wordmark with no daylight, so the two read as one lump of furniture rather
    /// than as the game's name and then what you are playing. Thirty-four is enough air to
    /// separate them, and because everything below hangs off the badge it takes the run's name
    /// down the screen with it - which is the second half of the note.
    ///
    /// One number for all five screens. The wordmark stays where it is on each of them, so the
    /// mark itself does not move between the resume card, the intro, the between-levels card,
    /// the pause screen and the game-over card.
    static let inGameLogoToIconGap: CGFloat = 42
    // **Forty-two since round 340**, eight more than round 339's, for the level intro's swell:
    // the card scales about its own centre while the wordmark holds still, so the badge is
    // thrown upwards as it comes in. See `InbetweenViewController.introZoom`

    /// How far the bottom row of buttons sits above the bottom of an in-game screen.
    ///
    /// The pause and game-over screens put their button row here, and round 332's layout notes
    /// asked the between-levels screen's "tap to continue" to land in the same place: "move the
    /// tap to continue down, near where the play button would be on other views".
    static let inGameBottomRowInset: CGFloat = 92

    /// Keeps the mode icon above whichever of the two title lines is actually showing.
    ///
    /// **James, round 332: "move endless mode label closer to icon", and the same note again
    /// for Endless Mayhem.** The icon is anchored above the *pack* line, because in Classic and
    /// the daily there is a label above the one naming the mode and anchoring to the lower of
    /// the two put the icon straight through it (play-test round 14). An endless run leaves the
    /// pack line empty - and an empty label still holds its height, so the mode's name sat a
    /// whole line below an icon that was supposed to be sitting on top of it.
    ///
    /// Asked every layout pass rather than decided once: the labels are written after the icon
    /// is built on both screens, and a daily changes which of them carries the mode's name.
    /// Where the mode's badge sits, measured down from the top of every in-game screen.
    ///
    /// The wordmark's own inset, plus its height, plus the air under it. Written as a sum of
    /// the three numbers it is made of rather than as a fourth number, so moving the wordmark
    /// moves the badge with it.
    static var inGameHeaderIconDrop: CGFloat {
        inGameLogoTopInset + inGameLogoHeight + inGameLogoToIconGap
    }

    /// How far in from each edge the wordmark may reach on an in-game screen.
    ///
    /// **Round 338, from the gallery.** Sixty, until now - and the Home button sits in the
    /// pause screen's top-left corner at an inset of 25 and a diameter of 50, so it ends at 75
    /// and the wordmark was allowed to start at 60. On a 402-point phone the wordmark is not
    /// wide enough to reach its own limit and nothing happened; on a 320-point one it is, and
    /// the G of GIGA-BALL was drawn behind the Home button.
    ///
    /// Eighty-six clears the button with air to spare, and the wordmark is scale-to-fit inside
    /// its box, so on the screens where this now bites it draws a little smaller rather than
    /// being cropped. One number for every in-game screen, including the two with no Home
    /// button on them, because the wordmark is meant to be in the same place on all of them.
    static let inGameLogoSideInset: CGFloat = 86

    /// The constraints that make up an in-game screen's header band.
    ///
    /// Held by the screen rather than rebuilt, because the band is re-measured on every layout
    /// pass - a rotation, a Slide Over resize, an iPad window dragged narrower - and creating
    /// constraints in a layout pass that then asks for another one is how a screen ends up
    /// walking down itself a pass at a time (round 337 did exactly that).
    struct InGameHeader {
        var logoTop: NSLayoutConstraint?
        var logoHeight: NSLayoutConstraint?
        var iconTop: NSLayoutConstraint?
        var iconWidth: NSLayoutConstraint?
        var iconHeight: NSLayoutConstraint?
        var titleTop: NSLayoutConstraint?
        weak var pinnedTo: UILabel?
    }

    /// The shape the in-game header is drawn at full size for: a 402 by 874 phone.
    ///
    /// Everything in the band - the wordmark's inset and height, the badge, the air under it,
    /// the type below - is a number that was chosen against this screen, so this is the size at
    /// which the scale below is exactly one.
    static let inGameHeaderReference = CGSize(width: 402, height: 874)

    /// How much the in-game header grows or shrinks to suit the screen it is on.
    ///
    /// **Round 338.** The band is 188 points before the first word of content: the wordmark's
    /// inset, the wordmark, the air under it, the badge, and the air under that. On the phone
    /// it was designed for that is a fifth of the screen and looks like a title. On a 320 by
    /// 568 one it is a third, and the between-levels card ran its total score straight through
    /// the tap line - the first gallery render has "Total Score" printed over "2 lives left".
    /// On a 1032 by 1376 iPad it is a tenth, and the whole screen read as a phone app someone
    /// had stretched.
    ///
    /// **The smaller of the two ratios**, because a screen can be generous in one direction and
    /// mean in the other: a Slide Over pane is a phone's width at an iPad's height, and sizing
    /// it by height alone gave it an iPad's badge over a wordmark that had to stay narrow
    /// enough to clear the pane's edges.
    ///
    /// Clamped at both ends. The floor stops a very small window shrinking the badge into a
    /// bullet point; the ceiling stops an iPad, nearly twice the reference height, printing a
    /// poster.
    /// The scale for the box a screen actually lays its header out in.
    ///
    /// The *safe area's* frame rather than the view's bounds, because on an iPad every in-game
    /// screen holds its content to a 460-point column and does it by inset (round 181's
    /// `limitMenuContentSize`). Measured against the bounds instead, the level intro scaled
    /// itself for a 1032-point screen and the pause screen for the 460-point column inside it -
    /// so the same badge came out at 118 points on one and 96 on the next, 160 points apart
    /// vertically, on two screens a player sees within a second of each other.
    static func inGameHeaderScale(inside view: UIView) -> CGFloat {
        let box = view.safeAreaLayoutGuide.layoutFrame
        return inGameHeaderScale(for: box.isEmpty ? view.bounds.size : box.size)
    }

    static func inGameHeaderScale(for size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return 1 }
        let ratio = min(size.height/inGameHeaderReference.height,
                        size.width/inGameHeaderReference.width)
        return min(1.4, max(0.72, (ratio*100).rounded()/100))
    }

    /// The air between the block naming the run and the block reporting it.
    ///
    /// The storyboards had fifteen on both screens, which was a line's gap inside one column
    /// of text. Now that the two are separate bands - the name hanging from the wordmark, the
    /// result below it - it is a gap between blocks, and fifteen reads as a crowding: both
    /// sides of it carry a halo, so the light from PAUSED runs into the level's name before
    /// there is any space between them.
    static let inGameHeaderToResultGap: CGFloat = 30

    /// Hangs the mode's badge and the run's name from the wordmark, at the top of the screen.
    ///
    /// **James, round 338: "many of the screens have the game mode logo and title too low -
    /// they should sit just below the Giga-Ball logo near the top of the views."**
    ///
    /// This used to run the other way round, and that was the whole fault. The badge was
    /// pinned *above* whichever title line was showing, and where that line sat was each
    /// storyboard's own business: a tie to the content's vertical centre on the level intro
    /// and the between-levels card, a tie to the content box's centre on the pause and
    /// game-over screens. So the badge landed wherever the text happened to fall, which on a
    /// tall phone was a third of the way down the screen, and on a 320 by 568 one was
    /// **straight through the middle of the wordmark** - round 338's first gallery render of
    /// the game-over card reads "GIG(badge)ALL".
    ///
    /// Anchored to the top, the badge is the same distance under the wordmark on every screen
    /// and every device, and the lines naming the run hang under it. What each screen does
    /// below that is its own business, which is where they should differ.
    ///
    /// The title line is still chosen rather than fixed: in Classic and the daily there is a
    /// pack line above the line naming the mode, and an endless run leaves it empty - and an
    /// empty label still holds a line's height, which is the gap round 332 asked to close.
    ///
    /// Everything in the band is sized from `inGameHeaderScale`, so a short screen wears a
    /// smaller version of the same header rather than a header that does not fit.
    func layOutTheInGameHeader(_ header: inout InGameHeader, logo: UIView?, icon: UIView,
                               above pack: UILabel, or level: UILabel, in container: UIView) {
        let scale = UIViewController.inGameHeaderScale(inside: container)
        let target: UILabel = (pack.text?.isEmpty == false) ? pack : level

        if header.iconTop == nil {
            let top = icon.topAnchor.constraint(
                equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 0)
            let width = icon.widthAnchor.constraint(equalToConstant: 0)
            let height = icon.heightAnchor.constraint(equalToConstant: 0)
            NSLayoutConstraint.activate([top, width, height])
            header.iconTop = top
            header.iconWidth = width
            header.iconHeight = height
        }
        if header.titleTop == nil || header.pinnedTo !== target {
            header.titleTop?.isActive = false
            let under = target.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 0)
            under.isActive = true
            // The title line's *top* against the badge's bottom, rather than the badge's
            // bottom against the title's top. Same distance, opposite owner: the badge is
            // placed and the text follows it, which is what "just below the Giga-Ball logo"
            // means.
            header.titleTop = under
            header.pinnedTo = target
        }

        header.logoTop?.constant = (UIViewController.inGameLogoTopInset*scale).rounded()
        header.logoHeight?.constant = (UIViewController.inGameLogoHeight*scale).rounded()
        header.iconTop?.constant = (UIViewController.inGameHeaderIconDrop*scale).rounded()
        let badge = (UIViewController.inGameModeIconSize*scale).rounded()
        header.iconWidth?.constant = badge
        header.iconHeight?.constant = badge
        header.titleTop?.constant = (UIViewController.inGameModeIconGap*scale).rounded()

        // **Without an animation of its own** (James, round 339: "during the intro the game
        // mode icon seems to have a little animation on its own before the main animation
        // starts - remove that initial game mode icon only animation and have it do the same
        // animation as the other elements"). The band is measured in `viewDidLayoutSubviews`,
        // and on the level intro that pass happens *inside* the entrance animation - so the
        // badge, having just been given its size and its place, travels from wherever it was
        // to wherever it belongs while everything else is fading in. It is furniture, not an
        // event: it arrives with the screen it is on, and nothing of its own happens first.
        //
        // The animations are taken off the badge rather than the layout being moved out of the
        // pass: a `layoutIfNeeded` from inside `viewDidLayoutSubviews` is a layout pass inside
        // a layout pass, and round 339 crashed the whole test bundle finding that out.
        icon.layer.removeAllAnimations()
        logo?.layer.removeAllAnimations()
    }

    /// What that logo shrinks to when a list scrolls up under it.
    ///
    /// The pack grid is what the screen is for, and at rest the logo takes a third of it.
    /// Trading its size for the grid's room as the packs travel is the same bargain the
    /// large title in a navigation bar makes.
    static let menuModeLogoScrolledSize: CGFloat = 84

    /// How much air a menu's list gets above its first row and below its last.
    ///
    /// The screens were built with the table pinned close to the title above it and the
    /// button row below, and the play test read the whole app as compact because of it
    /// (round 74). This is deliberately a *content* inset rather than a constraint: the
    /// twelve menu screens share a nib and a navigation pattern but not a layout - each is
    /// its own storyboard scene - so a constraint would be twelve edits that can drift,
    /// where an inset is one number applied from the one method they all already call.
    static let menuListBreathingRoom = UIEdgeInsets(top: 32, left: 0, bottom: 40, right: 0)
    // Forty at the bottom (round 98). Ninety-six was round 94's answer to a list that
    // would not scroll at all - the real cause was the settings touch watcher, fixed in
    // round 97, so the margin comes back down to what the button row actually needs

    /// **How far in the outer buttons sit when the row has a large centre button.**
    ///
    /// Where every outer button sits, measured from the screen's edge.
    ///
    /// Round 135 had two arrangements, chosen by what was in the row: a big play button drew
    /// the small ones in to here, and a row of only small buttons went to the row's own ends.
    /// The second half is gone (James, round 157: "everything out to 55pt"), because "the
    /// row's own ends" was never one place - it was 51pt on the menus, 53 on the level list
    /// and 55 on the daily, depending on what each screen's container happened to be. A
    /// promise about where a thumb lands has to be one number.
    static let menuButtonRowInset: CGFloat = 55

    /// Where a small button sits when there is no large one to group around.
    ///
    /// **The wide arrangement**, for the screens whose button row is small buttons only -
    /// Settings, Information, the pack grid, Statistics - and for the two screens that build a
    /// close button by hand rather than taking the shared row.
    ///
    /// It was only the second of those until round 169: `layoutMenuButtonRow` had put every
    /// row out to `menuButtonRowInset`, which round 157 asked for and round 169 took back for
    /// the rows with nothing in the middle. A close button pulled in to 55pt beside an empty
    /// centre reads as a button that has been moved rather than placed.
    static let menuButtonWideInset: CGFloat = 24

    /// The least air between two buttons in a row, before the row's own inset gives way.
    ///
    /// A number the row is allowed to shrink *to*, not one it aims for: on every screen wide
    /// enough to honour its inset the spacing works out far larger than this.
    static let menuButtonLeastGap: CGFloat = 16

    /// Puts a menu's icon above its title, and hands anything that hung from the icon down to
    /// the title instead.
    ///
    /// James, round 210: "I do think the icons and titles should be swapped, with the icon at
    /// the top, then using the classic mode menu view style where the icon shrinks when the
    /// page is scrolled before the content scrolls. We can have this same setup across all the
    /// game mode menu views."
    ///
    /// These headers are storyboard scenes, so the order is a set of constraints rather than a
    /// stack view to reorder. Three things have to happen and only the third is easy to
    /// forget: the title stops hanging from the top, the icon takes its place, and **everything
    /// that hung from the icon's bottom now hangs from the title's** - otherwise the title
    /// lands on top of the content that used to sit below the icon.
    ///
    /// The rehang is done by rebuilding each affected constraint rather than by editing one:
    /// `NSLayoutConstraint` is immutable in every part that matters, so the only way to change
    /// what it points at is to make another and stand the first one down.
    ///
    /// - Returns: the constant the title's top constraint was using, so the caller can give
    ///   the icon the same inset and leave the block starting exactly where it did.
    @discardableResult
    func swapMenuHeader(icon: UIView, title: UIView, in container: UIView) -> CGFloat {
        var titleInset: CGFloat = 20

        for constraint in container.constraints {
            let titleFromTop = (constraint.firstItem === title && constraint.firstAttribute == .top)
                || (constraint.secondItem === title && constraint.secondAttribute == .top)
            if titleFromTop, constraint.firstItem !== icon, constraint.secondItem !== icon {
                titleInset = abs(constraint.constant)
                constraint.isActive = false
                continue
            }

            let hangsFromTheIcon = constraint.secondItem === icon
                && constraint.secondAttribute == .bottom
                && constraint.firstItem !== title
            guard hangsFromTheIcon, let first = constraint.firstItem else { continue }

            constraint.isActive = false
            let moved = NSLayoutConstraint(item: first,
                                           attribute: constraint.firstAttribute,
                                           relatedBy: constraint.relation,
                                           toItem: title,
                                           attribute: .bottom,
                                           multiplier: constraint.multiplier,
                                           constant: constraint.constant)
            moved.priority = constraint.priority
            moved.isActive = true
        }

        for constraint in container.constraints
        where (constraint.firstItem === icon && constraint.secondItem === title)
            || (constraint.firstItem === title && constraint.secondItem === icon) {
            constraint.isActive = false
        }
        // Whatever held the two together in the old order goes, so the new pair below is the
        // only thing saying which is above which

        for constraint in container.constraints
        where (constraint.firstItem === icon && constraint.firstAttribute == .top)
            || (constraint.secondItem === icon && constraint.secondAttribute == .top) {
            constraint.isActive = false
        }
        // **And whatever placed the icon's top edge in the old order goes too** (round 321, from
        // James's iPhone 16 Pro Max log). The Level Stats screen's storyboard hangs the picture
        // under the pack line - `levelImageView.top = packNameAndLevelNumberLabel.bottom + 40` -
        // and neither loop above touched it, because it involves neither the title nor anything
        // hanging from the icon's *bottom*. So after the swap four constraints made a circle:
        // icon above title (+10), title above pack line (+0), pack line above icon (+40). Auto
        // Layout cannot satisfy a loop, so it printed three "Unable to simultaneously satisfy
        // constraints" blocks every time the screen opened and broke a different constraint
        // each time to get out - which is why it looked right, and why "looked right" was luck.
        // The icon's top is set exactly once, just below, so nothing else may set it

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: container.topAnchor, constant: titleInset),
            title.topAnchor.constraint(equalTo: icon.bottomAnchor,
                                       constant: UIViewController.menuHeaderIconGap),
        ])
        return titleInset
    }

    /// Lays a screen's button row out the shared way.
    ///
    /// - Parameter sizes: each button's width, in the order they appear. The row is always
    ///   three cells - some of them the invisible `ButtonNull` spacer - so what differs
    ///   between screens is only whether one of the three is large.
    ///
    /// Every row's outer buttons land `menuButtonRowInset` from the screen's edge, whatever
    /// is in it. The rest of the width is shared evenly, so the middle of three always lands
    /// on the row's centre.
    ///
    /// **One row does not come through here**: the main menu's, which builds its own layout
    /// and sizes its collection view by assigning to `frame.size.width` - which autolayout
    /// overwrites on the next pass, so widening it in code moves nothing (tried and measured,
    /// round 157). Reaching 55pt there means changing the storyboard's width constraint. The
    /// main menu is exempt from the shared arrangement anyway (round 128): its information and
    /// settings buttons sit where James wants them, which is not where this method would put
    /// them.
    ///
    /// The **pause row** was the second of that pair until round 206. Both of its reasons had
    /// expired: round 191 removed its hand-set width when that turned out to be half of what
    /// pinned the iPad's pause screen into a 414pt box, and its outer cells are 50pt boxes now
    /// rather than 75pt boxes holding 50pt icons, so there is no padding left for its inset to
    /// correct for. It sat at 63pt while both were true.
    func layoutMenuButtonRow(_ row: UICollectionView, sizes: [CGFloat]) {
        guard sizes.isEmpty == false else { return }
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = .zero
        // Self-sizing off: with an estimate set, a cell measures itself from its own
        // constraints and the delegate's large button never reaches the layout

        let fromScreen = row.superview?.convert(row.frame.origin, to: nil).x ?? 0
        let hasLargeButton = sizes.contains { $0 > MainMenuCollectionViewCell.smallButtonSize }
                             || carriesReturnToGameButton
        // **A big button on the screen counts, not only a big button in the row** (James, round
        // 176: "as the pause screen info and settings views (including child views) have a big
        // play button, the small buttons should adopt the narrower position. In the main menu
        // info and settings views, these buttons should adopt the wider position").
        //
        // Settings and Information are one screen each, reached from two places, and the pause
        // versions carry the 75pt play that `ReturnToGameButton` adds. That button is a subview
        // of the screen rather than a cell in this row, so `sizes` cannot see it - which is why
        // both versions had been taking the wide arrangement and the pause ones read as a close
        // button that had wandered away from the play beside it.
        //
        // Asked of the screen rather than passed in by each caller, so it holds for the child
        // views too - the reference pages go three deep, and `pausedGameBehind` is the same walk
        // up the chain that decides whether the play button is there in the first place
        let target = hasLargeButton ? UIViewController.menuButtonRowInset
                                    : UIViewController.menuButtonWideInset
        let gapsWanted = CGFloat(max(sizes.count - 1, 1))
        let leastItNeeds = sizes.reduce(0, +)
            + gapsWanted*UIViewController.menuButtonLeastGap
        let inset = max(0, min(target - fromScreen,
                               (row.frame.width - leastItNeeds)/2))
        // **And never more inset than the row has room for** (James, round 339, from an iPad
        // with the window dragged narrow: "it's possible to resize the window to a point where
        // the UI buttons at the bottom aren't symmetrical any more... it's also possible that
        // the settings button disappears when the window is particularly narrow").
        //
        // The inset was a promise about where a thumb lands and nothing checked it against the
        // width it was being taken out of. Below about 210 points there was no room left for
        // two 50-point buttons and the gap between them, so the flow layout pushed the second
        // one out of the visible row - it did not shrink or overlap, it was simply gone. The
        // inset gives way first now, symmetrically, so the row always holds what is in it.
        // **Two arrangements, chosen by what is in the row** (James, round 169: "only views
        // with a big centre button should have the narrower position small buttons").
        //
        // Round 135 had two and picked between them the same way; round 157 collapsed them
        // into one because the *wide* one was not a number at all - it was "the row's own
        // ends", which meant whatever each screen's container happened to be: 51pt on the
        // menus, 53 on the level list, 55 on the daily. Three values for one promise.
        //
        // So this is round 135's rule with round 157's fix kept: still two arrangements, but
        // both are now numbers measured from the *screen's* edge, which is what an inset is a
        // promise about - where the thumb lands. A row with a big centre button draws its
        // small ones in to sit with it; a row of only small buttons spreads to the wide inset,
        // because there is nothing in the middle for them to group around
        let available = row.frame.width - inset*2
        // Measured from the *screen's* edge, not the row's. Some of these rows are inset by
        // their own container and some are not, so insetting each row by the same amount put
        // their close buttons in different places - which is the thing being fixed
        let gaps = max(sizes.count - 1, 1)
        let spacing = max(0, (available - sizes.reduce(0, +))/CGFloat(gaps))

        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        row.collectionViewLayout = layout

        for constraint in row.constraints where constraint.firstAttribute == .height {
            constraint.constant = sizes.max() ?? MainMenuCollectionViewCell.smallButtonSize
        }
        // The row grows to hold its tallest button, which is how a 75pt play button fits a
        // storyboard row built for 50s
    }

    /// Opens that gap on every list in the screen.
    ///
    /// **Spacer views, not a content inset** (round 96). The inset version pinned
    /// `contentOffset` to minus the top inset so the padding would be visible, and that is
    /// the only line in the app that *moves* a scroll view - the settings list stopped
    /// scrolling the round it was added and no amount of work on the affordance, the
    /// gesture, `delaysContentTouches` or the fade brought it back, because none of those
    /// was ever the problem. A header and a footer are inert: they are content, so the list
    /// scrolls exactly as it did before any of this, and the gap comes for free.
    func giveMenuListsBreathingRoom() {
        for table in view.menuLists() {
            defer { table.applyScrollAffordance() }

            table.delaysContentTouches = true
            table.canCancelContentTouches = true
            // The storyboard sets `delaysContentTouches` to NO on these tables, which hands a
            // touch straight to the row it landed on instead of holding it briefly to see
            // whether it becomes a drag. Set here because twelve scenes would each need the
            // same tick, and this is the one place they all pass through

            if table.contentInset != .zero {
                table.contentInset = .zero
                table.contentOffset.y = 0
            }
            // Undoing rounds 74 to 94 on any table that still carries them

            guard table.wantsBreathingRoom, table.wearsGlassPanel == false else { continue }
            // Not the tables that wear a panel: a panel stays put while its rows move, so
            // padding inside one only slides the rows down inside the card

            let top = UIViewController.menuListBreathingRoom.top
            let bottom = UIViewController.menuListBreathingRoom.bottom
            if table.tableHeaderView == nil {
                table.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: top))
            }
            if table.tableFooterView == nil {
                table.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: bottom))
            }
            // Sized by frame rather than by constraint, which is what a table header wants -
            // an autolayout header needs a self-sizing pass this does not need to spend
        }
    }

    /// How far in a menu's contents sit, for a window of this size.
    ///
    /// The whole of the resize behaviour, as arithmetic: any width past what
    /// `menuMaximumAspectRatio` allows is split evenly either side, and a window already that
    /// shape or narrower keeps everything it has. Pulled out of `limitMenuContentSize` in
    /// round 181 so the iPad resize audit (§12.0) can be *tested* at the sizes iPadOS hands
    /// out rather than only eyeballed at the two or three a person thinks to try - and those
    /// are the sizes nobody can see: split view, slide over, and the two extremes.
    ///
    /// - Parameter inherited: the safe area the screen already has from its parent. Menus
    ///   open on top of one another as child view controllers filling their parent, so a
    ///   child inherits the inset its parent applied - adding the full amount again on top
    ///   halved the content at every level down. Subtracting what is already there is what
    ///   makes this idempotent however deep the stack goes.
    static func menuContentInsets(available: CGSize,
                                  inherited: UIEdgeInsets = .zero,
                                  widthOnly: Bool = false) -> UIEdgeInsets {
        let tallest = widthOnly ? available.height : min(available.height, menuMaximumHeight)
        let vertical = max(0, (available.height - tallest)/2)
        // **A height ceiling as well, on James's word** (round 320: "the iPad UI width limit
        // looks good, but it also needs a height limit. to match similar to the largest
        // iPhone, or maybe slightly larger"). Rounds 180 and 181 took height caps out twice,
        // for a slide-over losing a row and the pack grid scrolling with room to spare; both
        // were caps set by *shape*, which bit windows no taller than a phone. This one is an
        // absolute height, so nothing phone-sized is touched, and a slide-over never reaches
        // here anyway because `limitMenuContentSize` stops at a compact width
        let widest = widthOnly ? menuMaximumWidth
                               : min(tallest*menuMaximumAspectRatio, menuMaximumWidth)
        // Width only, on a compact width: the shape cap is about a window that is too square
        // for its content, which is an iPad's problem, and applying it to a tall narrow pane
        // would squeeze a phone-shaped window for no reason
        let horizontal = max(0, (available.width - widest)/2)
        // Two ceilings, whichever is lower: a *shape* for windows that are merely too square,
        // and an absolute width for windows that are simply large. The ratio on its own leaves
        // a 13-inch iPad 853 points of content, which is not the phone app centred on a bigger
        // background - it is the phone app stretched across one
        // The shape is taken against the *capped* height, so a window shortened by the ceiling
        // is not then left wider than the shape allows for the height it actually shows
        return UIEdgeInsets(top: max(0, vertical - inherited.top),
                            left: max(0, horizontal - inherited.left),
                            bottom: max(0, vertical - inherited.bottom),
                            right: max(0, horizontal - inherited.right))
        // The inherited insets come off both axes alike: a child screen filling a parent that
        // already stepped in only makes up the difference, and the device's own safe area
        // counts towards the step rather than being added on top of it
    }

    /// Centres the menu's contents within `menuMaximumAspectRatio`, leaving its background alone.
    ///
    /// Call from `viewDidLayoutSubviews`: the inset depends on the size the view has been
    /// given, which is not known before then, and it must be recomputed if that changes.
    /// Sizes a child screen's view to fill this one, and keeps it filling it.
    ///
    /// **`bounds`, not `frame`.** A view's frame is its rect in its *superview's* coordinates,
    /// and every screen in this app is a child view added over another - so `self.view.frame`
    /// is measured in the grandparent's space and is the wrong rect to hand a child. It is
    /// also the wrong *size* the moment a transform is involved, because a frame is the
    /// transformed bounding box: the pause menu's parallax and the menus' 1.15 dismissal
    /// scale both make it lie. `MenuNavigation` learned this and said so in a comment; the six
    /// older presentation sites never got the fix, and round 188 found the result on an iPad -
    /// the pause screen laid out 420pt wide on a 1032pt screen, Home tucked against the title
    /// instead of in its corner, because `menuContentInsets` had been handed a view roughly
    /// half the screen's height and capped the width against that.
    ///
    /// The autoresizing mask is the other half. A frame assigned once is a frame that never
    /// changes, so nothing triggers the layout pass that would notice a bad one and correct
    /// it - which is why a wrong answer *stuck* rather than being fixed on the next pass. With
    /// the mask the child tracks the parent, on rotation and on an iPad window resize too.
    /// **Round 313 made this the only way a screen is presented.** James, playing in iPadOS
    /// 26's windowed mode and dragging the window into every shape it would take: "iPad
    /// layouts need work with resizing as there's quite a few issues". Eighteen call sites
    /// were still writing `child.view.frame = self.view.frame` by hand - the exact line this
    /// function was written in round 188 to replace, carrying both of its bugs: the frame is
    /// measured in the *grandparent's* coordinates, and without the mask it is a frame
    /// assigned once that nothing ever revisits. On a phone the window never changes shape
    /// after a screen opens, so neither bug could show; on an iPad every drag of the window
    /// left the screen on top laid out for the window before it.
    func fillSelf(with child: UIView) {
        child.transform = .identity
        child.frame = view.bounds
        child.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // The transform first: setting a frame on a transformed view garbles the bounds,
        // which is `MenuNavigation`'s own hard-won note
    }

    /// The size the aspect cap should measure itself against: the **window**, not this view.
    ///
    /// The cap is a shape - width against height - so it has to be given the shape the player
    /// is actually looking at. `view.bounds` is not reliably that: every screen here is a
    /// child view added over another, and a screen presented over the game view gets whatever
    /// rect that view had. Round 188 measured the result on a 13-inch iPad: the pause screen
    /// laid out **420pt wide on a 1032pt window**, which is the cap dividing by a height of
    /// about 677 rather than 1376 - so Home sat beside the title instead of in its corner and
    /// the button row bunched into the middle.
    ///
    /// The window rather than the screen, deliberately: iPadOS 26 hands this app windows it
    /// never asked for (§12.0's resize audit), and the shape to cap is the shape of the window
    /// it has been given. `view.bounds` remains the fallback for a view not yet in a window,
    /// where there is nothing better to ask and the answer is corrected on the next pass.
    var menuAvailableSize: CGSize {
        view.window?.bounds.size ?? view.bounds.size
    }

    func limitMenuContentSize() {
        keepReturnToGameButtonFrontmost()
        giveMenuListsBreathingRoom()
        capMenuContentSize()
    }

    /// The size cap on its own, without the list padding or the button re-fronting.
    ///
    /// **Round 339.** The main menu needs the column - it was the one screen laying its rows
    /// out across whatever window it was given - and it must not have the breathing room:
    /// its table is a fixed set of mode rows sized to fill the space exactly, not a list that
    /// scrolls, and 72 points of header and footer spacers turned a menu that fits into one
    /// that does not.
    func capMenuContentSize() {
        // Every menu screen calls this from viewDidLayoutSubviews, which makes it the one
        // place that runs on every layout of every screen - so it carries the return-to-game
        // button's re-fronting too. See keepReturnToGameButtonFrontmost for why it needs one

        let regular = traitCollection.horizontalSizeClass == .regular

        let inherited = UIEdgeInsets(
            top: view.safeAreaInsets.top - additionalSafeAreaInsets.top,
            left: view.safeAreaInsets.left - additionalSafeAreaInsets.left,
            bottom: view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom,
            right: view.safeAreaInsets.right - additionalSafeAreaInsets.right)
        let wanted = UIViewController.menuContentInsets(available: menuAvailableSize,
                                                        inherited: inherited,
                                                        widthOnly: regular == false)
        // **The width cap applies at any width class; the height and shape caps only on an
        // iPad** (James, round 339: "the cell views expand with the window until a point, then
        // snap back to a set width once the window is wide enough. Can we just make this set
        // width the maximum width of the cell views so there's no need for them to snap
        // back?").
        //
        // The snap was the size class changing. A window narrower than an iPad's regular
        // threshold is *compact*, this method stood down entirely, and the content filled it -
        // so at 480 points the cells were 480 wide and at 520, where the window turns regular,
        // they were suddenly 460. Nothing about the content wanted to be 480; it was simply
        // that nobody was capping it. The width cap costs a phone nothing, because no phone is
        // wider than 460 points, and it takes the step out.

        guard additionalSafeAreaInsets != wanted else { return }
        // Setting this triggers another layout pass, so assigning unconditionally would
        // loop for as long as the screen is on
        additionalSafeAreaInsets = wanted
    }
}

extension UIView {

    /// Every table in this screen, however deep it is nested.
    ///
    /// Tables only. The round buttons along the bottom are a collection view and want no
    /// padding at all - they are a row of three, not a list - and the daily's pager is a
    /// collection view whose whole point is that a page fills it.
    /// Whether this list may scroll at all.
    ///
    /// Off for a table sized to hold everything it will ever have - the two-item Mode Select
    /// chooser - where any give at all is a list wobbling for no reason (round 96).
    var wantsScrolling: Bool {
        get { (objc_getAssociatedObject(self, &UIView.scrollingKey) as? Bool) ?? true }
        set { objc_setAssociatedObject(self, &UIView.scrollingKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private static var scrollingKey = 0

    /// Whether this list wants the menus' padding.
    ///
    /// Off for a table whose height is worked out from its rows: padding it makes it
    /// overflow the height that was calculated to hold it exactly, which is how the two-item
    /// Mode Select chooser grew a scroll bar, and then - once its height counted the padding
    /// too - climbed 144 points up the screen into the sentence above it (round 95).
    var wantsBreathingRoom: Bool {
        get { (objc_getAssociatedObject(self, &UIView.breathingRoomKey) as? Bool) ?? true }
        set { objc_setAssociatedObject(self, &UIView.breathingRoomKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private static var breathingRoomKey = 0

    /// Whether a `addGlass(under:)` panel is sitting behind this view.
    var wearsGlassPanel: Bool {
        superview?.subviews.contains {
            $0 is UIVisualEffectView && $0.tag == SettingsTableViewCell.glassPanelTag
        } ?? false
    }

    func menuLists() -> [UITableView] {
        if let table = self as? UITableView { return [table] }
        return subviews.flatMap { $0.menuLists() }
    }

    /// How far a card drifts with the tilt of the device, at this width.
    ///
    /// Twenty-five points on a phone and fifty on an iPad, which is the figure sixteen screens
    /// have each written out for themselves since 2019. The bigger screen gets the bigger
    /// travel because the effect is read as a proportion of what is around it: 25 points on an
    /// 11-inch screen is a card that looks like it is not quite still.
    static func parallaxTravel(forWidth width: CGFloat) -> Int {
        width > 450 ? 50 : 25
    }

    /// Makes this view drift with the tilt of the device, replacing any drift it already has.
    ///
    /// **One recipe, at last.** Sixteen screens carry their own copy of these eight lines and
    /// this is the seventeenth caller, so it is written once here rather than once more there;
    /// the sixteen are a sweep for another round, and this is what they would call.
    ///
    /// The old group is removed first, because these screens re-apply on every appearance and
    /// motion effects stack - two groups on one card is a card that drifts twice as far as the
    /// one beside it.
    @discardableResult
    func applyMenuParallax() -> UIMotionEffectGroup {
        for existing in motionEffects where existing is UIMotionEffectGroup {
            removeMotionEffect(existing)
        }
        // All of them, not the first: this runs on every layout pass, and one missed group is
        // a card that drifts twice as far as the screen it is sitting on

        guard UIView.motionEffectsAreWelcome else { return UIMotionEffectGroup() }
        // **And nothing drifts while the system asks for less motion** (round 328). Guarded
        // here as well as at the screens' own `addParallax`, because this is what a pop-up
        // closing calls to hand the parallax back to the screens underneath it - a path that
        // does not go through any of them

        let amount = UIView.parallaxTravel(forWidth: window?.bounds.width ?? bounds.width)
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x",
                                                     type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y",
                                                   type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        // Measured against the *window*, not this view: the screens that wrote this out for
        // themselves each asked their own full-screen view how wide it was, and a card is a
        // few hundred points narrower than the screen it sits on - asking the card would put
        // an iPad on the phone's travel

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        addMotionEffect(group)
        return group
    }

    /// Drifts this view's content over the backdrop inside it.
    ///
    /// **For the screens built in code** (James, round 328, asked whether the five screens with
    /// no parallax were deliberate: "yes" - they were not). The Daily Challenge, Music, Paddle
    /// Speed and Run Statistics screens put their content straight onto `view` rather than into
    /// a content view of their own, so there is nothing to hand to `applyMenuParallax` the way
    /// the storyboard screens do. Every direct subview gets the same drift instead, which comes
    /// to the same thing: they move together, because they are given the same travel.
    ///
    /// **The blur stays still**, which is what makes it parallax rather than the screen sliding
    /// about: these four each lay a dark `UIVisualEffectView` over the menu behind them, and
    /// that is the backdrop the content drifts over. It is the same split the storyboard
    /// screens have, where the blur lives on `backgroundView` and the drift on the content.
    ///
    /// Called from `viewDidLayoutSubviews` rather than once, because the daily rebuilds its card
    /// when the day changes and a subview added later would otherwise be the one thing standing
    /// still. `applyMenuParallax` removes any drift it finds before adding its own, so asking
    /// twice costs a group rather than doubling the travel.
    /// - Parameter settings: where the player's own parallax setting is read from. Injectable so
    ///   a test can ask for both answers without writing a durable one - CLAUDE.md's rule that a
    ///   test may not leave anything behind, met the way `SavedGame` and the daily's clock meet
    ///   it. `object(forKey:)` rather than `bool(forKey:)` because the protocol has the first and
    ///   not the second, and the registered default is true either way.
    func applyMenuParallaxToContent(settings: KeyValueStore = UserDefaults.standard) {
        guard (settings.object(forKey: "parallaxSetting") as? Bool) ?? true else {
            subviews.forEach { subview in
                subview.motionEffects.forEach { subview.removeMotionEffect($0) }
            }
            return
            // Turned off while the screen is open - Settings is reachable from most of them
        }
        for subview in subviews where (subview is UIVisualEffectView) == false {
            subview.applyMenuParallax()
        }
    }

    /// Every view under this one that is drifting with the tilt, including this one.
    ///
    /// The screens do not all hang their parallax off the same view - the pause menu drifts
    /// its `containterView`, Settings its `backgroundView`, the menus their own - so finding
    /// them is a search rather than a lookup.
    func viewsWithParallax() -> [UIView] {
        let mine = motionEffects.contains { $0 is UIMotionEffectGroup } ? [self] : []
        return mine + subviews.flatMap { $0.viewsWithParallax() }
    }

    /// Takes the drift off, and hands back what to put it back on.
    ///
    /// **A pop-up stands the screen behind it still** (James, round 164). Two layers both
    /// drifting read as one of them coming loose - which is why Settings had been doing this
    /// by hand since long before there was a second pop-up type to do it for. Now the pop-up
    /// does it for whatever raised it, so no screen has to remember.
    static func standDownParallax(under root: UIView) -> [UIView] {
        let drifting = root.viewsWithParallax()
        for view in drifting {
            for effect in view.motionEffects where effect is UIMotionEffectGroup {
                view.removeMotionEffect(effect)
            }
        }
        return drifting
    }
}

extension UICollectionView {

    /// The section inset this collection view's own layout was given.
    ///
    /// **What `insetForSectionAt` should answer for a collection view it is not about.** A
    /// screen with a grid *and* a button row has one delegate serving both, and each of the
    /// three screens that do wrote `guard collectionView == grid else { return .zero }` -
    /// which silently threw away the inset `layoutMenuButtonRow` had just set on the row,
    /// because a delegate's answer beats the layout's own property.
    ///
    /// That is why the pack screen's Game Center button sat 90pt from the right edge while
    /// its close button sat at 20 (James, round 165's screenshot), on a screen rounds 157 and
    /// 158 had supposedly moved out to 55: those rounds set the property, and this delegate
    /// method had been overruling it since long before them.
    ///
    /// Handing back the layout's own value is right for any row - where nothing set one it is
    /// `.zero`, which is what these were returning anyway.
    var ownSectionInset: UIEdgeInsets {
        (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
    }
}

extension UIView {

    /// Whether the app may add motion effects - the parallax that drifts a background under the
    /// device's tilt, and anything else that moves without being asked to.
    ///
    /// **Off when the system says Reduce Motion** (round 328). The app has had a parallax
    /// setting of its own since long before this, which is the right control to keep; what it
    /// did not have was any regard for the one a player sets once, in Settings, for every app
    /// on the phone. Apple's rule is that the app simply stops animating - the app's own
    /// setting is left exactly as the player left it, so nothing changes back when they turn
    /// Reduce Motion off again.
    static var motionEffectsAreWelcome: Bool {
        UIAccessibility.isReduceMotionEnabled == false
    }
}

/// The rack of balls a run has left, drawn the size the HUD draws it.
///
/// **James, round 332's layout notes: "show number of balls remaining above 3 lives left
/// label"**, and round 339 across three screens at once: "add the balls graphic above the x
/// balls remaining label", "I noticed balls left and lives left on different screens - let's
/// use balls instead of lives everywhere", and "make ball graphics for lives the same size as
/// they are in the game for the pause screens".
///
/// The pause screen grew one of these in round 335a and the resume card and the between-levels
/// card did not, so a run that ended reported its rack three different ways: a pill of balls, a
/// line saying lives, and a line saying balls. One view now, built once and asked for a number.
///
/// **The size is the game's, not a number of its own.** `GameSceneLayout` works the ball's size
/// out from the screen it is given - `layoutUnit*0.67`, where the unit is a twenty-second of the
/// play area's width - so asking it for the screen this rack is on gives exactly the ball the
/// player was just looking at, on every device, without this file holding an opinion about it.
final class BallRackView: UIView {

    /// How many the HUD itself will draw, which is the most this should.
    static let mostShown = GameScene.maxLivesShown

    private let balls = UIStackView()
    private var ballSize: CGFloat = 12
    private var sizes: [NSLayoutConstraint] = []
    private var shown = -1

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(white: 1, alpha: 0.10)
        balls.translatesAutoresizingMaskIntoConstraints = false
        balls.axis = .horizontal
        balls.alignment = .center
        addSubview(balls)
        NSLayoutConstraint.activate([
            balls.centerXAnchor.constraint(equalTo: centerXAnchor),
            balls.centerYAnchor.constraint(equalTo: centerYAnchor),
            leadingAnchor.constraint(equalTo: balls.leadingAnchor, constant: -padding),
            trailingAnchor.constraint(equalTo: balls.trailingAnchor, constant: padding),
            heightAnchor.constraint(equalTo: balls.heightAnchor, constant: padding*2),
        ])
        // The pill is the stack plus the HUD's own padding on all four sides, rather than a
        // fixed height: a ball sized for an iPad needs a taller pill than one sized for a
        // phone, and two numbers that have to agree are one number too many
    }

    required init?(coder: NSCoder) { nil }

    /// The air the HUD leaves around its own row, in ball widths.
    private var padding: CGFloat { ballSize*0.55 }

    /// Draws `count` balls at the size the game would draw them on a screen this size.
    ///
    /// - Returns: whether there is anything to show. A rack of none is no pill at all rather
    ///   than an empty one: the last ball is in play, and a row of nothing above "Last ball"
    ///   says the opposite of what the words say.
    @discardableResult
    func show(_ count: Int, on screen: CGSize, ball image: UIImage?) -> Bool {
        let wanted = max(0, min(count, BallRackView.mostShown))
        let size = GameSceneLayout(screen: screen).ballSize
        guard wanted != shown || abs(size - ballSize) > 0.5 else { return wanted > 0 }
        shown = wanted
        ballSize = size
        balls.spacing = size*0.6
        // `ballSize*1.6` centre to centre in the HUD, which is a gap of 0.6 between the edges

        balls.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sizes.forEach { $0.isActive = false }
        sizes = []
        for _ in 0..<wanted {
            let ball = UIImageView(image: image)
            ball.contentMode = .scaleAspectFit
            ball.alpha = GameScene.lifeIconAlpha
            // The HUD's own alpha for a ball it still has
            ball.translatesAutoresizingMaskIntoConstraints = false
            let width = ball.widthAnchor.constraint(equalToConstant: size)
            let height = ball.heightAnchor.constraint(equalToConstant: size)
            NSLayoutConstraint.activate([width, height])
            sizes += [width, height]
            balls.addArrangedSubview(ball)
        }
        layer.cornerRadius = (size + padding*2)/2
        isHidden = wanted == 0
        return wanted > 0
    }

    /// The ball skin the player has chosen, which the rack wears like the HUD does.
    static func chosenBall(in defaults: UserDefaults) -> UIImage? {
        let setup = LevelPackSetup()
        let index = min(max(defaults.integer(forKey: "ballSetting"), 0),
                        setup.ballImageArray.count - 1)
        return setup.ballImageArray[index]
    }

    /// What every screen calls the rack now.
    ///
    /// **James, round 339: "I noticed balls left and lives left on different screens - let's
    /// use balls instead of lives everywhere."** The game has never had lives in it. It has
    /// balls, and one of them is in play.
    static func line(for balls: Int) -> String {
        balls == 1 ? "1 ball left" : "\(balls) balls left"
    }
}
