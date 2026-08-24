//
//  EndlessIIBrickSpec.swift
//  Megaball
//
//  What one cell of a designed formation is made of.
//
//  Set rows and clusters have always been written as text, one character per column, and the
//  alphabet was six characters wide:
//
//      .  empty     N  ordinary     M  multi-hit     i  indestructible x1     I  x2     ?  any
//
//  That was the whole vocabulary, and every designed brick carried `endlessIIStaysPlain`, so
//  a formation could never contain a shape, a size or an action. Thirty-one designed
//  formations were built from four kinds of brick while the field around them had four types,
//  five shapes, three sizes and nine actions to draw on.
//
//  ## Why a legend rather than more letters
//
//  The obvious fix is more characters - `v` for convex, `s` for spinning, `d` for diamond. It
//  does not survive contact with the combinations: a brick is a type *and* a shape *and* a
//  size *and* up to two actions, which is thousands of possibilities, and one character cannot
//  carry "multi-hit convex spinning" however many letters are left in the alphabet.
//
//  So the grid keeps one character per cell and each formation brings its own key. `A` means
//  whatever this formation says it means, and it means something else in the next one. A
//  formation rarely needs more than three or four distinct kinds, so the local alphabet stays
//  small while the space it can reach is the whole of it.
//
//  Two things that fall out of it and are worth stating:
//
//  **The shape is still visible in the source**, which is most of why these are worth having.
//  A ring you can see in the file is a ring somebody can edit.
//
//  **The old six characters are just a legend everybody shares.** `EndlessIIBrickSpec.classic`
//  is that legend written down, so every formation authored before this keeps working with no
//  edit at all, and the new ones sit beside them in the same catalogue.
//
//  ## Nothing here decides what may combine
//
//  A spec says what a brick should be. Whether that brick can *exist* is `EndlessIIStyle`'s
//  question and it already has an answer - `stacksWith`, `suits`, and the size rules in
//  `endlessIICanTake`. This file asks; it never rules. `EndlessIIBrickSpecTests` walks every
//  legend in every formation and puts each spec to those rules, so an impossible brick is a
//  failing test rather than a field that quietly builds something else.
//

import Foundation

/// One cell of a designed formation.
///
/// Every axis is optional and nil means **"whatever the generator would have put there"** -
/// the same thing `?` has always meant, one axis at a time. So `EndlessIIBrickSpec(shape:
/// .wedge)` is "a wedge of whatever type the field is making", which is a formation that
/// varies where it should and is fixed where the design cares.
struct EndlessIIBrickSpec: Equatable {

    /// What a hit does to it. Nil for the field's own mix.
    var behaviour: EndlessIIBehaviour?

    /// What it is shaped like: one of `EndlessIIStyle`'s five shapes, or nil for an oblong.
    ///
    /// Held as a style rather than an `EndlessIIFace` because Rounded is a shape here and is
    /// not a face - it has its own drawing and its own body. `isShape` is the check.
    var shape: EndlessIIStyle?

    /// How much of the field it takes up. Nil for one ordinary cell.
    var size: BrickSize?

    /// What it does beyond being hit. Empty for a plain brick.
    ///
    /// A list because two are allowed and `endlessIIMaximumStyles` is the cap; the validation
    /// asks that rather than repeating the number.
    var actions: [EndlessIIStyle]

    /// Which face a Directional brick opens on. Nil lets the generator choose, which is what
    /// it does today - and it chooses a face the ball can actually reach (round 233), so a
    /// formation should usually leave this alone.
    var side: EndlessIISide?

    /// Which way up a shaped face sits, and which way round. Nil rolls it, as `makeFace` does.
    var mirrored: Bool?
    var flipped: Bool?

    /// True for a cell that holds nothing at all.
    var isEmpty: Bool = false

    init(behaviour: EndlessIIBehaviour? = nil,
         shape: EndlessIIStyle? = nil,
         size: BrickSize? = nil,
         actions: [EndlessIIStyle] = [],
         side: EndlessIISide? = nil,
         mirrored: Bool? = nil,
         flipped: Bool? = nil,
         isEmpty: Bool = false) {
        self.behaviour = behaviour
        self.shape = shape
        self.size = size
        self.actions = actions
        self.side = side
        self.mirrored = mirrored
        self.flipped = flipped
        self.isEmpty = isEmpty
    }

    /// An empty cell.
    static let nothing = EndlessIIBrickSpec(isEmpty: true)

    /// A cell the generator fills as it would have anyway - the old `?`.
    static let anything = EndlessIIBrickSpec()

    /// Every style this spec asks a brick to wear, shape included.
    ///
    /// The one place the two are put back together, because the compatibility rules do not
    /// distinguish them: `stacksWith` is asked of styles, and a shape is a style.
    var styles: [EndlessIIStyle] {
        (shape.map { [$0] } ?? []) + actions
    }

    /// Whether a hit on this cell can eventually take it away.
    ///
    /// A cell whose behaviour is unspecified counts as breakable: `?` is the field's own mix
    /// and is mostly destructible, which is how the six-character alphabet has always been
    /// read. The question matters for the rule that no designed row may be a wall with nothing
    /// to earn - see the catalogue's tests.
    var isBreakable: Bool {
        guard isEmpty == false else { return false }
        switch behaviour {
        case .indestructibleOnce, .indestructibleAlways: return false
        case .standard, .multiHit, .invisible, nil: return true
        }
    }

    /// Whether this spec asks for anything at all beyond an ordinary brick.
    ///
    /// A spec that asks for nothing is `?`, and a formation full of them is a formation with
    /// no design in it - which is worth being able to detect rather than being a shape that
    /// silently does nothing.
    var isPlain: Bool {
        behaviour == nil && shape == nil && size == nil && actions.isEmpty
    }

    // MARK: - The shared legend

    /// The six characters every formation written before round 238 uses.
    ///
    /// Written as specs rather than as a special case in the builder, so the old alphabet and
    /// a formation's own key go through exactly the same path. There is no "legacy" branch to
    /// drift.
    static let classic: [Character: EndlessIIBrickSpec] = [
        ".": .nothing,
        "?": .anything,
        "N": EndlessIIBrickSpec(behaviour: .standard),
        "M": EndlessIIBrickSpec(behaviour: .multiHit),
        "i": EndlessIIBrickSpec(behaviour: .indestructibleOnce),
        "I": EndlessIIBrickSpec(behaviour: .indestructibleAlways),
    ]

    /// What a character means in a given formation: its own key first, the shared one after.
    ///
    /// A formation may therefore *override* `N` if it has a reason to, and most will not
    /// bother. Unknown characters read as empty, which is what the old builder did with them.
    static func spec(for character: Character,
                     legend: [Character: EndlessIIBrickSpec]) -> EndlessIIBrickSpec {
        legend[character] ?? classic[character] ?? .nothing
    }
}

extension EndlessIIStyle {
    /// Whether this style is one of the five things a brick can be *shaped* like.
    ///
    /// `isFace` is the four drawn silhouettes; this is those four plus Rounded, which the
    /// brick workbook lists as a shape and which the game has always treated as one - it
    /// replaces the outline and refuses every other shape.
    var isShape: Bool { isFace || self == .rounded }
}

/// What is wrong with a spec, in the words somebody authoring a formation would want.
///
/// A type rather than a bool because "this formation is invalid" is not actionable and "Turbine
/// asks for a Spinning Fixed brick" is.
enum EndlessIIBrickSpecFault: Equatable, CustomStringConvertible {
    case twoShapes(EndlessIIStyle, EndlessIIStyle)
    case notAShape(EndlessIIStyle)
    case notAnAction(EndlessIIStyle)
    case tooManyStyles(Int)
    case stylesRefuseEachOther(EndlessIIStyle, EndlessIIStyle)
    case styleRefusesBehaviour(EndlessIIStyle, EndlessIIBehaviour)
    case sideWithoutDirectional
    case orientationWithoutAShape
    case sizeNotYetBuildable(BrickSize)
    case styleRefusesSize(EndlessIIStyle, BrickSize)

    var description: String {
        switch self {
        case .twoShapes(let a, let b):
            return "asks for two shapes at once (\(a) and \(b)) - a brick has one outline"
        case .notAShape(let style):
            return "\(style) is not a shape - it belongs in `actions`"
        case .notAnAction(let style):
            return "\(style) is a shape - it belongs in `shape`, not in `actions`"
        case .tooManyStyles(let count):
            return "asks for \(count) styles, and \(GameScene.endlessIIMaximumStyles) is the cap"
        case .stylesRefuseEachOther(let a, let b):
            return "\(a) and \(b) cannot share a brick"
        case .styleRefusesBehaviour(let style, let behaviour):
            return "\(style) cannot be carried by \(behaviour)"
        case .sideWithoutDirectional:
            return "names an open side without asking for Directional"
        case .orientationWithoutAShape:
            return "names an orientation without asking for a shape to turn"
        case .sizeNotYetBuildable(let size):
            return "asks for a \(size) brick, and a formation cannot place one yet - it needs "
                + "the two-row reserve, and a row either reserves or runs a pattern"
        case .styleRefusesSize(let style, let size):
            return "\(style) cannot be carried by a \(size) brick"
        }
    }
}

extension EndlessIIBrickSpec {

    /// Everything wrong with this spec, empty when it describes a brick the game can build.
    ///
    /// **Every rule here is asked of `EndlessIIStyle`, never restated.** The compatibility grid
    /// is one decision and it lives there; a validator that carried its own copy would be
    /// wrong the first time the grid changed, which is the exact failure that makes a reference
    /// page not worth having (`BrickTypeCatalogue` says the same thing about its own facts).
    ///
    /// The size rules in `endlessIICanTake` are deliberately not consulted. Those need a live
    /// brick in a live field - whether a spinner is in this column, whether a Directional brick
    /// has an open face - and a formation is authored long before either exists. What can be
    /// answered on paper is answered here; the rest is answered when the brick is built.
    var faults: [EndlessIIBrickSpecFault] {
        guard isEmpty == false else { return [] }
        var found: [EndlessIIBrickSpecFault] = []

        if let shape, shape.isShape == false { found.append(.notAShape(shape)) }
        for action in actions where action.isShape {
            found.append(.notAnAction(action))
        }
        // Caught separately from the pair rules below, because "Spinning is not a shape" is a
        // typo in the legend and "Spinning and Fixed cannot share a brick" is a design mistake,
        // and telling somebody the second when they made the first sends them the wrong way

        let all = styles
        if all.count > GameScene.endlessIIMaximumStyles {
            found.append(.tooManyStyles(all.count))
        }

        for (index, style) in all.enumerated() {
            for other in all.dropFirst(index + 1) {
                if style.isShape && other.isShape {
                    found.append(.twoShapes(style, other))
                } else if style.stacksWith(other) == false {
                    found.append(.stylesRefuseEachOther(style, other))
                }
            }
        }

        if let behaviour {
            for style in all where style.suits(behaviour) == false {
                found.append(.styleRefusesBehaviour(style, behaviour))
            }
        }

        if size == .big {
            found.append(.sizeNotYetBuildable(.big))
        }
        // **Big is refused rather than ignored.** It spans two rows, and rows arrive one at a
        // time from the top - so it has to be *reserved* by one row and built by the next, and
        // that machinery owns the row it runs on. A formation cannot ask for one while the rule
        // stands that a row either reserves or runs a pattern. Silently dropping the size would
        // have produced an ordinary brick where somebody drew a large one, which is the shape
        // coming out wrong with nothing to say why. The fault is meant to be deleted by the
        // round that builds it.
        //
        // **Tiny needs none of that** and is allowed: it is four quarter-cell bricks filling
        // one cell, built by splitting an ordinary one where it already stands (`makeTiny`),
        // which is a thing that can be done to a brick after the row is laid down

        for style in styles where style.suits(size ?? .normal) == false {
            found.append(.styleRefusesSize(style, size ?? .normal))
        }
        // The game's own size rules, asked rather than restated - the same bargain the pair
        // rules make above. A Tiny wedge is the obvious mistake here and is worth catching
        // where it is written rather than where it is built

        if side != nil, actions.contains(.directional) == false {
            found.append(.sideWithoutDirectional)
        }
        if (mirrored != nil || flipped != nil), shape == nil {
            found.append(.orientationWithoutAShape)
        }

        return found
    }

    var isBuildable: Bool { faults.isEmpty }
}
