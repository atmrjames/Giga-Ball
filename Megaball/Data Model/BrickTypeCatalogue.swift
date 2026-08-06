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

    /// A line on an entry's detail page.
    struct Fact {
        let label: String
        let value: String
    }

    struct Entry {
        let name: String
        let description: String
        /// What to draw for it.
        let art: BrickTypeArt
        /// Whether this is one of the things Endless 2.0 adds, rather than something the game
        /// has always had. §7.3 asks for the new material to be marked as such.
        let isNew: Bool
        let facts: [Fact]
    }

    struct Section {
        let title: String
        let entries: [Entry]
    }

    static var sections: [Section] {
        [Section(title: "Behaviours", entries: behaviours),
         Section(title: "Styles", entries: styles),
         Section(title: "Sizes", entries: sizes)]
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
                  description: "Destroyed by a single hit. It carries a colour, and the colour is what decides its score.",
                  art: .behaviour(.standard),
                  isNew: false,
                  facts: [Fact(label: "Hits to destroy", value: "1"),
                          Fact(label: "Found in", value: "Every mode")]),

            Entry(name: name(of: .multiHit),
                  description: "Four stages deep, shown here in the order they arrive. Each hit steps it down to the next, and the fourth destroys it. Clear Multi-Hit drops every one of them to a single hit; Reset Multi-Hit puts them all back.",
                  art: .behaviour(.multiHit),
                  isNew: false,
                  facts: [Fact(label: "States", value: "4"),
                          Fact(label: "Hits to destroy", value: "4"),
                          Fact(label: "Found in", value: "Every mode")]),

            Entry(name: "Indestructible",
                  description: "Two states, and neither can be broken by the ball. The first hit does not destroy it - it turns it into the second, so the first hit makes the wall rather than breaking it. After that a hit does nothing at all. Cleared only by Zap Indestructible, a Wrecking Ball or an explosion. Giga-Ball passes straight through one and leaves it standing.",
                  art: .behaviour(.indestructibleOnce),
                  isNew: false,
                  facts: [Fact(label: "States", value: "×1, then ×2"),
                          Fact(label: "Hits to destroy", value: "Cannot be destroyed"),
                          Fact(label: "Cleared by", value: "Zap, Wrecking Ball, explosions"),
                          Fact(label: "Found in", value: "Every mode")]),

            Entry(name: name(of: .invisible),
                  description: "Solid, but not drawn until something strikes it. From the moment it appears it is an ordinary Standard brick. Show Bricks reveals them; Hide Bricks puts them back.",
                  art: .behaviour(.invisible),
                  isNew: false,
                  facts: [Fact(label: "Hits to destroy", value: "1, after it appears"),
                          Fact(label: "Found in", value: "Every mode")])
        ]
    }

    // MARK: - Styles

    static func name(of style: EndlessIIStyle) -> String {
        switch style {
        case .rounded: return "Rounded"
        case .spinning: return "Spinning"
        case .flashing: return "Flashing"
        case .gravity: return "Gravity"
        case .moving: return "Moving"
        case .directional: return "Directional"
        case .exploding: return "Exploding"
        case .spawner: return "Spawner"
        case .portal: return "Portal"
        case .fixed: return "Fixed"
        }
    }

    /// The order the styles are listed in.
    ///
    /// The ones that only change how a brick looks or bounces first, then the ones that change
    /// what the field does. A player reading down the page meets the small ideas before the
    /// large ones, which is also the order a run introduces them in.
    static let styleOrder: [EndlessIIStyle] = [.rounded, .spinning, .flashing, .fixed,
                                               .gravity, .moving, .directional,
                                               .exploding, .spawner, .portal]

    private static func description(of style: EndlessIIStyle) -> String {
        switch style {
        case .rounded:
            return "The same oblong brick with its corners rounded away. A hit along the flat of an edge behaves exactly as it always has; a glancing hit near a corner leaves at an angle a square brick could never produce."
        case .spinning:
            return "Turns on the spot, and the bounce turns with it. The generator leaves the cells around it clear, because a brick twice as wide as it is tall needs the room to get round."
        case .flashing:
            return "Comes and goes. Solid and visible for a few seconds, then faded and passable for a few more. It will not turn solid while the ball is inside it, so it can never trap one."
        case .fixed:
            return "An ordinary brick until it is struck once. From then on it stops descending and holds its position, and a second hit destroys it. Anything descending onto it is destroyed by it, so leaving one alive carves a channel up through everything arriving above."
        case .gravity:
            return "Falls into any empty cell below it and keeps falling until something stops it. Destroy what it is resting on and it starts falling again."
        case .moving:
            return "Wanders from side to side within the room it has been given, turning back when something is in the way."
        case .directional:
            return "Takes damage from one side only. Every other side bounces the ball off without a mark. The side that works is drawn on the brick, so it is read from the artwork rather than guessed."
        case .exploding:
            return "Takes all eight of its neighbours with it when it is destroyed, whatever they are, Indestructible included. Explosions set off other explosions, and a long chain is a good moment rather than a problem."
        case .spawner:
            return "The opposite of Exploding: when it is destroyed it fills the empty cells around it with ordinary bricks. Never with another Spawner, and only where a cell is already empty, so it cannot run away with itself."
        case .portal:
            return "Struck rather than damaged. The ball entering one leaves from the other, keeping its speed. Alone it is a lift to the top of the field; in a pair it is a doorway, and it works both ways - the two colours say which end pairs with which, not which end is the way in."
        }
    }

    /// Which behaviours a style can be applied to, in words.
    ///
    /// Read off `EndlessIIStyle.suits` rather than written down, so the page cannot disagree
    /// with the game.
    static func behaviours(carrying style: EndlessIIStyle) -> String {
        if style == .portal {
            // Portal does not look for an Indestructible brick, it makes one - being struck
            // rather than damaged is part of what a Portal is
            return "Always Indestructible ×2"
        }
        let suited = allBehaviours.filter { style.suits($0) }
        guard suited.count < allBehaviours.count else { return "Any" }
        return suited.map(name(of:)).joined(separator: ", ")
    }

    /// Which other styles can share a brick with this one.
    ///
    /// Said whichever way is shorter. Spinning stacks with seven of the nine, and naming all
    /// seven is a line that reads as a list to work through rather than as a fact - where
    /// "any but Moving and Directional" is one thing to remember. Which way round that falls
    /// depends on the style, so it is measured rather than decided.
    static func styles(stackingWith style: EndlessIIStyle) -> String {
        let others = styleOrder.filter { $0 != style }
        let partners = others.filter { style.stacksWith($0) }
        guard partners.isEmpty == false else { return "Nothing - on its own" }
        guard partners.count < others.count else { return "Any other style" }

        let listed = partners.map(name(of:)).joined(separator: ", ")
        let refused = others.filter { style.stacksWith($0) == false }.map(name(of:))
        let excluded = "Any but " + refused.joined(separator: ", ")
        return excluded.count < listed.count ? excluded : listed
    }

    /// The sizes a style can be applied at.
    ///
    /// Unlike the two above this is not derivable: the size rules live in the scene's
    /// `endlessIICanTake`, which needs a live brick to answer. Written out here, and covered
    /// by a test that every style says something.
    static func sizes(carrying style: EndlessIIStyle) -> String {
        switch style {
        case .spinning:
            // A full-size brick already sweeps two cells in each direction as it turns, and a
            // Big one would need four
            return "Tiny and Normal"
        case .fixed, .gravity:
            // Only some quarters of a Tiny set would ever draw the style, and a Big one would
            // wall off two columns at once
            return "Normal"
        case .moving:
            // Both the room it looks for and the position it measures from assume a brick
            // sitting in exactly one cell
            return "Tiny and Normal"
        case .rounded, .flashing, .directional, .exploding, .spawner, .portal:
            return "Any"
        }
    }

    private static var styles: [Entry] {
        styleOrder.map { style in
            Entry(name: name(of: style),
                  description: description(of: style),
                  art: .style(style),
                  isNew: true,
                  facts: [Fact(label: "Behaviours", value: behaviours(carrying: style)),
                          Fact(label: "Sizes", value: sizes(carrying: style)),
                          Fact(label: "Stacks with", value: styles(stackingWith: style)),
                          Fact(label: "Found in", value: "Endless 2.0")])
        }
    }

    // MARK: - Sizes

    static func name(of size: BrickSize) -> String {
        switch size {
        case .tiny: return "Tiny"
        case .normal: return "Normal"
        case .big: return "Big"
        }
    }

    private static func description(of size: BrickSize) -> String {
        switch size {
        case .tiny:
            return "A quarter of a cell - half the width and half the height. Four of them fit where one ordinary brick would, and a cell holding one of them is not a wall."
        case .normal:
            return "One cell, which is what every brick in Classic and Endless is."
        case .big:
            return "Two cells by two. It takes four times the room and needs four times the clearing."
        }
    }

    private static func occupies(_ size: BrickSize) -> String {
        switch size {
        case .tiny: return "A quarter cell"
        case .normal: return "One cell"
        case .big: return "2 × 2 cells"
        }
    }

    private static var sizes: [Entry] {
        BrickSize.allCases.map { size in
            Entry(name: name(of: size),
                  description: description(of: size),
                  art: .size(size),
                  isNew: size != .normal,
                  facts: [Fact(label: "Occupies", value: occupies(size)),
                          Fact(label: "Behaviours", value: "Any"),
                          Fact(label: "Styles", value: size == .big ? "Any but Spinning" : "Any"),
                          Fact(label: "Found in",
                               value: size == .normal ? "Every mode" : "Endless 2.0")])
        }
    }
}

/// What a catalogue entry's icon is a picture of.
enum BrickTypeArt {
    case behaviour(EndlessIIBehaviour)
    case style(EndlessIIStyle)
    case size(BrickSize)
}
