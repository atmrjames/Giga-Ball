//
//  BrickTypeCatalogue.swift
//  Megaball
//
//  What the reference page says about every kind of brick.
//
//  Endless 2.0 describes a brick with three independent things: what a hit does to it
//  (behaviour), what it does beyond being hit (style), and how much of the field it takes up
//  (size). That is a good model to build on and a hard one to meet for the first time in the
//  middle of a run - a spinning Indestructible brick is two familiar ideas at once, and a
//  player who has met neither reads it as one strange new brick.
//
//  So this is the power-ups page for bricks. Same shape, same job: somewhere to go and find
//  out what the thing that just happened was.
//
//  The compatibility lines are *derived*, not written out. Which behaviours a style can carry
//  and which styles can share a brick are decisions that already exist in `EndlessIIStyle`,
//  and a reference page that repeated them by hand would be wrong the first time either one
//  changed - the exact failure that makes reference pages not worth having.
//

import SpriteKit

enum BrickTypeCatalogue {

    struct Entry {
        let name: String
        let description: String
        /// What to draw for it.
        let art: BrickTypeArt
        /// Whether this is one of the things Endless 2.0 adds, rather than something the game
        /// has always had. §7.3 asks for the new material to be marked as such.
        let isNew: Bool
    }

    struct Section {
        let title: String
        let entries: [Entry]
    }

    /// The page's own headings, and they are the 2026 brick workbook's (James, round 237: "the
    /// bricks info screen should be broken up into more sections - use the brick details
    /// reference").
    ///
    /// Three sections became five, and the split is the workbook's rather than a tidier
    /// version of the old one. "Styles" was fourteen entries under one heading covering three
    /// unrelated ideas - what a brick is *shaped* like, what it *does*, and two bricks that
    /// are neither - which is a heading that tells a player nothing about where to look. The
    /// order is what a brick *is* first - both kinds of it - and then the three axes that
    /// modify it: what shape, what size, what it does.
    static var sections: [Section] {
        [Section(title: "Classic Brick Types", entries: behaviours),
         Section(title: "Endless Mayhem Brick Types", entries: newBrickTypes),
         Section(title: "Shapes", entries: shapes),
         Section(title: "Sizes", entries: sizes),
         Section(title: "Movement Actions", entries: movementActions),
         Section(title: "On-Hit Actions", entries: onHitActions)]
    }
    // The two "what is this brick" headings sit together at the top (James, round 238), which
    // is the question a player arrives with. Everything below them is a modifier: what shape
    // that brick is, what size, what it does. The workbook's own order put the Mayhem bricks
    // last, and they are not a footnote - they are the other half of the first question

    /// One section's entries, by heading. For the tests, which should say which section they
    /// mean rather than counting along the list.
    static func section(titled title: String) -> [Entry]? {
        sections.first { $0.title == title }?.entries
    }

    /// Every entry in order, which is what the list is indexed by when a row is tapped.
    static var allEntries: [Entry] {
        sections.flatMap(\.entries)
    }

    // MARK: - Behaviours

    static let allBehaviours: [EndlessIIBehaviour] = [.standard, .multiHit, .indestructibleOnce,
                                                      .indestructibleAlways, .invisible]

    static func name(of behaviour: EndlessIIBehaviour) -> String {
        switch behaviour {
        case .standard: return "Standard"
        case .multiHit: return "Multi-Hit"
        case .indestructibleOnce: return "Indestructible ×1"
        case .indestructibleAlways: return "Indestructible ×2"
        case .invisible: return "Invisible"
        }
    }

    private static var behaviours: [Entry] {
        [
            Entry(name: name(of: .standard),
                  description: "Destroyed by a single hit",
                  art: .behaviour(.standard),
                  isNew: false),

            Entry(name: name(of: .multiHit),
                  description: "Takes multiple hits to destroy",
                  art: .behaviour(.multiHit),
                  isNew: false),

            Entry(name: "Indestructible",
                  description: "Cannot be destroyed",
                  art: .behaviour(.indestructibleOnce),
                  isNew: false),

            Entry(name: name(of: .invisible),
                  description: "Cannot be seen until hit",
                  art: .behaviour(.invisible),
                  isNew: false)
        ]
    }

    // MARK: - Styles

    static func name(of style: EndlessIIStyle) -> String {
        switch style {
        case .rounded: return "Round"
        case .spinning: return "Spinning"
        case .flashing: return "Flashing"
        case .gravity: return "Gravity"
        case .moving: return "Moving"
        case .directional: return "Directional"
        case .exploding: return "Exploding"
        case .spawner: return "Spawner"
        case .portal: return "Portal"
        case .breathing: return "Breathing"
        case .fixed: return "Fixed"
        case .convex: return "Convex"
        case .concave: return "Concave"
        case .wedge: return "Wedge"
        case .diamond: return "Diamond"
        }
    }

    /// The order the styles are listed in.
    ///
    /// The ones that only change how a brick looks or bounces first, then the ones that change
    /// what the field does. A player reading down the page meets the small ideas before the
    /// large ones, which is also the order a run introduces them in.
    static let styleOrder: [EndlessIIStyle] = shapeOrder + actionOrder + [.portal]

    /// What a brick is shaped like. Rounded leads, because it is the smallest departure from
    /// the oblong every brick has been since 2020, and Diamond comes last as the furthest
    /// carried - the only one with no flat face left at all.
    static let shapeOrder: [EndlessIIStyle] = [.rounded, .convex, .concave, .wedge, .diamond]

    /// What a brick does, in the two kinds James split it into (round 270).
    static let actionOrder: [EndlessIIStyle] = movementOrder + onHitOrder

    /// Actions you can see a brick performing.
    ///
    /// James, round 270: "these bricks can just use whatever brick graphic, with no additional
    /// graphic required. The movement is enough of an indication of the brick type."
    ///
    /// Which is the useful half of the distinction. A brick that is turning, fading, breathing,
    /// wandering or falling has already told you what it is by the time you look at it, so
    /// marking it as well would be saying the same thing twice - and the mark would have to sit
    /// on top of art that is already moving.
    static let movementOrder: [EndlessIIStyle] = [.spinning, .flashing, .breathing,
                                                  .moving, .gravity]

    /// Actions that only happen when the brick is struck.
    ///
    /// James, round 270: "these bricks have overlay graphics, graphics that go on top of the
    /// brick graphic to denote what type of brick it is, as these bricks otherwise can't be
    /// told apart until they're hit and run their action."
    ///
    /// The power-up brick is the fifth of these and is listed at the top of the page instead,
    /// as a type in its own right - it is also the one that already wears its overlay, since
    /// the icon it carries is exactly the mark this category describes. It is Square-only, so
    /// its overlay only ever has to be drawn at those proportions.
    static let onHitOrder: [EndlessIIStyle] = [.fixed, .directional, .exploding, .spawner]

    /// **The workbook's own words** (James, round 291: "for the brick and power up info /
    /// details, use the information that's written in the document I shared previously. The
    /// descriptions should match the ones I wrote").
    ///
    /// These were paragraphs written over a dozen rounds, and every one of them is now the line
    /// from `Giga-Ball 2026 - Brick Details.xlsx`. It is the same call round 229 made for the
    /// sixty-six power-ups - "shorter is better", in his words - and the same one made twice:
    /// the elaboration read as documentation on a screen a player opens mid-run to find out
    /// what a brick does.
    ///
    /// Two of the sheet's lines carry slips and keep the game's grammar instead, exactly as
    /// round 229 did with its three: Fixed reads "until its destroyed" and "any other brick the
    /// hits it" there.
    private static func description(of style: EndlessIIStyle) -> String {
        switch style {
        case .rounded:
            return "Smooth, corner-less brick"
        case .spinning:
            return "Spins around its centre"
        case .flashing:
            return "Flashes on and off"
        case .breathing:
            return "Shrinks and expands"
        case .fixed:
            return "When hit it is fixed in place until it is destroyed, destroying any other brick that hits it"
        case .gravity:
            return "Falls down into empty space below it"
        case .moving:
            return "Moves side to side into the empty spaces next to it"
        case .directional:
            return "Can only be destroyed from one side"
        case .exploding:
            return "Destroys surrounding bricks when hit"
        case .spawner:
            return "Creates new bricks nearby when hit"
        case .portal:
            return "Sends the ball to the top or to another portal brick. Cannot be destroyed"
        case .convex:
            return "Pointy brick"
        case .concave:
            return "Notched brick"
        case .wedge:
            return "Triangular brick"
        case .diamond:
            return "Each face is angled"
        }
    }
    // **Read off `EndlessIIStyle.suits` rather than written down**, which is what the line
    // above this one has always claimed and this one did not do. It was a switch of hand-typed
    // sentences, and round 237 changed the rules and moved only the generator's copy - so the
    // page spent three rounds telling players that Fixed is Normal-only and Moving is
    // Tiny-and-Normal, when both take any size now. That is the exact failure a derived
    // reference page exists to avoid, sitting inside one

    /// The drawn shapes, and then the Square brick.
    ///
    /// James, round 270: "Square brick should be under shapes, not sizes." Which is where a
    /// player looks for it: what makes a Square brick a Square brick is that it is square, and
    /// the 1 x 2 cells it occupies is the mechanism rather than the thing. The five above it
    /// are `EndlessIIStyle`s and it is a `BrickSize`, so the heading holds both - which is what
    /// `Entry` being a plain description rather than a wrapper around a style is for.
    private static var shapes: [Entry] { shapeOrder.map(entry(for:)) + [entry(for: .square)] }

    private static var movementActions: [Entry] { movementOrder.map(entry(for:)) }

    private static var onHitActions: [Entry] { onHitOrder.map(entry(for:)) }

    /// The two bricks Endless Mayhem adds, which are not a shape, a size or an action - they
    /// are types in their own right, and they sit under the classic four for that reason.
    ///
    /// A player who has just been hit by one of these is asking "what *was* that", which is
    /// the question the top of the page answers.
    private static var newBrickTypes: [Entry] { [powerUpBrick, entry(for: .portal)] }

    private static func entry(for style: EndlessIIStyle) -> Entry {
        Entry(name: name(of: style),
              description: description(of: style),
              art: .style(style),
              isNew: true)
    }

    // MARK: - Sizes

    static func name(of size: BrickSize) -> String {
        switch size {
        case .tiny: return "Tiny"
        case .normal: return "Normal"
        case .big: return "Big"
        case .square: return "Square"
        }
    }

    private static func description(of size: BrickSize) -> String {
        switch size {
        case .tiny:
            return "A quarter brick"
        case .normal:
            return "A regular brick size"
        case .big:
            return "Four times the size of a normal brick"
        case .square:
            return "Each side is the same"
            // James's own words, round 293, filling the one gap the workbook had - Square
            // arrived in round 247, after the sheet was drawn. The line before this was mine
            // ("twice the height of a normal brick"), which was true and was describing the
            // cells rather than the brick: what a player sees is a square
        }
    }

    /// The styles a brick of this size can carry.
    ///
    /// **Read off `EndlessIIStyle.suits` like its opposite number two hundred lines up**, and
    /// for the reason written there. This was the hand-typed sentence "Any but Spinning" for a
    /// Big brick and "Any" for everything else, which had been wrong since round 240: a Big
    /// brick cannot take Breathing or any of the four drawn faces either, and a Tiny one cannot
    /// take any of the six. Round 270 only noticed because Square moved to Shapes and would
    /// have gone on claiming it could be a Diamond.
    static func styles(fitting size: BrickSize) -> String {
        let refused = styleOrder.filter { $0.suits(size) == false }
        guard refused.isEmpty == false else { return "Any" }
        return "Any but " + refused.map(name(of:)).joined(separator: ", ")
    }

    /// The power-up brick, which is its own thing rather than a style or a size.
    ///
    /// It sat at the head of the Styles section, because a section holding one entry would
    /// have been a heading for its own sake. The workbook gives it a second occupant - Portal
    /// - so it has its own heading now, which is where it always belonged.
    static var powerUpBrick: Entry {
        Entry(name: "Power-Up",
              description: "Contains a power-up that activates when hit",
              art: .powerUpBrick,
              isNew: true)
    }

    private static var sizes: [Entry] {
        BrickSize.allCases.filter { $0 != .square }.map(entry(for:))
        // Square has moved to Shapes and is listed there instead of here, not as well: the
        // page's own test counts every entry once, and a brick in two sections is a brick a
        // player finds twice and cannot tell apart
    }

    private static func entry(for size: BrickSize) -> Entry {
        Entry(name: name(of: size),
              description: description(of: size),
              art: .size(size),
              isNew: size != .normal
)
    }
}

/// What a catalogue entry's icon is a picture of.
enum BrickTypeArt {
    case behaviour(EndlessIIBehaviour)
    case style(EndlessIIStyle)
    case size(BrickSize)

    /// The power-up brick, which is none of the three above.
    ///
    /// It borrowed `.style(.rounded)` and so the page showed a *rounded brick* - a picture of a
    /// different brick entirely, and one that stopped being even approximately right when round
    /// 271 gave the power-up brick its own badge. James, round 283: "power-up - use a generic
    /// power up graphic."
    case powerUpBrick
}
