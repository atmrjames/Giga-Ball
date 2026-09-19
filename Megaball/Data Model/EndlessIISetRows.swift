//
//  EndlessIISetRows.swift
//  Megaball
//
//  Rows somebody designed, among rows nobody did.
//
//  Everything else about the field is drawn from weights, and weighted randomness is very
//  good at producing fields that are different from each other and bad at producing fields
//  that mean anything. A row that was arranged on purpose reads completely differently: a
//  wall with one gap in it is a shot to find, where the same number of bricks scattered is
//  just a number of bricks.
//
//  They are rare and short for exactly the reason phases are - the moment a designed shape
//  becomes the norm it stops being a landmark and starts being the wallpaper.
//

import Foundation

/// One designed run of one to three rows.
///
/// Written out as text because that is the form a person can actually read and edit. Each
/// character is a column, **top row first** - the first row here is the one that ends up
/// highest on screen, which is what a person drawing a shape expects and what the queue
/// finally does since round 249.
///
///     .  empty        N  ordinary brick     M  multi-hit
///     i  indestructible x1                  I  indestructible x2
///     ?  whatever the generator would have put there anyway
struct EndlessIISetRow {
    let name: String
    let rows: [String]
    /// The height below which this one does not appear.
    let minimumHeight: Int
    /// What this pattern's own characters mean, for the shapes that need more than the six
    /// above (`EndlessIIBrickSpec`). Empty on every pattern written before round 238, which
    /// is why it has a default: the shared alphabet answers everything they draw with.
    let legend: [Character: EndlessIIBrickSpec]

    init(name: String, rows: [String], minimumHeight: Int,
         legend: [Character: EndlessIIBrickSpec] = [:]) {
        self.name = name
        self.rows = rows
        self.minimumHeight = minimumHeight
        self.legend = legend
    }

    /// How wide the patterns are written for. A field of a different width is padded with
    /// empties rather than being stretched, so a shape stays the shape it was drawn as.
    static let designedForColumns = 11

    static let all: [EndlessIISetRow] = [
        EndlessIISetRow(name: "Comb", rows: ["I.INI.INI.I"], minimumHeight: 150),
        // The alternating indestructible row that already existed, written down. Pushed
        // deep after play-testing: it is one of the hardest shapes in the pool, and it was
        // arriving in the opening minutes.
        //
        // **Two of its gaps carry an ordinary brick now** (round 194). James's maze note -
        // "dotted with normal bricks so they don't just fly by" - was written about new
        // shapes, and the rule it implies condemned this one: a row of nothing but
        // indestructibles is a wall the ball rattles off with nothing to earn, and it
        // descends past as a tax on time. Three gaps are still open, so it is no harder to
        // get through than it was; what changed is that going through it is now worth
        // something. The test that found this holds for anything heavy added later

        EndlessIISetRow(name: "Gate", rows: ["NNNNN.NNNNN"], minimumHeight: 30),
        // A wall with one way through. The whole row is one shot

        EndlessIISetRow(name: "Funnel", rows: ["NN.......NN",
                                               ".NN.....NN.",
                                               "..NN...NN.."], minimumHeight: 90),
        // Wide at the top and narrowing to one gap at the bottom, which is what a funnel is.
        // The ball meets the narrow end first and opens out into room once it is through.
        //
        // **Its comment said the opposite until round 249**, and it was right about what the
        // field was drawing: the queue was laying every formation out upside down, so this one
        // really did open downward. It is the shape that made the bug hard to see, because a
        // funnel the wrong way up is still a funnel

        EndlessIISetRow(name: "Pillars", rows: ["I..I..I..I.",
                                                "N..N..N..N."], minimumHeight: 120),
        // Indestructible posts with ordinary bricks hanging off them

        EndlessIISetRow(name: "Chequer", rows: ["N.N.N.N.N.N",
                                                ".N.N.N.N.N."], minimumHeight: 60),

        EndlessIISetRow(name: "Vault", rows: ["IIIIIIIIIII",
                                              "..MMMMMMM..",
                                              "....NNN...."], minimumHeight: 200),
        // An indestructible lid over something worth getting at

        EndlessIISetRow(name: "Split", rows: ["NNNNN.NNNNN",
                                              "....I.I...."], minimumHeight: 150),
        // The gap from the row above is guarded once you are through it

        EndlessIISetRow(name: "Steps", rows: ["N.........N",
                                              ".N.......N.",
                                              "..N.....N.."], minimumHeight: 70),

        EndlessIISetRow(name: "Shoal", rows: ["?.?.?.?.?.?"], minimumHeight: 0),
        // The opening set row now the Comb has gone deep - designed spacing, undesigned
        // contents, and nothing about it punishes a new player
        // Designed spacing, undesigned contents - a shape that still varies

        EndlessIISetRow(name: "Keep", rows: ["..IIIII....",
                                             "..I???I....",
                                             "..IIIII...."], minimumHeight: 250),
        // Something walled in. Reachable only once the walls have been dealt with

        // MARK: Rows that are made of something (round 240)
        //
        // The eleven above are drawn from the four brick kinds the shared alphabet reaches. A
        // legend lets a row be made of a *shape* or an *action*, which is a different kind of
        // landmark: the Palisade is not a wall with a gap, it is a wall that answers every hit
        // the same way.

        EndlessIISetRow(name: "Palisade", rows: ["WWWWWWWWWWW"], minimumHeight: 100,
                        legend: ["W": EndlessIIBrickSpec(behaviour: .standard, shape: .wedge,
                                                         mirrored: true)]),
        // A full row of slopes all facing the same way. Anything reaching it leaves in the same
        // direction whatever angle it arrived at, so the row is a redirection rather than an
        // obstacle - and it is a shot worth setting up rather than one to get through

        EndlessIISetRow(name: "Ripple", rows: ["VCVCVCVCVCV"], minimumHeight: 130,
                        legend: ["V": EndlessIIBrickSpec(behaviour: .standard, shape: .convex),
                                 "C": EndlessIIBrickSpec(behaviour: .standard,
                                                         shape: .concave)]),
        // Domes and dishes alternating. Each dome throws a shot wider and each dish gathers it
        // back, so a ball working along the row is passed between two opposite answers

        EndlessIISetRow(name: "Drawbridge", rows: ["DDDD.DDDDDD",
                                                   "?????.?????"], minimumHeight: 150,
                        legend: ["D": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.directional],
                                                         side: .bottom)]),
        // A wall with one gap that only takes damage from below, over a row with its gap
        // somewhere else. Going through the top is one shot; taking the top apart is a rally

        EndlessIISetRow(name: "Shingle", rows: ["ttttttttttt"], minimumHeight: 110,
                        legend: ["t": EndlessIIBrickSpec(behaviour: .standard, size: .tiny)]),
        // A full row of quarter-cell bricks: forty-four of them where eleven would be, each
        // worth a hit and none of them worth aiming at. It comes apart a quarter at a time, so
        // the row thins rather than opening

        EndlessIISetRow(name: "Trawl", rows: ["mmm.mmm.mmm"], minimumHeight: 170,
                        legend: ["m": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.moving])]),
        // Three groups of wanderers with gaps between them. They set off into the gaps the
        // moment the row arrives, so the shape starts as a design and becomes a field

        EndlessIISetRow(name: "Rockfall", rows: ["g.g.g.g.g.g",
                                                 "...........",
                                                 "?.?.?.?.?.?"], minimumHeight: 200,
                        legend: ["g": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.gravity])]),
        // Six fallers over an empty row over six ordinary bricks. The top row lands on the
        // bottom one and the shape closes itself, so what looks like three rows of room is one
        // row of bricks arriving in two stages

        // MARK: The mazes
        //
        // James, round 190: "Mazes of indestructible bricks dotted with normal bricks so they
        // don't just fly by." The dotting is the whole design. A maze of nothing but
        // indestructibles is a wall that descends past with nothing to earn from it - the ball
        // rattles off it and the row is a tax on time. The ordinary bricks inside are what
        // make a player want to get in there, and what makes the shape worth the risk of
        // spending a rally in it.
        //
        // Three rows each, like everything else here: longer and it stops being a landmark
        // punctuating the field and becomes the field. §6.2's Fortress phase is where a
        // longer stretch of this character belongs.

        EndlessIISetRow(name: "Catacomb", rows: ["I.I.I.I.I.I",
                                                 ".N.N...N.N.",
                                                 "I.I.I.I.I.I"], minimumHeight: 110),
        // The lightest of them: posts above and below with ordinary bricks in the aisles.
        // Open from either side, so it can be worked at rather than solved in one go

        EndlessIISetRow(name: "Warren", rows: ["I.IIIII.I.I",
                                               "I.N...N.N.I",
                                               "..I.I.I.I.."], minimumHeight: 190),
        // Pockets reachable from below. The bottom row is the way in and the middle is what
        // there is to get; the lid is mostly closed, so what goes in has to come back out

        EndlessIISetRow(name: "Bastion", rows: ["IIII.I.IIII",
                                                "I.N.....N.I",
                                                "II..I.I..II"], minimumHeight: 280),
        // The heaviest, and the deepest gated. Two ways in at the bottom, two bricks worth
        // having, and a lid with a pair of slots that a ball has to be aimed at

        // MARK: The drafted eleven (rounds 284 and 286)
        //
        // James, round 284: "please start to draft sequences and I can play test them" - the
        // heading §12.0 has been holding open since round 190. These are a first pass and are
        // meant to be argued with.
        //
        // The one rule behind the choice of them: **each is made of something the catalogue
        // had never been made of.** The twenty-two above draw on four brick kinds, four shapes,
        // one size and three actions, and the field around them has five behaviours, four
        // shapes, four sizes and fifteen styles. So there was no designed row anywhere that was
        // Multi-hit, that breathed, that turned, that exploded, that could not be seen, that
        // refilled itself or that went anywhere - and a landmark is worth having precisely
        // because it is the one row in a run that is unmistakably *about* something.
        //
        // Gated shallow to deep in roughly the order a player can be expected to cope: the
        // ones that only need looking at come first, the ones that need a plan come last.
        //
        // **Nine of them at first, and two more once a caution turned out to be unfounded.**
        // Round 284 left Big and Square out on the grounds that no formation used either and
        // so no convention existed for what the cells a two-row brick hangs into should say.
        // The convention was there the whole time and four clusters obey it - Millstone and
        // Keepsake among them - and it is the obvious one: the character goes in the top-left
        // cell the brick occupies and every other cell it fills is written empty. Colonnade and
        // Rampart are the two that were owed.

        EndlessIISetRow(name: "Seam", rows: ["MMM.MMM.MMM"], minimumHeight: 60),
        // Three blocks of Multi-hit with two gaps, and the shallowest of the nine because it
        // asks for nothing but persistence. Multi-hit is in the shared alphabet and no set row
        // has ever used it: twenty-two designed rows and not one of them was made of the brick
        // that takes four hits. The gaps are the point - a wall of these with no way through
        // would be a wait rather than a shape

        EndlessIISetRow(name: "Bellows", rows: ["bbbbbbbbbbb"], minimumHeight: 120,
                        legend: ["b": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.breathing])]),
        // A solid row with no gap in it at all, which every other wall here would call unfair.
        // It is passable because it breathes: each brick shrinks to half a cell and swells back
        // (§4.12), so the row opens gaps all along itself and closes them again, out of step
        // with its neighbours. The shot is timed rather than aimed, which nothing else in the
        // pool asks for

        EndlessIISetRow(name: "Chevron", rows: ["WWWWW.EEEEE"], minimumHeight: 140,
                        legend: ["W": EndlessIIBrickSpec(behaviour: .standard, shape: .wedge,
                                                         mirrored: true),
                                 "E": EndlessIIBrickSpec(behaviour: .standard, shape: .wedge,
                                                         mirrored: false)]),
        // The Palisade's answer to the obvious question about it. That row sends everything one
        // way; this one has the two halves facing each other, so both sides feed the gap in the
        // middle. A ball anywhere along it is being returned towards the one column that is
        // open, which makes it the first shape in the pool that helps

        EndlessIISetRow(name: "Lattice", rows: ["dNdNdNdNdNd"], minimumHeight: 140,
                        legend: ["d": EndlessIIBrickSpec(behaviour: .standard,
                                                         shape: .diamond)]),
        // Rhombi alternating with ordinary bricks. A diamond has no flat face, so every hit
        // leaves at a diagonal - a ball that gets into this row is passed along it from one
        // rhombus to the next rather than being sent back out, and the ordinary bricks between
        // them are what it collects on the way. The one shaped face with no designed row of its
        // own

        EndlessIISetRow(name: "Orrery", rows: ["...........",
                                               ".s...s...s."], minimumHeight: 160,
                        legend: ["s": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.spinning])]),
        // Three turning bricks, spaced four columns apart, under a row left deliberately empty.
        // **The empty row is not decoration**: a spinner sweeps a circle wider than its own
        // cell, and the generator books it clearance above for that reason - a formation cannot
        // ask the row above it for anything, because that row was built before this one was
        // drawn, so the shape has to carry its own room. Mostly gap and still hard to cross,
        // because the gaps are turning

        EndlessIISetRow(name: "Magazine", rows: ["???X???X???"], minimumHeight: 170,
                        legend: ["X": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.exploding])]),
        // Two charges buried in a row of whatever the field was making anyway. It is the only
        // shape here that is worth *more* than the bricks in it: find either charge and the row
        // opens around it. Undesigned contents on purpose - a charge is interesting because of
        // what is packed round it, and what is packed round it should differ every time

        EndlessIISetRow(name: "Mirage", rows: ["vNv.vNv.vNv"], minimumHeight: 190,
                        legend: ["v": EndlessIIBrickSpec(behaviour: .invisible)]),
        // The mazes' dotting rule applied to a row that cannot be seen rather than one that
        // cannot be broken. Six invisible bricks with three ordinary ones standing among them:
        // the visible bricks say where the row *is*, and everything either side of one is a
        // brick you have found rather than a brick you can see. Nothing but invisibles would be
        // a row that is only discovered by being bounced off, which is the same complaint
        // James made about the Comb

        EndlessIISetRow(name: "Wellspring", rows: [".....p....."], minimumHeight: 210,
                        legend: ["p": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.spawner])]),
        // One brick, alone in an empty row. It is the emptiest formation in the catalogue and
        // the only one that fills itself in: a spawner refills the cells around it, so what
        // arrives as a single brick becomes a patch of field unless it is dealt with while it
        // is still one brick. Gated deep because a player who ignores it is worse off than
        // one who never met it, which is not a thing to hand somebody in their first minutes

        EndlessIISetRow(name: "Colonnade", rows: ["Q.Q.Q.Q.Q.Q",
                                                  "..........."], minimumHeight: 130,
                        legend: ["Q": EndlessIIBrickSpec(behaviour: .standard, size: .square)]),
        // Six bricks one cell wide and two rows deep, with a full-height gap between each.
        // **It is the Comb turned ninety degrees**: every other row here blocks a row, and a
        // Square brick blocks a *column*, so what this leaves open is six corridors rather than
        // six gaps. The row below is written empty because that is where each brick hangs down
        // to - the rule every formation with a two-row shape in it obeys

        EndlessIISetRow(name: "Rampart", rows: ["B...B...B..",
                                                "..........."], minimumHeight: 200,
                        legend: ["B": EndlessIIBrickSpec(behaviour: .standard, size: .big)]),
        // Three blocks two cells across and two rows deep, with two clear cells between them.
        // The heaviest thing in the pool by area and still ordinary bricks: a wall of Big
        // Indestructibles would be the maze problem again, where this is simply a lot of brick
        // to get through and worth the points for doing it. The six cells each block hangs into
        // are drawn empty, as above

        EndlessIISetRow(name: "Conduit", rows: ["p?.?.?.?.?p"], minimumHeight: 240,
                        legend: ["p": EndlessIIBrickSpec(behaviour: .indestructibleAlways,
                                                         actions: [.portal])]),
        // A portal at each end of the field with a scattering of ordinary bricks between them.
        // Indestructible because a portal has to be (`suits`): it is struck rather than
        // damaged, so the behaviour that means "a hit does nothing" is the only one it can
        // wear. What it does to the row is turn the two walls into each other - a ball
        // travelling out of the field on one side arrives travelling out of it on the other,
        // which is either a rally that never ends or a way of getting behind the row, depending
        // entirely on how it is set up. The deepest gated of the nine, and the one most likely
        // to come back from a play test wanting a different pair of columns

        // MARK: - Round 329's eight

        // James, round 329: "create some new brick layout designs for Endless Mayhem mode of
        // different types, shapes, using different bricks, etc." Written to fill the gaps the
        // thirty above leave rather than to add more of what is already there: two shapes that
        // had no designed row, three actions that had only one apiece, and three formations
        // that are about the *arrangement* rather than about any one brick.

        EndlessIISetRow(name: "Ratchet", rows: ["WEWEWEWEWEW"], minimumHeight: 110,
                        legend: ["W": EndlessIIBrickSpec(behaviour: .standard, shape: .wedge,
                                                         mirrored: true),
                                 "E": EndlessIIBrickSpec(behaviour: .standard, shape: .wedge,
                                                         mirrored: false)]),
        // Wedges alternating the way they face, which Palisade and Chevron each do half of -
        // one is a row all facing the same way, the other is two halves meeting in the middle.
        // Alternating every column makes a row with no flat face anywhere along it: whichever
        // cell the ball meets, it leaves at an angle, and the angle reverses cell to cell. The
        // shallowest of the eight, because a row that scatters the ball is punishment enough
        // early on without anything else in it

        EndlessIISetRow(name: "Cradle", rows: ["CCCCCCCCCCC"], minimumHeight: 150,
                        legend: ["C": EndlessIIBrickSpec(behaviour: .standard, shape: .concave)]),
        // The concave face had no row of its own - Ripple alternates it with convex, where the
        // two cancel. A whole row of scoops does the opposite of Palisade: a wedge throws the
        // ball off, a scoop gathers it back toward the middle of the cell it struck, so this
        // row hands the ball back rather than away. Worth a row on its own because it is the
        // one shaped face that makes a rally *easier*, and the field is allowed to be kind
        // sometimes

        EndlessIISetRow(name: "Trestle", rows: ["MMMMMMMMMMM",
                                               "...NNNNN...",
                                               "....N.N...."], minimumHeight: 240,
                        legend: [:]),
        // Heavy across the top, narrowing to two legs. The multi-hit lid means the shape cannot
        // be opened from above in one pass, so the way in is up through the legs and into the
        // pocket between them - and the pocket is the point: a ball that gets inside has the
        // lid above it and a leg either side, which is the best few seconds of scoring the mode
        // offers. Deep, because a ball that goes in can also come straight back down the middle

        EndlessIISetRow(name: "Cage", rows: ["I.........I",
                                             "I.MMMMMMM.I",
                                             "I.........I"], minimumHeight: 320,
                        legend: [:]),
        // Six indestructible posts down the two edges with a multi-hit bar strung between them,
        // and the rows above and below it left open. Everything here is about the *columns*:
        // the posts make the outside lanes unplayable for three rows, so the field is
        // temporarily nine columns wide, and the bar is the only thing in it worth hitting.
        // The deepest of the eight - it takes the walls away, which is the one thing a player
        // always has

        EndlessIISetRow(name: "Avalanche", rows: ["gggg.ggg.gg"], minimumHeight: 260,
                        legend: ["g": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.gravity])]),
        // A row that falls. Rockfall spaces its fallers out; this one is nearly solid, so what
        // drops is a sheet rather than a handful - and what it drops *onto* is whatever the
        // generator made underneath, which is how a designed row gets to rearrange an
        // undesigned one. The two gaps are deliberate: a solid row of fallers lands as a solid
        // row, and the holes are what make the landing uneven enough to be interesting

        EndlessIISetRow(name: "Rookery", rows: ["..p.....p..",
                                                 ".NNN...NNN."], minimumHeight: 300,
                        legend: ["p": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.spawner])]),
        // Two spawners, each sitting over three ordinary bricks. Clearing the three underneath
        // is what makes room for the spawner above to refill them, so the shape rewards leaving
        // the spawner alone and punishes clearing around it - the opposite way round from
        // everything else in the field, where the dangerous brick is the one to leave. Break
        // the spawner first and the row is three bricks and a gap; break the bricks first and
        // it is a job

        EndlessIISetRow(name: "Fuse", rows: ["X.N.X.N.X.N"], minimumHeight: 250,
                        legend: ["X": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.exploding])]),
        // Four charges spaced two columns apart with ordinary bricks between them. Magazine
        // buries one charge in a row nobody designed; this one is the charges *and* the spacing,
        // so that each blast reaches the bricks either side of it and stops short of the next
        // charge. It is a row that can be cleared in four hits by a player who knows what it is
        // and in eleven by one who does not, which is exactly the kind of thing a designed row
        // is for

        EndlessIISetRow(name: "Comet", rows: ["s.........s",
                                               "...........",
                                               "....s.s...."], minimumHeight: 200,
                        legend: ["s": EndlessIIBrickSpec(behaviour: .standard,
                                                         actions: [.spinning])]),
        // Four spinners falling inward, two wide and two near the middle, with the row between
        // them left empty for the clearance a spinner needs - the same booking Orrery makes and
        // for the same reason: a formation cannot ask the row above it for room, because that
        // row was built before this one was drawn. What the arrangement adds is a *gradient*:
        // the outer pair are reachable from the wall lanes, the inner pair only from the middle
    ]

    /// The ones allowed at this height.
    static func available(at height: Int) -> [EndlessIISetRow] {
        all.filter { height >= $0.minimumHeight }
    }

    /// What belongs in a column of one of this pattern's rows.
    ///
    /// Anything outside the written width is empty, so a narrower or wider field leaves the
    /// shape alone rather than distorting it.
    static func character(in row: String, column: Int) -> Character {
        let characters = Array(row)
        guard column >= 0, column < characters.count else { return "." }
        return characters[column]
    }
}
