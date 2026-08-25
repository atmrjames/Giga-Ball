//
//  EndlessIISizes.swift
//  Megaball
//
//  Big and Tiny bricks. Size is a separate axis from type - a Big brick is still whatever
//  type it was - so like the behaviours in EndlessIIBricks, these are applied to a brick
//  that already exists rather than being types of their own.
//
//  The rule everything here bends around: a brick's `position.y` is how the rest of the
//  game knows which row it is in. The descent moves every brick down by one row, and the
//  bottom-row check that gates new-row generation asks whether a brick's position has
//  reached the last row. A brick that put its position anywhere other than its row centre
//  would be removed at the wrong moment, or would sit in the bottom row blocking generation
//  while looking like it was somewhere else.
//
//  So Tiny simply shrinks in place, and Big keeps its node on a row centre and expresses
//  the extra size as an anchor point and an offset physics body.
//

import SpriteKit

/// Where a Big brick's sprite and body sit relative to its node.
///
/// It covers two columns and two rows: the row it is generated in, and the row below -
/// which was deliberately left empty a row earlier, because new rows arrive at the top and
/// there is nothing above them to grow into.
struct EndlessIIBigBrick {
    /// One cell: the size of an ordinary brick.
    let cell: CGSize

    var size: CGSize { CGSize(width: cell.width*2, height: cell.height*2) }

    /// Puts the node on the top-left cell's centre while the sprite covers all four.
    var anchorPoint: CGPoint { CGPoint(x: 0.25, y: 0.75) }

    /// The body follows the sprite, not the node.
    var bodyCentre: CGPoint { CGPoint(x: cell.width/2, y: -cell.height/2) }

    /// The node sits on the left column's centre, the same x an ordinary brick there
    /// would have.
    func nodeX(leftColumn: Int, gameWidth: CGFloat) -> CGFloat {
        -gameWidth/2 + cell.width/2 + cell.width*CGFloat(leftColumn)
    }

    /// The rectangle the brick actually covers, for checking it lands on whole cells.
    func coverage(leftColumn: Int, rowY: CGFloat, gameWidth: CGFloat) -> CGRect {
        let x = nodeX(leftColumn: leftColumn, gameWidth: gameWidth)
        return CGRect(x: x - cell.width/2, y: rowY - cell.height*1.5,
                      width: cell.width*2, height: cell.height*2)
    }

    /// Whether a Big brick starting here fits the field.
    static func fits(leftColumn: Int, columns: Int) -> Bool {
        leftColumn >= 0 && leftColumn + 1 < columns
    }
}

extension GameScene {

    /// How often a row leaves room for a Big brick, and how often an ordinary brick shrinks.
    ///
    /// Both are opening guesses. Big costs two rows of setup, so it should be the rarer of
    /// the two even at the same number.
    static let endlessIIBigChance = 18
    /// The deep rate for Tiny, kept here for the reference page. How often it actually
    /// happens is `EndlessIIProgression.tinyChance(at:)`, which ramps to this - a flat rate
    /// put the hardest thing in the mode in front of a player in their first twenty metres.
    static let endlessIITinyChance = EndlessIIProgression.deepTinyChance

    /// Which quarters of a cell a Tiny set fills.
    ///
    /// All four, or one of the two diagonal pairs. The diagonals are the interesting ones:
    /// they leave a route through the cell rather than a solid block, so a Tiny set is
    /// sometimes an obstacle and sometimes a gap with something in it - and the ball can be
    /// threaded between them.
    static func endlessIITinyLayout() -> [CGPoint] {
        let step = endlessIITinyOffset
        let topLeft = CGPoint(x: -step, y: step)
        let topRight = CGPoint(x: step, y: step)
        let bottomLeft = CGPoint(x: -step, y: -step)
        let bottomRight = CGPoint(x: step, y: -step)

        switch Int.random(in: 0...5) {
        case 0: return [topLeft, bottomRight]
        case 1: return [topRight, bottomLeft]
        default: return [bottomLeft, bottomRight, topLeft, topRight]
        }
        // Two in six, so the full set is genuinely the common case and a diagonal pair reads
        // as a variation on something familiar. It was one in two, which is not a weighting
        // at all - the comment said one thing and the arithmetic did another
    }

    /// The line the field shows between two ordinary bricks, in points.
    ///
    /// The brick artwork carries its own border on every edge, so two bricks side by side show
    /// two of them and that is the whole of the ordinary field's spacing. Measured off the
    /// artwork - twenty-eight pixels tall with a pixel of border - so it holds at any cell
    /// size.
    var endlessIIBrickSeam: CGFloat { brickHeight/14 }

    /// The extra gap left around each quarter of a Tiny set, in points.
    ///
    /// Half the seam, because a Tiny brick is drawn at half scale and so is the border in its
    /// own artwork - two of them come to half of what two ordinary bricks show, and this makes
    /// up the difference. The result is that a Tiny set is spaced exactly like the field around
    /// it.
    ///
    /// It used to be a fraction of a *cell*, applied to both axes. A cell is twice as wide as
    /// it is tall, so the same fraction meant the vertical gaps came out at half the horizontal
    /// ones - which is what made a set of four look nudged apart rather than laid out, and made
    /// the gaps down the middle the most obvious thing about a Tiny brick.
    var endlessIITinyGap: CGFloat { endlessIIBrickSeam/2 }

    /// How far each quarter sits from the centre of its cell, as a fraction of the cell.
    ///
    /// Exactly a quarter, on both axes, so the four sit on the quarter-cell centres the way
    /// ordinary bricks sit on cell centres. The gap comes out of each quarter's size instead,
    /// which keeps every gap in the set the same and matches the gap to the next cell along.
    static let endlessIITinyOffset: CGFloat = 0.25

    // MARK: - Big

    /// What this row has to leave empty, and what it has to build.
    ///
    /// Rows arrive one at a time from the top with nothing above them, so anything taller than
    /// one row cannot be built in one go: a row leaves the cells empty, and the next row builds
    /// down into the gap. A row either reserves or builds, never both.
    ///
    /// **One pending slot rather than four** (round 246). It was a property per shape - Big,
    /// power-up brick, spinner, and the spinner's own clearance - each cleared at the top and
    /// checked in a fixed order, which is four ways of saying one thing and four places to
    /// forget when a fifth shape arrives. A fifth is exactly what is coming: the 2x1 square
    /// size wants this sequence, a formation asking for a Big brick wants to drive it, and
    /// §6.2's Monolith wants both.
    func endlessIIPlanRow() -> EndlessIIRowPlan {
        guard gameMode == .endlessII else { return EndlessIIRowPlan() }

        if endlessIIPhase != .monolith { endlessIIMonolithRoute = nil }
        // The route is chosen once and held for the phase, or the channel would wander and the
        // block would stop being one block

        if endlessIIPendingBookings.isEmpty == false {
            let due = endlessIIPendingBookings
            endlessIIPendingBookings = due.compactMap { booking in
                guard case .spinner(let column) = booking.build else { return nil }
                return EndlessIIBooking(.spinnerClearance(column: column))
            }
            // A spinner is the odd one out: one cell, but it needs the cells above and below
            // kept clear, so it runs the sequence over three rows rather than two. The cell
            // below was left empty a row ago; this row places it and books the one above

            return EndlessIIRowPlan(skip: endlessIIColumns(due) { $0.columnsToClear(in: $1) },
                                    builds: due)
        }

        if endlessIIPhase == .monolith, let wall = endlessIIMonolithWall() {
            endlessIIPendingBookings = wall
            return EndlessIIRowPlan(skip: endlessIIColumns(wall) { $0.columnsToReserve(in: $1) })
        }
        // Asked before the rolls, because a Monolith row is the whole row: a spinner or a
        // power-up brick booked into the middle of a wall would be a hole the design did not
        // put there

        for candidate in endlessIIRowCandidates() {
            endlessIIPendingBookings = [EndlessIIBooking(candidate)]
            return EndlessIIRowPlan(skip: candidate.columnsToReserve(in: numberOfBrickColumns))
            // Reserved, not built: the cells this row leaves empty are the ones the next row
            // will fill from above.
            //
            // **One offer taken, however many were made.** More than one roll can come up on a
            // row and only the first is ever taken, which is what the chain of early returns
            // did and is the density the mode was play-tested at. Booking several is a thing a
            // *phase* asks for, and Monolith is the phase that asks
        }
        return EndlessIIRowPlan()
    }

    /// The columns a set of bookings wants, gathered.
    private func endlessIIColumns(_ bookings: [EndlessIIBooking],
                                  _ wanted: (EndlessIITwoRowBuild, Int) -> Set<Int>) -> Set<Int> {
        bookings.reduce(into: Set<Int>()) {
            $0.formUnion(wanted($1.build, numberOfBrickColumns))
        }
    }

    // MARK: - Monolith

    /// A wall of Big bricks with one channel left through it (§6.2).
    ///
    /// **The phase that needed the row to hold more than one shape.** "One enormous Big brick
    /// formation with a narrow route" is four Big bricks abreast on an eleven-column field, and
    /// four abreast is four reservations from one row - which is why this arrived with the
    /// booking list rather than with the other seventeen phases.
    ///
    /// A Big brick is two rows tall, so the phase alternates on its own: a row of holes, a row
    /// of wall, a row of holes. The block that comes out of that is solid except for the
    /// channel, and the channel is in the same columns for as long as the phase lasts - it is
    /// rolled once and held, because a route that moved from row to row would be a wall with
    /// gaps rather than a way through.
    ///
    /// Nil on a field too narrow to have a wall and a route both, which no shipping device is.
    func endlessIIMonolithWall() -> [EndlessIIBooking]? {
        let columns = numberOfBrickColumns
        guard columns >= 5 else { return nil }

        if endlessIIMonolithRoute == nil {
            let width = Int.random(in: 1...2)
            let start = Int.random(in: 0...(columns - width))
            endlessIIMonolithRoute = Set(start..<(start + width))
            // One or two columns out of eleven, which is the "narrow" in §6.2's line. Two is
            // a gap the ball goes through without being aimed; one has to be found
        }
        let route = endlessIIMonolithRoute ?? []

        var wall: [EndlessIIBooking] = []
        var column = 0
        while column + 1 < columns {
            guard route.contains(column) == false, route.contains(column + 1) == false else {
                column += 1
                continue
                // Stepped one at a time past the channel rather than two, so the wall picks up
                // again on the very next column the route does not want
            }
            wall.append(EndlessIIBooking(.big(leftColumn: column)))
            column += 2
        }
        return wall.isEmpty ? nil : wall
    }

    /// What this row might commit to, in the order it is offered.
    ///
    /// A sequence rather than a list, so a roll that fails costs nothing and the next shape is
    /// asked in turn - which is what the chain of early returns was doing, said once.
    private func endlessIIRowCandidates() -> [EndlessIITwoRowBuild] {
        var offered: [EndlessIITwoRowBuild] = []

        if Int.random(in: 1...100) <= GameScene.endlessIISpinChance {
            offered.append(.spinner(column: Int.random(in: 0..<max(1, numberOfBrickColumns))))
        }

        if endlessIIPowerUpBricksInPlay.isEmpty,
           Int.random(in: 1...100) <= GameScene.endlessIIPowerUpBrickChance {
            offered.append(.powerUpBrick(column: Int.random(in: 0..<max(1,
                                                                       numberOfBrickColumns))))
            // Not even reserved while one is still in play - the row that reserves is a row
            // with a hole in it, and holding one open for a brick that will not be built is
            // worse than not offering one
        }

        if Int.random(in: 1...100) <= GameScene.endlessIISquareChance {
            offered.append(.square(column: Int.random(in: 0..<max(1, numberOfBrickColumns))))
        }

        let bigChance = endlessIIPhase == .giants ? 90 : GameScene.endlessIIBigChance
        if Int.random(in: 1...100) <= bigChance {
            let left = Int.random(in: 0..<max(1, numberOfBrickColumns - 1))
            if EndlessIIBigBrick.fits(leftColumn: left, columns: numberOfBrickColumns) {
                offered.append(.big(leftColumn: left))
            }
        }

        return offered
        // The order is the priority the four early returns had: a spinner beats a power-up
        // brick beats a Big one, on the rows where more than one roll comes up
    }

    /// How often a row commits to the three-row sequence a spinning brick needs.
    static let endlessIISpinChance = 12

    /// How often a row commits to the two-row sequence a Square brick needs.
    ///
    /// Under a Big brick's, because it is the quieter of the two shapes: a Big one is an
    /// obstacle you plan a whole screen around, and a Square one is a column with a lid on it.
    /// Both cost a row with a hole in it, so neither can be common.
    static let endlessIISquareChance = 12

    /// Builds the Square brick a row owes: one cell wide, two tall, and square on screen.
    ///
    /// The same geometry the power-up brick has always had - `EndlessIITallBrick` is that plan
    /// with the power-up taken out of it (§12.0: "the power-up brick already builds one, so the
    /// machinery exists"). The node sits on the *upper* cell's centre with the sprite covering
    /// both, which is the trick a Big brick uses for the same reason: a brick's `position.y` is
    /// its row (§8.6), so the node stays on a row centre and the drawing hangs off it.
    func endlessIIMakeSquare(column: Int, rowY: CGFloat) -> SKSpriteNode {
        let plan = EndlessIITallBrick(cell: CGSize(width: brickWidth, height: brickHeight))

        let brick = SKSpriteNode(texture: endlessIIBrickTexture())
        brick.color = brickWhite
        brick.colorBlendFactor = brick.texture == brickNormalTexture ? 1 : 0
        brick.size = plan.size
        brick.anchorPoint = plan.anchorPoint
        brick.position = CGPoint(x: plan.nodeX(column: column, gameWidth: gameWidth), y: rowY)
        brick.zPosition = 1
        brick.name = BrickCategoryName
        brick.physicsBody = brickBody(SKPhysicsBody(rectangleOf: plan.size,
                                                    center: plan.bodyCentre))
        if brick.texture == brickInvisibleTexture { brick.isHidden = true }
        addChild(brick)
        return brick
        // Drawn from the field's own mix rather than always Standard, so a Square brick is a
        // *size* rather than a kind - which is the whole of what §12.0 asked for
    }

    /// Builds the Big brick a row owes, ready to be animated in with the rest of the row.
    func endlessIIMakeBig(leftColumn: Int, rowY: CGFloat) -> SKSpriteNode {
        let plan = EndlessIIBigBrick(cell: CGSize(width: brickWidth, height: brickHeight))

        let brick = SKSpriteNode(texture: brickNormalTexture)
        brick.color = brickWhite
        brick.colorBlendFactor = 1.0
        brick.size = plan.size
        brick.anchorPoint = plan.anchorPoint
        brick.position = CGPoint(x: plan.nodeX(leftColumn: leftColumn, gameWidth: gameWidth),
                                 y: rowY)
        brick.zPosition = 1
        brick.name = BrickCategoryName
        brick.physicsBody = brickBody(SKPhysicsBody(rectangleOf: plan.size,
                                                    center: plan.bodyCentre))
        addChild(brick)
        return brick
    }

    // MARK: - Tiny

    /// Shrinks some ordinary bricks to a quarter of a cell.
    ///
    /// Centred, so the node stays on its row centre and the gaps open up evenly around it -
    /// a quarter-cell brick pushed into one corner would read as a misplaced normal brick
    /// rather than as a small one.
    func applyEndlessIISizes(to bricks: inout [SKNode]) {
        guard gameMode == .endlessII else { return }

        var made: [SKNode] = []
        for node in bricks {
            guard let brick = node as? SKSpriteNode else { continue }
            guard brick.texture == brickNormalTexture else { continue }
            guard brick.endlessIIStaysPlain == false else { continue }
            guard isOrdinaryCellSized(brick) else { continue }
            // Already resized - the Big brick this row built comes through here too
            guard endlessIISpinners.contains(where: { $0.brick === brick }) == false else {
                continue
            }
            // A spinning brick is placed by the row generator, which runs before this, and
            // `endlessIICanTake` refuses to make a Tiny brick spin - but nothing stopped a
            // spinner being shrunk *afterwards*. Four quarter-cell bricks each turning about
            // their own centre sweep straight through one another, which is the one thing the
            // spinner's whole clearance rule exists to prevent
            let chance = endlessIIPhase == .miniatures
                ? 100
                : endlessIIProgression.tinyChance(at: endlessHeight)
            // Ramped with height rather than flat. The Miniatures phase is the exception and
            // stays a certainty - a phase whose whole character is Tiny bricks is not a phase
            // that should be waiting on a roll
            guard Int.random(in: 1...100) <= chance else { continue }
            made.append(contentsOf: Array(makeTiny(brick).dropFirst()) as [SKNode])
        }
        bricks.append(contentsOf: made)
        // The three new quarters join the row, so the arrival animation and the brick count
        // see them like anything else generated this row
    }

    /// Whether a brick is still exactly one cell.
    ///
    /// Compared with a tolerance, not for equality. `SKSpriteNode.size` is backed by floats,
    /// so a width assigned straight from `brickWidth` does not read back as `brickWidth` -
    /// a plain `==` here is always false, which silently turns off everything it guards.
    func isOrdinaryCellSized(_ brick: SKSpriteNode) -> Bool {
        let size = endlessIIFieldSize(of: brick)
        return abs(size.width - brickWidth) < 0.5 && abs(size.height - brickHeight) < 0.5
        // The field size rather than the sprite's, so a shaped brick is the ordinary cell it
        // fills rather than the third of one its sprite hides in (`endlessIIFieldSize`)
    }

    /// Replaces a brick with the four quarter-cell bricks that fill its cell.
    ///
    /// Four, not one. A single quarter-cell brick floating in the middle of an otherwise
    /// empty cell reads as a mistake - a normal brick that failed to draw properly - because
    /// nothing else in the field sits anywhere but on the grid. Four of them fill the cell
    /// exactly, so the cell still looks like a cell, and what the player gets is a brick
    /// that takes four hits to clear and opens gaps as it goes rather than one that vanishes
    /// in a single hit and leaves a hole.
    ///
    /// The original node becomes the bottom-left quarter and the other three are new, so
    /// whatever the caller already did to it - its texture, its colour - carries into at
    /// least one of them.
    func makeTiny(_ brick: SKSpriteNode) -> [SKSpriteNode] {
        let gap = endlessIITinyGap
        let quarter = CGSize(width: brickWidth/2 - gap, height: brickHeight/2 - gap)
        // Taken off the size rather than added around the position, so the four still fill
        // their cell and the gap at the cell's edge is half of the one down its middle - which
        // adds up to the same gap wherever two bricks meet
        let home = brick.position
        var quarters: [SKSpriteNode] = []

        for (index, offset) in GameScene.endlessIITinyLayout().enumerated() {
            let piece: SKSpriteNode
            if index == 0 {
                piece = brick
            } else {
                piece = SKSpriteNode(texture: brick.texture)
                piece.color = brick.color
                piece.colorBlendFactor = brick.colorBlendFactor
                piece.zPosition = brick.zPosition
                piece.name = BrickCategoryName
                addChild(piece)
            }
            piece.size = quarter
            piece.position = CGPoint(x: home.x + offset.x*brickWidth,
                                     y: home.y + offset.y*brickHeight)
            piece.physicsBody = brickBody(SKPhysicsBody(rectangleOf: quarter))
            quarters.append(piece)
        }
        return quarters
        // All four keep their row centre within half a cell of the original, so the descent
        // and the bottom-row check still read them as belonging to this row
    }
}
