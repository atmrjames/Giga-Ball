//
//  EndlessIIRowPlanTests.swift
//  GigaBallTests
//
//  The two-row sequence is the most delicate thing in the generator, and its failures are all
//  quiet ones. A shape whose reserved cells and built cells disagree leaves a hole in the field
//  or a brick inside another. A pending slot that is not cleared builds the same shape twice. A
//  row that both reserves and builds does neither properly.
//
//  None of that crashes and none of it looks wrong in one screenshot, which is why the
//  sequence is a value with its own tests now rather than four optional columns and a chain of
//  early returns.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIRowPlanTests: XCTestCase {

    private let columns = 11

    // MARK: - What each shape asks of the two rows

    /// A tall shape clears the same cells it reserved.
    ///
    /// It grows down into the gap the row before left, so the row that builds it must not put
    /// an ordinary brick in those columns first - it would end up inside the shape.
    func testATallShapeClearsExactlyWhatItReserved() {
        for build in [EndlessIITwoRowBuild.big(leftColumn: 4),
                      .powerUpBrick(column: 4)] {
            XCTAssertEqual(build.columnsToReserve(in: columns),
                           build.columnsToClear(in: columns), "\(build)")
        }
    }

    /// A Big brick takes two columns, and a power-up brick one.
    func testEachShapeTakesTheColumnsItActuallyFills() {
        XCTAssertEqual(EndlessIITwoRowBuild.big(leftColumn: 4).columnsToReserve(in: columns),
                       [4, 5])
        XCTAssertEqual(EndlessIITwoRowBuild.powerUpBrick(column: 4)
            .columnsToReserve(in: columns), [4])
    }

    /// A spinner reserves the cell *below* it and clears the two *beside* it.
    ///
    /// It is the one shape whose two rows ask for different cells, because it is not tall - it
    /// is one cell that sweeps a circle wider than itself, so the row before leaves room under
    /// it and the row that places it leaves room either side.
    func testASpinnerReservesBelowItAndClearsBesideIt() {
        let spinner = EndlessIITwoRowBuild.spinner(column: 5)
        XCTAssertEqual(spinner.columnsToReserve(in: columns), [5])
        XCTAssertEqual(spinner.columnsToClear(in: columns), [4, 6])
    }

    /// Nothing is ever asked for outside the field.
    ///
    /// A spinner against a wall has one side and a Big brick is offered a left column that
    /// leaves room - but the trimming is here rather than at each call site, because a column
    /// off the edge is a `Set` entry nothing matches and a hole that never appears.
    func testNoShapeReachesOutsideTheField() {
        for build in [EndlessIITwoRowBuild.spinner(column: 0),
                      .spinner(column: columns - 1),
                      .big(leftColumn: columns - 1),
                      .powerUpBrick(column: 0)] {
            for column in build.columnsToReserve(in: columns)
                .union(build.columnsToClear(in: columns)) {
                XCTAssertTrue((0..<columns).contains(column), "\(build) reached \(column)")
            }
        }
    }

    // MARK: - The sequence itself

    private func fieldScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.numberOfBrickColumns = columns
        scene.brickWidth = 36
        scene.brickHeight = 18
        scene.gameWidth = 396
        return scene
    }

    /// A row that owes a shape builds it, and books nothing new.
    ///
    /// **A row either reserves or builds, never both.** Two shapes arranging the same cells
    /// would leave neither of them intact, which is what the reservation guard on formations
    /// exists to prevent as well.
    func testARowThatOwesAShapeBuildsItAndReservesNothing() {
        let scene = fieldScene()
        scene.endlessIIPendingBookings = [EndlessIIBooking(.big(leftColumn: 3))]

        let plan = scene.endlessIIPlanRow()
        XCTAssertEqual(plan.builds, [EndlessIIBooking(.big(leftColumn: 3))])
        XCTAssertEqual(plan.bigs.map(\.build.column), [3])
        XCTAssertEqual(plan.skip, [3, 4])
        XCTAssertTrue(scene.endlessIIPendingBookings.isEmpty,
                      "the bookings have to be emptied or the next row builds them again")
    }

    /// A spinner is the exception: placing one books the clearance above it.
    func testPlacingASpinnerBooksTheCellAboveIt() {
        let scene = fieldScene()
        scene.endlessIIPendingBookings = [EndlessIIBooking(.spinner(column: 5))]

        let plan = scene.endlessIIPlanRow()
        XCTAssertEqual(plan.spinAt, 5)
        XCTAssertEqual(plan.skip, [4, 6], "room to turn, either side")
        XCTAssertEqual(scene.endlessIIPendingBookings,
                       [EndlessIIBooking(.spinnerClearance(column: 5))],
                       "and the row above has to stay empty too")

        let next = scene.endlessIIPlanRow()
        XCTAssertEqual(next.skip, [5])
        XCTAssertNil(next.spinAt, "the clearance places nothing - it is a hole")
        XCTAssertTrue(scene.endlessIIPendingBookings.isEmpty,
                      "and the sequence ends there")
    }

    /// The three names the row generator asks by point at one shape each.
    func testTheThreeNamesReadTheOneValue() {
        XCTAssertEqual(EndlessIIRowPlan(build: .big(leftColumn: 2)).bigs.map(\.build.column),
                       [2])
        XCTAssertNil(EndlessIIRowPlan(build: .big(leftColumn: 2)).powerUpAt)
        XCTAssertNil(EndlessIIRowPlan(build: .big(leftColumn: 2)).spinAt)

        XCTAssertEqual(EndlessIIRowPlan(build: .powerUpBrick(column: 7)).powerUpAt, 7)
        XCTAssertEqual(EndlessIIRowPlan(build: .spinner(column: 9)).spinAt, 9)

        XCTAssertNil(EndlessIIRowPlan(build: .spinnerClearance(column: 9)).spinAt,
                     "a clearance is a hole, not a brick - it must not read as one")
    }

    /// A plain row asks for nothing and books nothing, which is most rows.
    func testAPlainRowIsPlain() {
        let scene = fieldScene()
        scene.gameMode = .classic
        let plan = scene.endlessIIPlanRow()
        XCTAssertTrue(plan.skip.isEmpty)
        XCTAssertTrue(plan.builds.isEmpty)
        XCTAssertTrue(scene.endlessIIPendingBookings.isEmpty,
                      "and no other mode is left holding one")
    }

    // MARK: - The Square size

    /// A Square brick is one cell wide and two tall, which is square on screen.
    ///
    /// A cell is twice as wide as it is tall, so "one by two in cells" and "square to look at"
    /// are the same statement - which is the whole reason the size is worth having and the
    /// reason it is called Square rather than Tall.
    func testASquareBrickIsOneCellAcrossAndTwoDown() {
        XCTAssertEqual(BrickSize.square.halfCellsWide, BrickSize.normal.halfCellsWide)
        XCTAssertEqual(BrickSize.square.halfCellsTall, BrickSize.big.halfCellsTall)
        XCTAssertEqual(BrickSize.square.scaleWide, 1)
        XCTAssertEqual(BrickSize.square.scaleTall, 2)
    }

    /// Every other size is still the same on both axes.
    ///
    /// The per-axis split is new, and the way it goes wrong is by being applied to the three
    /// that never needed it.
    func testTheOtherThreeSizesAreStillSquareInCells() {
        for size in [BrickSize.tiny, .normal, .big] {
            XCTAssertEqual(size.halfCellsWide, size.halfCellsTall, "\(size)")
        }
    }

    /// It runs the same two-row sequence as a power-up brick, and takes one column.
    func testASquareBrickReservesAndClearsItsOwnColumn() {
        let square = EndlessIITwoRowBuild.square(column: 6)
        XCTAssertEqual(square.columnsToReserve(in: columns), [6])
        XCTAssertEqual(square.columnsToClear(in: columns), [6])
        XCTAssertEqual(EndlessIIRowPlan(build: square).squares.map(\.build.column), [6])
        XCTAssertNil(EndlessIIRowPlan(build: square).powerUpAt,
                     "it is the same shape and not the same brick")
    }

    /// The field can tell one from the three sizes it already had.
    ///
    /// A Square brick is exactly one cell wide, so a width-only test calls it Normal - which is
    /// what `endlessIISizeOf` did until it was given a height to look at. And a Big brick is
    /// two cells on *both* axes, so asking about height first would call that one Square.
    func testTheFieldRecognisesEachSizeByItsShape() {
        let scene = fieldScene()
        let cell = CGSize(width: scene.brickWidth, height: scene.brickHeight)

        let wanted: [(BrickSize, CGSize)] = [
            (.tiny, CGSize(width: cell.width/2, height: cell.height/2)),
            (.normal, cell),
            (.square, CGSize(width: cell.width, height: cell.height*2)),
            (.big, CGSize(width: cell.width*2, height: cell.height*2)),
        ]
        for (size, extent) in wanted {
            let brick = SKSpriteNode(texture: scene.brickNormalTexture, size: extent)
            brick.position = CGPoint(x: 0, y: 100)
            brick.name = BrickCategoryName
            scene.addChild(brick)
            XCTAssertEqual(scene.endlessIISizeOf(brick), size, "\(size)")
            brick.removeFromParent()
        }
    }

    /// And it is built where it was booked, hanging from the upper cell's centre.
    ///
    /// The node stays on a row centre and the drawing hangs off it, which is the trick a Big
    /// brick uses for the same reason: a brick's `position.y` is its row (§8.6), and the
    /// descent and the bottom-row check both read it.
    func testASquareBrickHangsFromItsRowRatherThanStraddlingIt() {
        let scene = fieldScene()
        let brick = scene.endlessIIMakeSquare(column: 4, rowY: 200)

        XCTAssertEqual(brick.position.y, 200, "the node is on the row it was built for")
        XCTAssertEqual(brick.size.width, scene.brickWidth, accuracy: 0.5)
        XCTAssertEqual(brick.size.height, scene.brickHeight*2, accuracy: 0.5)
        XCTAssertLessThan(brick.frame.midY, brick.position.y,
                          "and the sprite hangs below it, into the row that was reserved")
        XCTAssertEqual(brick.frame.maxY, 200 + scene.brickHeight/2, accuracy: 0.5,
                       "its top edge should sit on the top of its own row")
    }

    /// The size a style can carry is asked of the same rule as everything else.
    func testASquareBrickTakesTheStylesItsShapeAllows() {
        XCTAssertTrue(EndlessIIStyle.moving.suits(BrickSize.square))
        XCTAssertTrue(EndlessIIStyle.gravity.suits(BrickSize.square))
        XCTAssertTrue(EndlessIIStyle.directional.suits(BrickSize.square))

        for style in [EndlessIIStyle.spinning, .breathing, .convex, .diamond] {
            XCTAssertFalse(style.suits(BrickSize.square),
                           "\(style) needs one ordinary centred cell, and this is not one")
        }
    }

    // MARK: - Monolith

    /// A Monolith row is a wall of Big bricks with one channel through it (§6.2).
    ///
    /// **The phase that needed a row to hold more than one shape.** "One enormous Big brick
    /// formation with a narrow route" is four Big bricks abreast on an eleven-column field, and
    /// four abreast is four reservations from one row - which is why this arrived with the
    /// booking list rather than with the other seventeen phases.
    func testAMonolithRowBooksAWallOfBigBricks() {
        let scene = fieldScene()
        scene.endlessIIPhase = .monolith

        let reserving = scene.endlessIIPlanRow()
        let wall = scene.endlessIIPendingBookings
        XCTAssertGreaterThan(wall.count, 1, "one Big brick is Giants, not a monolith")
        XCTAssertTrue(wall.allSatisfy { if case .big = $0.build { return true }
                                        else { return false } },
                      "the wall is Big bricks and nothing else")
        XCTAssertTrue(reserving.builds.isEmpty,
                      "the row that reserves builds nothing - it is the holes")

        let building = scene.endlessIIPlanRow()
        XCTAssertEqual(building.bigs.count, wall.count,
                       "and the next row builds every one of them")
        XCTAssertEqual(building.skip, reserving.skip,
                       "over exactly the cells that were left empty for it")
    }

    /// No two bricks in the wall want the same cell.
    func testTheWallNeverPutsTwoBricksInOnePlace() {
        let scene = fieldScene()
        scene.endlessIIPhase = .monolith
        _ = scene.endlessIIPlanRow()

        var seen: Set<Int> = []
        for booking in scene.endlessIIPendingBookings {
            let wanted = booking.build.columnsToReserve(in: scene.numberOfBrickColumns)
            XCTAssertTrue(wanted.isDisjoint(with: seen), "two bricks want \(wanted)")
            seen.formUnion(wanted)
        }
        XCTAssertLessThan(seen.count, scene.numberOfBrickColumns,
                          "a wall with no way through is a wall, not a route")
    }

    /// The channel is in the same columns for as long as the phase lasts.
    ///
    /// A route that moved from row to row would be a wall with gaps in it rather than a way
    /// through, which is the whole difference between this and a dense stretch of Giants.
    func testTheRouteIsHeldForTheWholePhase() {
        let scene = fieldScene()
        scene.endlessIIPhase = .monolith
        _ = scene.endlessIIPlanRow()
        let route = scene.endlessIIMonolithRoute

        XCTAssertNotNil(route)
        XCTAssertLessThanOrEqual(route?.count ?? 0, 2, "narrow, which is §6.2's word")

        for _ in 0..<20 {
            _ = scene.endlessIIPlanRow()
            XCTAssertEqual(scene.endlessIIMonolithRoute, route)
        }

        for booking in scene.endlessIIPendingBookings {
            let wanted = booking.build.columnsToReserve(in: scene.numberOfBrickColumns)
            XCTAssertTrue(wanted.isDisjoint(with: route ?? []),
                          "a Big brick was booked across the route")
        }
    }

    /// And it is forgotten when the phase ends, so the next one starts somewhere else.
    func testTheRouteGoesWithThePhase() {
        let scene = fieldScene()
        scene.endlessIIPhase = .monolith
        _ = scene.endlessIIPlanRow()
        XCTAssertNotNil(scene.endlessIIMonolithRoute)

        scene.endlessIIPhase = .standard
        scene.endlessIIPendingBookings = []
        _ = scene.endlessIIPlanRow()
        XCTAssertNil(scene.endlessIIMonolithRoute,
                     "a route left behind would put the next monolith's channel where the "
                     + "last one's was")
    }

    /// Every other phase still books one shape to a row.
    ///
    /// The density the mode was play-tested at: more than one roll can come up on a row and
    /// only the first is ever taken. Booking several is a thing a phase asks for, and Monolith
    /// is the only phase that asks.
    func testNoOtherPhaseBooksMoreThanOneShapeToARow() {
        for phase in EndlessIIPhase.allCases where phase != .monolith {
            let scene = fieldScene()
            scene.endlessIIPhase = phase
            for _ in 0..<80 {
                scene.endlessIIPendingBookings = []
                _ = scene.endlessIIPlanRow()
                XCTAssertLessThanOrEqual(scene.endlessIIPendingBookings.count, 1,
                                         "\(phase) booked two shapes into one row")
            }
        }
    }

    // MARK: - A formation driving the sequence

    /// A formation books its Big brick a row before the row it is drawn on.
    ///
    /// Rows are emitted bottom-first (round 249), so the row that reserves comes *out* before
    /// the row the brick is drawn on - which is only possible because the queue holds the whole
    /// shape and can be read one row ahead. A rolled Big brick has to guess a row in advance; a
    /// drawn one is already written down.
    func testAFormationBooksItsBigBrickARowAhead() {
        let scene = fieldScene()
        scene.endlessIISetRowLegend = ["B": EndlessIIBrickSpec(size: .big)]
        scene.endlessIISetRowQueue = ["...........", "..B........"]
        // Emission order: the plain row first - it lands lower - then the row with the brick

        _ = scene.endlessIINextSetRow(reservationPending: false)
        XCTAssertEqual(scene.endlessIIPendingBookings.map(\.build), [.big(leftColumn: 2)],
                       "the row below has to leave the cells empty before the brick arrives")

        _ = scene.endlessIINextSetRow(reservationPending: false)
        let plan = scene.endlessIIPlanRow()
        XCTAssertEqual(plan.bigs.map(\.build.column), [2], "and the row it is drawn on builds it")
        XCTAssertEqual(plan.skip, [2, 3])
    }

    /// A formation asking for a Square brick gets one.
    ///
    /// **This is the test that was missing.** Round 247 added the Square size, round 250 taught
    /// a formation to book a Big brick, and round 251 wrote two formations out of squares -
    /// and nothing joined them up. A `.square` cell validated, built, and came out as an
    /// ordinary oblong, because the booking asked whether the size was Big rather than whether
    /// it was two rows tall. Palisade Post and Hourglass are *about* their squares, and both
    /// were quietly being drawn as plain rows of bricks.
    func testAFormationBooksItsSquareBrickTheSameWay() {
        let scene = fieldScene()
        scene.endlessIISetRowLegend = ["Q": EndlessIIBrickSpec(size: .square)]
        scene.endlessIISetRowQueue = ["...........", "....Q......"]

        _ = scene.endlessIINextSetRow(reservationPending: false)
        XCTAssertEqual(scene.endlessIIPendingBookings.map(\.build), [.square(column: 4)],
                       "a Square brick is two rows tall, so it needs the row below left empty")

        _ = scene.endlessIINextSetRow(reservationPending: false)
        let plan = scene.endlessIIPlanRow()
        XCTAssertEqual(plan.squares.map(\.build.column), [4],
                       "and the row it is drawn on builds it")
        XCTAssertEqual(plan.skip, [4], "one column, because a Square brick is one column wide")
    }

    /// Every size a formation may name is either booked or needs no booking.
    ///
    /// Read off `BrickSize` rather than listed, so a sixth size cannot be added and silently
    /// ignored the way Square was. Tiny is the one that needs nothing: it is one brick split
    /// where it already stands.
    func testEverySizeAFormationCanNameIsAnsweredSomewhere() {
        for size in BrickSize.allCases {
            let scene = fieldScene()
            scene.endlessIISetRowLegend = ["X": EndlessIIBrickSpec(size: size)]
            scene.endlessIISetRowQueue = ["...........", "....X......"]

            _ = scene.endlessIINextSetRow(reservationPending: false)
            switch size {
            case .tiny, .normal:
                XCTAssertTrue(scene.endlessIIPendingBookings.isEmpty,
                              "\(size) fits in the row it is drawn on")
            case .big, .square:
                XCTAssertFalse(scene.endlessIIPendingBookings.isEmpty,
                               "\(size) is taller than a row, so it has to be booked ahead")
            }
        }
    }

    /// The brick a formation booked wears what the formation asked for.
    ///
    /// A Big or Square brick is built by its own function from the field's own mix, which is
    /// right for a rolled one and wrong for a drawn one: without this a formation asking for a
    /// multi-hit Big brick got a standard one, with nothing anywhere to say it had not.
    func testABookedShapeCarriesItsFormationsSpec() {
        let scene = fieldScene()
        let asked = EndlessIIBrickSpec(behaviour: .multiHit, size: .big)
        scene.endlessIISetRowLegend = ["B": asked]
        scene.endlessIISetRowQueue = ["...........", "..B........"]

        _ = scene.endlessIINextSetRow(reservationPending: false)
        XCTAssertEqual(scene.endlessIIPendingBookings.first?.spec, asked,
                       "the booking carries the legend, or the brick is built from the mix")

        let brick = scene.endlessIIMakeBig(leftColumn: 2, rowY: 0)
        scene.endlessIIDressBookedShape(brick, as: scene.endlessIIPendingBookings.first?.spec)
        XCTAssertEqual(brick.texture, scene.brickMultiHit3Texture,
                       "a multi-hit Big brick has to look like one")
        XCTAssertTrue(brick.endlessIIStaysPlain,
                      "and the generator's own styling passes leave a designed brick alone")
    }

    /// The generator's own roll carries no legend.
    ///
    /// A spec left lying around would dress the next rolled shape in whatever the last
    /// formation asked for, which is a Big brick that is multi-hit for no reason a player
    /// could see.
    func testARolledShapeIsNeverDressedByAFormation() {
        let scene = fieldScene()
        scene.endlessIIPendingBookings = []

        var rolled: EndlessIIBooking?
        for _ in 0..<400 where rolled == nil {
            _ = scene.endlessIIPlanRow()
            rolled = scene.endlessIIPendingBookings.first
            if rolled != nil { break }
            scene.endlessIIPendingBookings = []
        }
        // The candidates are rolled, so this asks until one comes up rather than assuming it
        // does on the first row

        XCTAssertNotNil(rolled, "400 rows without a single shape means the chances have gone")
        XCTAssertNil(rolled?.spec, "a rolled shape is a size and nothing else")
    }

    /// It does not book one over a reservation the generator has already made.
    ///
    /// A row either reserves or builds, and the generator's own roll for this row has happened
    /// by the time a formation row is asked for. The formation gives way: one brick missing
    /// from a shape beats two shapes arranging the same cells and neither surviving.
    func testAFormationGivesWayToAReservationAlreadyMade() {
        let scene = fieldScene()
        scene.endlessIISetRowLegend = ["B": EndlessIIBrickSpec(size: .big)]
        scene.endlessIISetRowQueue = ["...........", "..B........"]
        scene.endlessIIPendingBookings = [EndlessIIBooking(.spinner(column: 7))]

        _ = scene.endlessIINextSetRow(reservationPending: false)
        XCTAssertEqual(scene.endlessIIPendingBookings.map(\.build), [.spinner(column: 7)],
                       "the spinner was booked first and keeps the row")
    }

    /// And it never books one that would hang off the edge of the field.
    func testAFormationsBigBrickHasToFitTheField() {
        let scene = fieldScene()
        scene.endlessIISetRowLegend = ["B": EndlessIIBrickSpec(size: .big)]
        scene.endlessIISetRowQueue = ["...........", "..........B"]

        _ = scene.endlessIINextSetRow(reservationPending: false)
        XCTAssertTrue(scene.endlessIIPendingBookings.isEmpty,
                      "a Big brick in the last column has no second column to fill")
    }

    /// A power-up brick is not even reserved while one is still in play.
    ///
    /// The row that reserves is a row with a hole in it, and holding one open for a brick that
    /// will not be built is worse than not offering one.
    func testNoPowerUpBrickIsReservedWhileOneIsInPlay() {
        let scene = fieldScene()
        let inPlay = SKSpriteNode()
        inPlay.name = BrickCategoryName
        inPlay.endlessIIPowerUpIndex = 0
        scene.addChild(inPlay)
        // The list is derived from the field rather than held, so one is put *in* the field -
        // which is also the honest version of the question being asked
        XCTAssertEqual(scene.endlessIIPowerUpBricksInPlay.count, 1)

        for _ in 0..<200 {
            scene.endlessIIPendingBookings = []
            _ = scene.endlessIIPlanRow()
            if scene.endlessIIPendingBookings.contains(where: {
                if case .powerUpBrick = $0.build { return true } else { return false }
            }) {
                return XCTFail("a second power-up brick was booked while one was in play")
            }
        }
    }
}
