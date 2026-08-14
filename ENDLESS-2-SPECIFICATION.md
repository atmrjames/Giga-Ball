# Endless Mayhem — design specification

**Status: built.** Every mechanic in this document exists - the phases in §12 are all
complete, and §12.0 records what each one turned into, including where play-testing
overruled the design written here. What remains is §8.5's asset list and the Quick Start
Guide, neither of which is code. This began as a design document, unlike
[SPECIFICATION.md](SPECIFICATION.md), which describes the app as it stands; it is now
equal parts design record and build log, and the sections written to stop mistakes being
repeated (§8.6, §12.0's play-test notes) are the ones that keep earning their place.

The mode shipped under the name **Endless Mayhem**; the code and this document's internal
references say `endlessII`, which is the identifier history and not worth churning.

**What this is:** the design for a new game mode, added alongside the existing Classic and
Endless modes rather than replacing either.

**What it is for:** the existing Endless Mode is a single idea executed once — rows
descend, density rises, you climb until you drop the ball. It is a good idea, and players
have years of scores on its leaderboards. But it runs out of new things to show a player
within a couple of minutes, and everything it *could* show is gated behind height most
players never reach. Endless II keeps the shape and makes variety the point.

---

## 1. Constraints

- **The existing Endless Mode does not change.** Same rules, same generation, same
  leaderboards, same achievements, same place on the main menu.
- **New leaderboards and achievements.** Endless II scores are not comparable, so they do
  not share a board.
- **The play zone keeps its fixed 1.8236 aspect ratio**, as everywhere else.
- **Additive only.** Every existing brick type and power-up behaves identically in Endless
  II. Nothing existing is rebalanced to suit the new mode.
- **Improvements flow forward.** Future work on shared mechanics — physics, scoring,
  paddle, save format — applies to all three modes. Only *new* Endless II features are
  exclusive to it.
- **No monetisation, no ads, no data collection.**

---

## 2. Design pillars

**Variety over escalation.** The existing mode's only axis is *harder*. This one's main
axis is *different*.

**Reachable novelty.** Rare elements stay rare, but rarity must not mean *deep*. A player
who never gets far still meets them (§6.2).

**The drop rate does not go up.** Power-ups fall no more often than today. The variety is
in *which* ones fall.

**Interactions are the fun.** Power-ups should combine wherever combining is coherent.
Mutual exclusion is the exception, not the model (§5.1).

**Legibility.** A player must be able to tell what just happened.

**Extensibility is a feature, not a nicety.** Brick types, power-ups, phases and
backgrounds will keep being added. Each must be a data entry plus its own behaviour, never
an edit to a shared switch. This is the single most important constraint on how §8 is
built — see §8.4.

**Fun is a play-test question.** This document settles what gets built so it can be judged.

---

## 3. What carries over

All existing brick types (Normal, Multi-hit, Indestructible ×2, Invisible) and all 28
existing power-ups, unchanged. Paddle, ball, physics, multiplier and scoring rules as in
[SPECIFICATION.md §4](SPECIFICATION.md).

**Lives.** One, as in Endless. **Score.** Height in metres, as in Endless.

---

## 4. Brick types

### 4.0 Two axes: behaviour and style

A brick is described by two independent things, and **any behaviour can carry any style**.

**Behaviour** is what happens when the ball arrives — the axis the game has always had, and
the one every existing level is built from. **Style** is everything else: what the brick
looks like, where it sits, whether it moves, and what it does to the field around it. Style
is entirely new to Endless 2.0.

Splitting them this way is what makes a spinning Indestructible brick possible, and a
spinning Indestructible brick is chaos of exactly the right kind: an obstacle you cannot
remove, presenting a different angle every time the ball reaches it.

**Behaviours** (existing, unchanged)

| Behaviour | What a hit does |
|---|---|
| Standard | Destroyed. Carries a colour, which affects its score |
| Multi-hit | Four stages; each hit steps it down, the fourth destroys it |
| Indestructible ×1 | Becomes Indestructible ×2 |
| Indestructible ×2 | Nothing. Cleared only by Zap, Wrecking Ball or an explosion. Giga-Ball passes straight through one but leaves it standing |
| Invisible | Solid but not drawn until struck, then behaves as Standard |

**Styles** (new)

| Style | What it adds | §  |
|---|---|---|
| Plain | Nothing. What every brick in Classic and Endless is | — |
| Rounded | Rounded-rectangle body, so glancing hits deflect unpredictably | 4.5 |
| Convex | A dome. Off-centre hits leave wider than they arrived — it scatters | 4.12 |
| Concave | A dish. Hits near an edge are turned back inward — it collects | 4.12 |
| Wedge | A right triangle. Everything reaching the slope leaves the same way | 4.12 |
| Spinning | Rotates on the spot; the bounce angle changes with it | 4.1 |
| Flashing | Alternates solid-and-visible with passable-and-faded | 4.2 |
| Gravity | Falls into empty cells below it | 4.6 |
| Moving | Wanders within a reserved region | 4.8 |
| Directional | Only takes its behaviour's damage from one side | 4.7 |
| Exploding | Destroys its eight neighbours when destroyed | 4.9 |
| Spawner | Fills its empty neighbours when destroyed | 4.10 |
| Portal | Sends the ball elsewhere; never damaged | 4.11 |

**Size** is a third, smaller axis that combines with both. It is separate because it changes
how much of the field a brick occupies rather than what it is.

| Size | Occupies |
|---|---|
| Tiny | A quarter cell — half width, half height |
| Normal | One cell |
| Big | 2×2 cells |

### 4.0.1 Which combinations work

Most do. The ones that do not are the ones where the style and the behaviour contradict
each other rather than the ones that are merely strange.

| Style | Standard | Multi-hit | Indest. ×1 | Indest. ×2 | Invisible |
|---|---|---|---|---|---|
| Rounded | ✓ | ✓ | ✓ | ✓ | ✓ |
| Convex | ✓ | ✓ | ✓ | ✓ | ✗ ⁷ |
| Concave | ✓ | ✓ | ✓ | ✓ | ✗ ⁷ |
| Wedge | ✓ | ✓ | ✓ | ✓ | ✗ ⁷ |
| Spinning | ✓ | ✓ | ✓ | ✓ | ✓ |
| Fixed | ✓ | ✓ | ✓ | ✗ ² | ✓ |
| Flashing | ✓ | ✓ | ✓ | ✓ | ✗ ¹ |
| Gravity | ✓ | ✓ | ✓ | ✓ | ✓ |
| Moving | ✓ | ✓ | ✓ | ✓ | ✓ |
| Directional | ✓ | ✓ | ✓ | ✗ ² | ✓ |
| Exploding | ✓ | ✓ | ✓ | ✓ ⁶ | ✓ |
| Spawner | ✓ | ✓ | ✓ | ✓ ⁶ | ✓ |
| Portal | ✗ ³ | ✗ ³ | ✗ ³ | ✓ | ✗ ³ |

1. Both are about whether the brick can be seen. A brick that is invisible until struck and
   also fades in and out has no readable state.
2. Directional describes how a brick is destroyed. On one that never is, there is nothing
   for it to describe.
3. A Portal is struck rather than damaged, so its behaviour has to be the one that already
   means "a hit does nothing". Building it on Indestructible ×2 is not a limitation — it is
   what makes the rest of the game treat it correctly for free.
6. **These fire on every hit rather than on destruction.** On any other behaviour they go off
   once, when the brick dies. On one that never dies that moment never comes, so contact is
   the trigger instead — a brick that clears its neighbours each time you hit it, or one that
   keeps refilling them. Both are self-limiting: an explosion with nothing beside it does
   nothing, and a Spawner only fills cells that are empty.
7. A shaped face is something to aim off deliberately, and an Invisible brick is not drawn
   until it has been struck. A slope nobody can see answers the shot before the player knows
   it is there.

**Sizes** combine with every behaviour and every style, with two exceptions: a Big brick
cannot be Spinning, because the clearance a full-size brick needs to turn is already two
cells in each direction and a Big one would need four; and the three shaped faces are
Normal-size only, because a face is built from the brick's own size and drawn about its
node, which holds only for a brick that is one cell sitting centred.

### 4.0.2 Stacking two styles

A brick may carry more than one style where the two do not fight over the same thing. An
Indestructible brick that is rounded *and* spinning is the example worth building for: you
cannot remove it, it presents a different angle every time, and the angles it presents are
ones a rectangle never would.

What decides it is what each style owns. Two styles that both rewrite a brick's shape, or
both decide whether it is solid, or both move it, cannot be combined — the second would
simply undo the first.

| | Rounded | Spinning | Flashing | Gravity | Moving | Directional | Exploding | Spawner | Portal |
|---|---|---|---|---|---|---|---|---|---|
| **Rounded** | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Spinning** | ✓ | — | ✓ | ✓ | ✗ ¹ | ✗ ² | ✓ | ✓ | ✓ |
| **Flashing** | ✓ | ✓ | — | ✓ | ✓ | ✗ ³ | ✓ | ✓ | ✗ ⁴ |
| **Gravity** | ✓ | ✓ | ✓ | — | ✗ ¹ | ✓ | ✓ | ✓ | ✓ |
| **Moving** | ✓ | ✗ ¹ | ✓ | ✗ ¹ | — | ✗ ² | ✓ | ✓ | ✓ |
| **Directional** | ✓ | ✗ ² | ✗ ³ | ✓ | ✗ ² | — | ✓ | ✓ | ✗ ⁴ |
| **Exploding** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | — | ✗ ⁵ | ✗ ⁴ |
| **Spawner** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ ⁵ | — | ✗ ⁴ |
| **Portal** | ✓ | ✓ | ✗ ⁴ | ✓ | ✓ | ✗ ⁴ | ✗ ⁴ | ✗ ⁴ | — |

1. Both want to say where the brick is. Two things moving one brick is one of them losing.
2. A Directional brick's vulnerable side has to be findable. On something that turns or
   slides, "the left side" is not a thing the player can aim at.
3. Same reason from the other end: a brick that keeps vanishing cannot also be asking you to
   read which of its edges is the soft one.
4. Portal is never damaged and never destroyed, so anything about being destroyed or about
   being solid has nothing to attach to.
5. Both fire on destruction and do opposite things — one clears the neighbourhood, the other
   fills it. Whichever ran second would decide, which is not a rule anyone could read.

**How many.** Two at most. Three is not ruled out by the grid, but a brick doing three
things is one nobody can read at a glance, and legibility is what makes the combinations fun
rather than noisy.

### 4.1 Spinning
Rotates continuously, one direction or the other, at a fixed rate. It keeps the shape of an
ordinary brick — the turning is only interesting because the thing turning is oblong, and a
brick shrunk to a square to make room reads as a different kind of brick rather than as a
familiar one behaving strangely.

The body turns with it, so the bounce genuinely changes with the angle. That is the point of
the brick.

**Clearance:** a brick twice as wide as it is tall sweeps a circle of radius ≈1.12 cells as
it turns, so it needs the cell above, the cell below and both side cells left empty. The
generator commits to this across three rows: the row below is left empty, the spinner is
placed in the next row with its side cells empty, and the row after leaves the cell above
empty.

### 4.2 Flashing
Alternates between solid-and-visible and passable-and-invisible. **The transition is fast**
— a quick fade, not a slow one — so its state is never ambiguous, and it **holds each state
for a few seconds**. Styled like the Giga-Ball glow, yellow-green.

Solid only while visible. If the ball overlaps the cell at the moment it would turn solid,
the brick stays passable until the ball has left, so it can never trap the ball.

### 4.3 Big and 4.4 Tiny
Sizes rather than types (see the table above), so they combine with any type. Big occupies
2×2 cells, Tiny a quarter cell.

These are the main driver for the playfield abstraction (§8.1). Handled there by working
the grid at **half-cell resolution**: Tiny is 1×1 half-cells, Normal 2×2, Big 4×4, so one
integer grid expresses all three exactly.

### 4.5 Rounded
An ordinary brick with rounded corners — the same oblong shape, not a circle. The body is
the rounded rectangle, so glancing hits near a corner deflect at angles a sharp rectangle
never produces, while a hit anywhere along the flat of an edge behaves exactly as it always
has. Watch for the ball resting on top and losing horizontal speed.

### 4.6 Gravity
Falls into any empty cell below it and keeps falling until it rests on a brick or reaches
the lowest row. If its support is destroyed, it resumes falling. Falls are animated. Two
falling into the same column resolve in order.

### 4.7 Directional
Destroyed only when struck from one side; other sides bounce without damage.

**Top and bottom before left and right.** The ball spends most of its time travelling up and
down, so a brick that only takes damage from above or below is something the player can solve
by waiting for the right pass. Left and right ask for a specific angle, which is a much harder
shot — so those stay rare until a run is well underway, with a small chance of meeting one
sooner. **Drawn as the
Indestructible brick with one edge in the standard brick's material**, so the hittable side
is read from the artwork rather than from a colour.

### 4.8 Moving
Occupies one cell but wanders within a reserved 2×2 region. No other brick may occupy the
other three cells.

### 4.9 Exploding
When destroyed, destroys all eight adjacent bricks regardless of type, including
Indestructible.

**Explosions chain**, each brick detonating at most once per event, resolved in a single
pass. Exploding bricks are rare enough that a long chain is unlikely — and a rare long
chain is a good moment, not a problem.

### 4.10 Spawner
When destroyed, creates new bricks of other types in nearby empty cells. The counterpart
to Exploding: one clears the field, this one refills it.

**Needs bounding**, or a field can grow faster than it can be cleared. Proposed: spawns a
fixed small number, never spawns another Spawner, and only into cells that are already
empty — so it cannot displace anything or cascade.

### 4.11a Fixed
Behaves as an ordinary brick until it is struck once. From then on it stops descending with
the rest of the field and holds its position, and is destroyed by a second hit. **Bricks that
descend onto it are destroyed by it**, so leaving one alive carves a channel up through
everything arriving above it.

The interesting part is that it is the player who decides where the obstacle goes: one hit
plants it, and where it is planted determines what the next twenty rows do.

**It never gates generation.** An anchored brick does not descend, so one anchored low in the
field would sit in the bottom row for ever and no further row would be generated. It is
excluded from the bottom-row count instead — still destructible by the player, by an
explosion, or by Zap, it simply does not hold the field up while it waits.

**Ordinary size only, and never with anything that moves it.** Only some quarters of a Tiny
set would ever draw the style, and a Big one would wall off two columns at once. Moving and
Gravity are excluded because one says stay exactly here and the others say do not.

### 4.12 Power-Up brick

A power-up built into the field rather than falling out of it. Breaking it sets it off at once —
good or bad — through exactly the same path a caught power-up goes through, so every effect,
timer, icon and conflict rule is the one that already exists.

The point is what that does to a *bad* one. A falling Lose A Ball is avoided by moving the
paddle, which costs nothing and is not really a decision. One built into the field is a brick
you have to *not hit*: it is in the way, it is in the middle of the shot you wanted, and leaving
it there means playing around it until it has descended past you.

**It is never cleared by reaching the bottom.** It carries on down and out, like an
Indestructible brick, so somebody who spent twenty metres avoiding a bad one is not punished at
the last moment by the field clearing it for them.

**Two cells tall and one wide**, which on a grid whose cells are twice as wide as they are tall
makes it square — the shape a power-up already has when it falls. That is the whole reason for
the shape: it should read as a power-up sitting in the field rather than as a brick with a
picture on it. It wears the icon of whatever it is holding, and it is built the way a Big brick
is: the node stays on its row centre and the extra height is an anchor point and an offset body,
with the row below reserved a row earlier.

**Rare**, and never given a style. It is already saying one thing loudly; a spinning, flashing
power-up brick would be saying three.

### 4.11 Portal
Struck rather than destroyed. The ball entering one leaves from another Portal brick
elsewhere in the field, keeping its speed.

**The two ends are never the same colour.** The second Portal takes whichever colour is not
already in the field, rather than "blue if there are none" — those are the same answer until a
Portal is removed (Zap clears Indestructible bricks, and a Portal is built on one), after which
the survivor could be yellow and the next one would be yellow as well.

**Two at most, and they behave differently alone and in a pair.** One on its own is a lift:
the ball goes to the top of the field and comes back down through everything. A pair is a
doorway, and it works both ways — the ball comes out of whichever end it did not go into,
still travelling the way it was, so blue to yellow and yellow to blue are the same journey.
The two colours are a label rather than a direction: they let a player see which end pairs
with which before committing to the shot. Three would be ambiguous about where a jump lands. A brief cooldown stops the ball re-entering the far end immediately, and the
ball is pushed clear of the exit along its heading so it does not arrive inside the brick it
just came out of.

### 4.12a Shaped faces — Convex, Concave and Wedge

Every brick the game has had since 2020 is a rectangle, so every bounce off the field has
been one of four answers. These three are the same brick — the same behaviour, the same
score, the same descent — with a different outline, and the outline is the whole feature.

| Face | Shape | What it does to a shot |
|---|---|---|
| Convex | A dome: full height in the middle, shoulders a tenth below the mid-line | Off-centre hits leave *wider* than they arrived. One of these scatters a shot across a tight field; straight up the middle still comes straight back |
| Concave | A dish: a notch cut to a tenth *above* the mid-line | Hits near either edge are turned back toward the middle. The one brick that gathers a shot rather than spreading it, and two facing each other make a corridor |
| Wedge | A right triangle, pointing left or right, decided when it is built | Everything reaching the slope leaves the same way whatever angle it arrived at — the closest the field comes to a brick you can aim with |

Two things make this harder than it looks, and both are why the geometry is a pure,
tested type (`EndlessIIFaceGeometry`) rather than paths written inline:

- **A physics body must be convex.** `SKPhysicsBody(polygonFrom:)` takes convex paths only,
  and a notch is not one. So a face declares its *silhouette* (drawn, may be concave)
  separately from its *body pieces* (always convex, assembled with `SKPhysicsBody(bodies:)`
  when there is more than one). A non-convex path is not rejected by SpriteKit — it is
  silently mangled, and the brick then bounces off a shape nobody drew, which reads as a
  physics bug rather than a path bug. A test asserts every piece is convex.
- **The sprite has to hide inside the shape.** The face is drawn as a shape node filled with
  the brick's own texture, the way Rounded does it, because the sprite behind it must keep
  its texture — `endlessIIBehaviour(of:)` and every line in `hitBrick` identify a brick by
  that texture and masking it would blind them. Rounded shrinks its sprite to 78% and that
  hides a rectangle inside a rounded rectangle. It is not enough here: **a Wedge's
  hypotenuse passes through the node's own centre, so no centred rectangle fits inside it
  at any scale.** Each face therefore names the rectangle its sprite hides in, applied as a
  size and an anchor point — the Big brick's trick (§8.6), for the same reason: the node
  stays on its row centre and only the drawing moves. A test asserts all four corners of
  that rectangle are inside the silhouette.

**Normal size only, and they stack with little.** A face rebuilds the outline, the body and
where the sprite sits, so it refuses anything that redraws the outline (Rounded), turns the
brick (Spinning), decides where it sits (Gravity, Moving, Fixed), reads a hit against a
rectangle (Directional) or replaces what a hit means (Portal). What is left — Flashing,
Exploding, Spawner — touches colour, alpha and neighbours, none of which a shape cares
about. That rule is stated once in `EndlessIIStyle.refusedByAFace` and the reference page
derives its line from it rather than repeating it.

---

## 5. New power-ups

### 5.1 Conflicts, not channels

The first draft proposed broad channels with one active power-up each. **That was wrong.**
It would have stopped Magnetism combining with Inert Paddle, or Aura with Wrap-Around, and
those combinations are the fun.

**Power-ups combine by default.** There are only two kinds of exception.

**Stepped axes.** Some pairs already share a value and already resolve sensibly: collecting
the same one again deepens the effect, collecting its opposite steps back toward normal.
This is existing behaviour and is kept exactly as it is.

| Axis | Steps | Opposite cancels toward |
|---|---|---|
| Ball speed | Slowest ← Slow ← Nominal → Fast → Fastest | Nominal |
| Ball size | Smaller ← Nominal → Larger | Nominal |
| Paddle size | 0.5 ← 0.75 ← 1.0 → 1.5 → 2.0 → 2.5 | 1.0 |

So Slow Ball collected while Fast Ball is active returns the ball to normal speed; collected
while Slow is active it goes slower still. Nothing new is needed for these.

**True conflicts.** Two groups where two power-ups set the same single rule and cannot both
be honoured. **The one collected later supersedes the earlier, which ends immediately** —
they cancel rather than combine.

| Conflict group | Why | Members |
|---|---|---|
| `ballHitBehaviour` | One rule for what the ball does on contact with a brick | Giga-Ball, Inert Ball, Wrecking Ball |
| `launchControl` | One thing can own the launch | Sticky Paddle, Aimed Sticky |

That is the whole list. **Everything else composes.**

Deliberately *not* grouped, because they combine well:

- Magnetism + Inert Paddle — drawn in, but unable to steer. Coherent and interesting
- Flipped Angle + Magnetism — inverted steering plus attraction
- Aura + Wrecking Ball — the aura destroys without bouncing, the ball destroys and bounces; the two do different jobs at different radii
- Portal Paddle + Wrap-Around — both change where the ball reappears, in different axes
- Trajectory Line + Landing Marker — different information, no conflict

**All power-ups act on every ball in play at once.** A speed change, an aura, a wrecking
ball applies to all of them; there is no per-ball state to track.

### 5.2 Rarity

Three tiers, governing which power-ups are *eligible*, not how often power-ups drop.
Roughly 60 / 30 / 10 as a starting point. How these get from a guess to a balance is §6.5.

| Tier | Character |
|---|---|
| Common | Numeric. Changes a value |
| Uncommon | Behavioural. Changes how something behaves within the existing rules |
| Rare | Rules-changing. Suspends or inverts a rule the player relies on |

Rarity is independent of depth (§6.2).

### 5.3 The existing power-ups, classified

The twenty-eight that already exist, placed into the same scheme so there is one table
rather than two. **Behaviour is unchanged** — this is a classification of what is already
there, and the tier and stacking columns are proposals for review.

| Power-up | Effect | Conflict | Tier | Timed | Stacking |
|---|---|---|---|---|---|
| Extra Ball | Gives an extra life | — | — | No | **Excluded from Endless II.** See note |
| Lose A Ball | Loses the current life. Bad | — | Uncommon | No | Repeats |
| Slow Ball | Slows the ball | Ball speed axis | Common | Yes | Deepens; Fast cancels |
| Fast Ball | Speeds the ball up. Bad | Ball speed axis | Common | Yes | Deepens; Slow cancels |
| Expand Paddle | Widens the paddle | Paddle size axis | Common | Yes | Deepens; Shrink cancels |
| Shrink Paddle | Narrows the paddle. Bad | Paddle size axis | Common | Yes | Deepens; Expand cancels |
| Sticky Paddle | Ball sticks to the paddle | `launchControl` | Uncommon | Catches | Adds catches |
| Gravity Field | Applies gravity to the ball. Bad | — | Uncommon | Yes | Extends |
| +100 Points | Adds 100 × multiplier | — | Common | No | Repeats |
| −100 Points | Removes 100 × multiplier. Bad | — | Common | No | Repeats |
| +1000 Points | Adds 1000 × multiplier | — | Uncommon | No | Repeats |
| −1000 Points | Removes 1000 × multiplier. Bad | — | Uncommon | No | Repeats |
| Max Multiplier | Sets the multiplier to its maximum | — | Uncommon | No | No further effect |
| Reset Multiplier | Sets the multiplier to its minimum. Bad | — | Uncommon | No | No further effect |
| Complete Level | Moves to the next level | — | — | No | **Excluded from Endless II.** See note |
| Show Bricks | Reveals hidden bricks | — | Uncommon | No | Repeats |
| Hide Bricks | Hides standard and invisible bricks. Bad | — | Uncommon | Yes | Extends |
| Clear Multi-Hit | Reduces multi-hit bricks to one hit | — | Uncommon | No | Repeats |
| Reset Multi-Hit | Restores multi-hit bricks. Bad | — | Uncommon | No | Repeats |
| Zap Indestructible | Removes all indestructible bricks | — | Uncommon | No | Repeats |
| Giga-Ball | Ball passes through all bricks | `ballHitBehaviour` | Rare | Yes | Extends |
| Inert Ball | Ball stops removing bricks. Bad | `ballHitBehaviour` | Uncommon | Yes | Extends |
| Lasers | Fires lasers from the paddle | — | Uncommon | Yes | Extends, then fires faster |
| Quicksand | Moves all bricks down. Bad | — | Uncommon | No | Repeats |
| Mystery | Applies a random power-up | — | Uncommon | No | Repeats |
| Backstop | A net below the paddle, saves one ball | — | Uncommon | Catches | Adds a catch |
| Expand Ball | Makes the ball larger | Ball size axis | Common | Yes | Deepens; Shrink cancels |
| Shrink Ball | Makes the ball smaller | Ball size axis | Common | Yes | Deepens; Expand cancels |

**Two are excluded.**

- **Complete Level** has no meaning in a field with no end, so it is not in the drop
  table.
- **Extra Ball is excluded from Endless II.** It grants a *life*, which is meaningless
  where there is exactly one and no way to earn another - and it would have collided with
  Multi-Ball, which adds a ball in play. Removing it settles the naming question too:
  Multi-Ball keeps its name.

### 5.4 The new power-ups

**Timed** — whether it runs on a clock. **Stacking** — what a second collection does while
the first is still active.

| Power-up | Conflict | Tier | Timed | Stacking | Behaviour and notes |
|---|---|---|---|---|---|
| **Descent** | — | Uncommon | Yes | Extends duration | Field moves down continuously. Bricks past the lower limit are destroyed, not scored. Suspends the normal descent cadence while active |
| **Trajectory Line** | — | Uncommon | Yes | Extends, then lengthens the line | Draws the ball's path ahead, reflecting off walls, stopping at the first brick it would meet |
| **Aimed Sticky** | `launchControl` | Uncommon | Yes | Extends duration | Ball is held; drag to choose the launch angle, shown by an arrow. **The default angle is the angle the ball would have bounced at anyway**, so releasing without dragging changes nothing |
| **Magnetism** | — | Uncommon | Yes | Extends, then strengthens | Curves the ball toward the paddle. Strength falls off with distance. Temporary, so it cannot make a run unloseable |
| **Lock** | — | Rare | Yes | Extends duration | Freezes every active timed power-up; their timers stop. **Only drops while at least one timed power-up is active with enough time left to still be active when the Lock reaches the paddle.** Ends by itself, or by Key |
| **Key** | — | Uncommon | No | n/a | Ends the Lock; timers resume. **Only drops while a Lock is active** — so its weight is set high *within that window*, rare overall but reliably available while it is possible |
| **Cull** | — | Rare | No | Fires again | Destroys half the remaining bricks, chosen at random, of any type including Indestructible. Scored as destroyed. Its value is highest exactly when the field is worst, which is when a run is most likely to end - and being random rather than chosen means it relieves the pressure without deciding the shape of what is left |
| **Laser Beam** | — | Rare | No | Fires again | A sustained vertical beam destroying a whole column including Indestructible. **One beam per ball in play**, each fired from its own x-position — so with four balls it clears four columns at once |
| **Portal Paddle** | — | Rare | Yes | Extends duration | Ball entering the paddle re-enters at the top, keeping horizontal velocity |
| **Wrap-Around** | — | Rare | Yes | Extends duration | Ball leaving one side re-enters the other. **The paddle wraps too**, so a paddle driven off one edge reappears at the other — the side walls stop being walls for as long as it lasts, and the corners stop being the safe places they usually are. Moving bricks and explosions wrap as well, so what the power-up changes is the shape of the field rather than one rule about the ball |
| **Landing Marker** | — | Common | Yes | Extends duration | Marks where the ball will cross the paddle's line |
| **Wrecking Ball** | `ballHitBehaviour` | Rare | Yes | Extends duration | Destroys any brick in one hit regardless of type, and **still bounces off it** — distinct from Giga-Ball, which passes through without destroying everything |
| **Aura** | — | Uncommon | Yes | Extends, then grows | Glow of twice the ball's radius. Bricks touched by the aura are destroyed; the ball bounces only off bricks it touches itself |
| **Randomised Bounce** | — | Uncommon | Yes | Extends duration | Bounce angles gain a random offset. Bad |
| **Inert Paddle** | — | Uncommon | Yes | Extends duration | Paddle no longer influences bounce angle. Bad |
| **Flipped Angle** | — | Uncommon | Yes | Extends duration | Paddle's angular influence inverted. Bad |
| **Multi-Ball** | — | Uncommon | No | Adds another ball, to a maximum of four | Adds a ball. **Weight drops to zero while four are in play**, so it stops being offered rather than being collected for nothing. §5.4 |
| ~~**Wipe**~~ | — | Uncommon | No | n/a | **Built** (round 31). Ends every active power-up immediately. Bad. **Does not remove a Lock** — otherwise Wipe is strictly better than Key and Key never drops. Drops only while something is running for it to end: a bad power-up that takes nothing away is a gift rather than a dud |
| **Paddle Halo** | — | Rare | Yes | Extends, then reaches further | Semicircular glow from the paddle into the lower rows, destroying bricks it touches |
| **Reversed Controls** | — | Uncommon | Yes | Extends duration | Paddle moves opposite to the player's touch. Bad |
| **Ball Steering** | — | Rare | Yes | Extends duration | Moving the paddle steers the ball's x-position in flight |
| **Clear And Retreat** | — | Uncommon | No | Repeats | Destroys the lowest occupied row and pushes the field up one row |
| **Infill** | — | Uncommon | No | Repeats | Adds bricks in random empty cells. Bad |

Colour convention unchanged: green is beneficial and awards points, red is harmful and
deducts.

**Default stacking**, unless the table says otherwise: a second collection of a timed
power-up **extends** its duration rather than restarting it, and where a magnitude makes
sense a third collection may deepen it. Instant power-ups simply happen again.

### 5.5 Multi-Ball

**In.** The rule: **the run continues while at least one ball is in play**; the life is lost
when the last one goes.

Only Endless II uses it. Classic and Endless keep a single ball, so the existing modes are
untouched — but the scene must hold a *collection* of balls rather than one, which touches:

- ball-lost handling, which currently ends the life on any loss
- per-ball state: sticky, aura, trajectory line, landing marker each act on their own ball.
  **Sticky is built**: the paddle holds a queue and launches the oldest first, one per tap,
  with the first ball taking its turn in the same queue. A ball saved with no heading was
  being held, and comes back held
- power-up state that is *not* per ball: the Giga-Ball body, the ball's size and its speed all
  belong to the run. Each of those reached the first ball's node and had to be pushed to the
  rest — a set of balls that look alike and behave differently is worse than no Multi-Ball
- the save format, which stored one ball's position and velocity (§9.3) — **built**
- the ball-speed power-ups, which set a single shared limit — proposed: shared across all
  balls, as one value, matching the `ballSpeed` conflict group

### 5.6 Interaction rules not covered by §5.1

- **Lock and Key are the only conditional drops.** Eligibility depends on live game state,
  which the allocation table cannot express today — a specific requirement on §8.2.
- Bad power-ups drop freely regardless of how clear the field is. In an endless mode there
  is no "last brick", so the Classic-mode concern does not apply.

---

## 6. Game dynamics

### 6.1 Progression

**The start is gentle.** A run opens with simple brick types, low density and common
power-ups, and builds: more brick types, rising density, rare power-ups becoming more
likely. **New brick types are introduced before density rises far**, so a player meets each
one when there is room to see what it does.

### 6.2 Phases

Phases are short stretches of **5–25 metres**, each length drawn at random, punctuating
longer runs of ordinary randomly generated field. They are the seasoning, not the meal.

Each has a **weight** and some a **minimum height**, so the opening stays gentle.

| Phase | Character | Gate |
|---|---|---|
| Standard | The baseline mix | — |
| Quiet | Low density, a breather | — |
| Swarm | Many Tiny bricks, sparse | — |
| Drift | Moving bricks, wide spacing | Low |
| Flicker | Flashing bricks dominant | Low |
| Cascade | Gravity bricks, field reshapes as it is cleared | Medium |
| Minefield | Exploding bricks scattered through ordinary ones | Medium |
| Fortress | Big and Indestructible, few gaps, one clear route | Medium |
| Gauntlet | Directional bricks, one approach angle works | High |
| Carousel | Spinning and Rounded, unpredictable bounces | High |
| Downpour | Descent runs faster for the phase | High |
| Windfall | Normal density, noticeably more power-ups | — |
| Monolith | One enormous Big brick formation with a narrow route | High |
| Static | Flashing bricks, all in phase, so the whole field blinks together | High |
| Monoculture | One brick behaviour and nothing else, for the whole phase | Medium |
| Giants | Big bricks only, at lower density | Medium |
| Miniatures | Tiny bricks only, at higher density | Medium |
| Motif | Every brick wears the same pair of styles — spinning Multi-hit, rounded Indestructible | High |

**The uniform phases are the rarest.** Monoculture, Giants, Miniatures and Motif fix what
the field is made of once, at the start of the phase, rather than drawing it per brick. A
field where everything is one thing is a different problem from one where everything is
different, and it is a problem the player can plan against — which is what makes it a relief
after a mixed stretch rather than another kind of noise. It also shows a combination off
properly: one spinning Multi-hit brick is a curiosity, a screen of them is a puzzle. They
carry the lowest weights because a run that kept serving them would be a run of set pieces.

**Breathers are weighted, not scheduled.** Quiet simply carries a higher weight than the
rest, so breaks arrive often without being predictable. A Quiet phase is **not empty** — a
sparse field would just fly past. It is lower density and easier brick types, so it still
has to be played, just with room to breathe.

### 6.2.1 Clusters

Phases decide what a long stretch is made of. Set rows decide what one row is. **A cluster is
a shape sitting *in* a row that is otherwise whatever it was going to be** — three or four
columns wide, dropped at a column the generator picks, with ordinary field either side of it.

That difference is the whole point. A set row says "the next row is this". A cluster says
"there is a thing over there", and the field carries on around it — which is what makes it
read as an object in the field rather than as a change of subject. It is also why clusters
need no machinery of their own: a cluster is written as a small grid and expanded into
full-width rows whose every other column is `?`, "whatever the generator would have put
there", and from that point on it is a set row.

**The grid is not square.** A cell is twice as wide as it is tall, because a brick is. So a
shape that is square *in cells* is a 2:1 rectangle on screen, and anything meant to read as a
circle, a diamond, a ring or a staircase needs roughly twice as many rows as columns. Every
shape below is drawn for that, which is why they all look tall written down and correct in
the game.

**Three kinds of contents**, and most clusters are one of the first two:

- **A set formation of undesigned bricks** — the shape is designed, the contents are not, so
  the same ring is a different problem each time. Written with `?`
- **A set formation of particular bricks** — where the *type* is the idea. An indestructible
  lid, a multi-hit shell
- **Both** — a shell of something specific around contents that vary

| Cluster | Shape | Gate | Why |
|---|---|---|---|
| Block | 2×2, undesigned | — | The simplest thing a cluster can be, and the one that teaches a player that clusters exist |
| Slab | 4×2, undesigned | 40 | |
| Tower | 2×4, undesigned | 60 | |
| Chequer | 3×3 alternating | 50 | Solid enough to matter, open enough to be threaded |
| Wedge | A right triangle | 70 | A slope. Everything that hits it is sent the same way |
| Diamond | Points at top and bottom | 80 | |
| Cross | A plus | 90 | |
| Hoop | A ring with nothing in it | 110 | The inside is reachable and worth nothing, so the shape itself is the obstacle rather than a wrapper round a prize |
| Arrowhead | A chevron with a hollow | 130 | |
| Circle | An approximation, six rows deep | 150 | |
| Staircase | Three steps, two rows each | 170 | Two rows per step, so the steps are square on screen |
| Anvil | Indestructible lid over undesigned bricks | 190 | Has to be played around rather than through |
| Studs | Spaced Indestructible ×1 posts | 200 | What it leaves behind is decided by which ones the player chose to hit |
| Vault | Indestructible ring around undesigned bricks | 220 | The way in is the gaps at the corners |
| Core | Multi-hit shell around something ordinary | 240 | Slow to open and quick to finish |

**Rarity works as it does everywhere else.** Each carries a weight as well as a gate, and the
plain blocks carry the highest — a run that kept serving set pieces would be a run of set
pieces, which is the same rule the uniform phases follow. Height raises what is *possible*
rather than what is guaranteed.

**They never fit half-way.** A shape that runs off the side of the field is not the shape, and
the wall would be doing the part of the work the design was for. A cluster is only placed at a
column where it fits whole.

### 6.2.2 A floor under the density

The opening is meant to be sparse, and it is. What it cannot be is *absent*: **no more than two
consecutive rows arrive empty.**

Height is gained by clearing the bottom row, and a row with nothing in it is cleared the moment
it arrives — so a run of empty rows is height for free. That sounds generous and is the
opposite. The field rushes past, the player is deep before the mode has shown them anything,
and the density that was meant to arrive gradually arrives all at once, because it is keyed to
a height they reached in seconds.

The third empty row in a row gets exactly one brick, drawn from the mix that height would have
produced, and placed in the middle two thirds — against a wall it is easy to leave alone, and
leaving it alone is the thing this exists to stop. The density curve itself is untouched.

### 6.3 Exposure

**The introduction schedule.** Every new brick type and every Uncommon and Rare power-up is
shuffled at the start of a run and introduced at intervals, so a player who never gets deep
still meets a different subset each time, and the mode teaches itself without a tutorial.

**Rarity is preserved.** Being introduced early does not make something common — it makes
it *possible*. After a first appearance, an element returns at its normal weight.

**It does not show everything in one run.** The schedule covers a subset — proposed: enough
elements to fill the first 200–300 m, drawn from a pool that changes each run. How far
ahead to plan and how much to include is explicitly a tuning question for play-testing.

### 6.4 How rarity gets tuned

The tiers above are a starting guess, and a guess is all they can be before the power-ups
exist. What matters is that tuning is **cheap and evidence-led** rather than a rebuild.

**The knobs.** Each power-up carries its own weight, not just a tier — the tier is a
default the weight starts from. Weights live in the registry (§8.4) as data, so changing
one is an edit to a table, not to behaviour. Three modifiers sit on top: a minimum height,
a conditional predicate (Lock and Key), and a phase multiplier so a phase can make its own
elements more likely without changing the global mix.

**What we are tuning toward.** Three questions, in order:

1. *Does it appear?* Anything a player never meets in twenty runs is too rare to justify
   the work — either raise it or cut it.
2. *Is it legible?* If it appears and players cannot tell what happened, that is a
   presentation problem (§7.3), not a rarity one. Rarity should not be used to hide a
   power-up that does not read.
3. *Is it fun at that frequency?* The rules-changing ones are the ones this matters for. A
   Rare power-up that is annoying is worse the more often it appears; one that is
   delightful is wasted at 2%.

**How.** Play-test with the tier weights as written, note which power-ups were never seen
and which were seen too often to stay interesting, and adjust. Because Endless II runs are
short and single-life, a session produces a lot of runs quickly — this is one of the few
things about the mode that is easy to gather evidence on.

**What would make this rigorous, if it is worth it later:** the stats system already
records power-up usage. Recording per-power-up collection counts against runs would turn
"felt about right" into a distribution to look at. Not needed for the first pass.

### 6.5 Randomness

Seeded per run. Drawn without replacement within a phase, so a phase does not repeat one
brick type while omitting another. The existing `PowerUpAllocation` weighting is kept and
extended with tier, conflict-group and conditional filters.

---

## 7. Presentation

### 7.1 The power-up HUD

The current tray shows a fixed row of eight icons with a bar beneath each, including
power-ups that are not active. At this many power-ups that does not scale.

- Show **only active** power-ups
- Timer becomes a **ring around the icon**
- Icons appear on collection and fade out on expiry
- Centred, growing from the middle
- A Locked power-up shows its ring frozen, visibly distinct from a draining one

**Endless II only for now.** Classic and Endless keep the existing tray until this has been
played and judged.

### 7.2 Dynamic backgrounds

**The machinery is built** (`EndlessIIScrollingBackground`); the artwork is an asset slot.
Two copies of one vertically-looping tile leapfrog each other, code-owned from the start
because the scene file's background node will not accept a new texture at runtime. The
backdrop scrolls six points per metre climbed - well under the field's own row per metre,
which is what makes it parallax - and it eases toward the height rather than stepping with
it, so it reads as distance rather than as another moving part. It sits above the painted
background and below everything that plays, so the four selectable backgrounds remain
available underneath it and simply do not scroll.

Drop a looping tile named `EndlessMayhemBackdrop` into the asset catalogue and it is used
as-is; until then a barely-there drawn gradient proves the scroll works. The original ideas
stand for the artwork itself: a repeating grid in the Classic style, or a slow colour cycle
that shifts hue with depth.

### 7.3 Legibility

Each Rare power-up needs an unmistakable visual while active, beyond its HUD icon:
Wrap-Around marks the side walls, Portal Paddle marks the paddle and the top of the field,
Inert Paddle and Flipped Angle change the paddle's appearance, Halo is its own visual.

**Icons.** Each new power-up needs one in the existing style — rounded square, green for
beneficial and magenta for harmful, white glyph. These can be generated to match and then
tuned by hand.

**The power-ups information page lists them all**, with a description of what each does,
and the Endless II ones **explicitly marked as exclusive to that mode**.

---

## 8. What has to be built underneath

### 8.1 The playfield and brick grid
Brick size and position are computed inline against a fixed 22-column layout, and nothing
can answer what occupies a cell. Needed by Big, Tiny, Moving, Gravity and Exploding.
Requires: cell occupancy, adjacency, sub-cell and multi-cell sizes, region reservation, a
settle pass after destruction, and clearance rules for Spinning.

### 8.2 The power-up system as data
Near-identical switch cases today, each declaring icon, bar, timer and expiry inline.
Needed by conflict groups, tiers, stacking rules, conditional drops and the ring HUD.

### 8.3 Level data out of code
**Deferred until after Endless II.** Endless II generates its field and does not need it.

### 8.4 Extensibility
Both 8.1 and 8.2 are built so that a new brick type or power-up is **a data entry plus one
implementation**, with no edits to shared code. Concretely: a registry each, where an entry
declares its identity, artwork, rarity, conflict group and behaviour hooks. Adding the
twenty-third power-up must cost the same as adding the third. The same applies to phases
and backgrounds, which are also tables.

---

## 8.5 Art and audio still to make

Everything new is currently wearing a placeholder that reads correctly, which was the right
order: the mechanics have all changed shape at least once since they were drawn. With phase
8 complete this section is now the shopping list, slot by slot, for the real assets.

### Power-up icons — twenty drawn placeholders

Every one is a `static let` in `PowerUpIcon.swift`, drawn at 120×120 into the standard
rounded-square badge, green for beneficial and red for harmful. To replace one: add the
asset (e.g. `PowerUpMagnetism.png`), swap the entry in `LevelPackSetup.powerUpImageArray`
(which feeds the reference page and the power-up bricks) and the matching `SKTexture` in
`GameScene` (which feeds the drops) — both are found by the icon's name. The `applyPowerUp`
switch matches on those scene textures, so the drop, the brick and the page must all come
from the same place, which they do today via `PowerUpIcon`.

The twenty: Multi-Ball, Trajectory Line, Landing Marker, Aimed Sticky, Magnetism, Portal
Paddle, Paddle Halo, Ball Steering, Inert Paddle, Flipped Angle, Reversed Controls, Cull,
Clear And Retreat, Laser Beam, Wrecking Ball, Aura, Infill, Descent, Auto-Aim, Wrap-Around.

### Brick styles — glyph-on-tint placeholders

The nine styles and two sizes wear ordinary brick artwork tinted a distinct colour with a
drawn glyph over it (`BrickTypeIcons` and the style application in the brick creation
extensions). Real artwork replaces the tint-plus-glyph per style; the glyph-per-style rule
should survive whatever the art looks like, because it is what keeps the styles readable
without relying on colour alone (§7.3).

### Menus

Endless Mayhem currently reuses the original Endless infinity icon on the main menu, the
mode detail screen and the game-over screen. It deserves its own mark.

### The Daily Challenge's marks

Two more rows on the list, both James's side (his own note from the first daily play
test: "I should make some unique icons for the different twists"):

- **The mode's menu icon** - the calendar mark is drawn (`PowerUpIcon.dailyChallenge`),
  a real one replaces it there.
- **A badge per twist** - each twist wears a drawn violet badge
  (`PowerUpIcon.twist…`, mapped by `DailyTwist.icon`), shown beside its name on the
  briefing screen, the pause summary and the level intro. Real artwork replaces them in
  `PowerUpIcon.swift` and nowhere else - every screen reads `DailyTwist.icon`. The
  badge-beside-title layout is already in place, so the art drops straight in.

### The scrolling backdrop

One vertically-looping tile, screen-wide, named `EndlessMayhemBackdrop` in the asset
catalogue - the machinery in §7.2 picks it up by name the moment it exists. Quiet artwork
wanted: it sits behind the whole field, and a backdrop that competes with the bricks is
worse than none.

### In-scene drawing that may stay drawn

The halo, aura glow, laser beam flash, portal jump trail, aim arrow, pull lines, exit
strips, wall tints and the landing triangle are `SKShapeNode`/tint work, styled to the
mode's palette. These can ship as they are or be replaced piecemeal - none blocks release.

### Sound

The events that currently borrow a sound or play none, each with where it fires:

| Event | Today | Where |
|---|---|---|
| Explosion / Cull / Laser Beam / Infill | haptics only | `EndlessIIBehaviourBricks.endlessIIExplode`, `EndlessIIFieldPowerUps` |
| Portal jump (brick, paddle, wrap) | haptic only | `endlessIIEnterPortal`, `applyEndlessIIPaddlePortals`, `applyEndlessIIWraps` |
| Spawner refilling | none | `endlessIISpawn` |
| Gravity brick landing | none | the fallers tick in `EndlessIIBehaviourBricks` |
| Flashing brick turning solid | none | the flashing tick |
| Fixed brick anchoring | heavy haptic | `endlessIIAnchorIfNeeded` |
| Build-in rain / Clear And Retreat | `endlessRowDownSound` (borrowed) | `runEndlessIIBuildIn`, `endlessIIClearAndRetreat` |
| Power-up brick going off | `powerUpSound` (borrowed) | `endlessIITriggerPowerUpBrick` |
| Aimed catch / aimed launch | sticky catch / release sounds (borrowed) | `EndlessIIAimedSticky` |

The borrowed ones may be fine borrowed - the new ones from silence are the priority.

## 8.6 Constraints the implementation has to respect

Things that are not obvious from reading the code, each of which has already caused a bug.
Written down because they are the expensive kind of knowledge — every one cost a debugging
session, and none of them announces itself.

**A brick's `position.y` is its row.** The descent moves by it and the bottom-row check that
gates new-row generation reads it. A brick whose position is anywhere but its row centre is
cleared away at the wrong moment, or sits in the last row blocking generation for ever. Big
bricks keep their node on a row centre and express their size through an anchor point and an
offset physics body for exactly this reason.

**The descent moves by `brickHeight`, not by each brick's own height.** Those were the same
number while every brick was one cell. A brick of any other size drifts out of step with the
field it belongs to.

**Nothing runs a repeating `SKAction` on a brick.** `countBricks()` decides whether a row move
is underway by asking every brick `hasActions()`, and a new row is only generated once nothing
is moving. A brick with a permanent action answers yes for ever and the field stops descending.
Spinning, flashing, falling and wandering are all driven from `update` instead.

**`SKSpriteNode.size` is backed by floats.** A width assigned straight from `brickWidth` does
not read back as `brickWidth`, so `size.width == brickWidth` is always false. Compare with a
tolerance. This silently disabled two whole features once.

**A physics body cannot be moved from `didBegin`.** SpriteKit calls contact handlers in the
middle of simulating the step, and a position written there is overwritten as the step
resolves. Record the intent and apply it in `didSimulatePhysics`.

**`colorBlendFactor` is modulated by the texture.** Colourising a bright texture gives the
colour; colourising a dark one gives a dark, muddy version of it. Tinting only works on the
plain brick artwork.

**`CGMutablePath.addArc` joins to the current point.** Drawing a segmented ring without a
`move(to:)` before each arc fills every gap with a connecting line and the ring reads solid.

**The side blocks are the walls.** They fill whatever the play area leaves over, and a wall of
zero width gets no physics body — which the next line force-unwraps. They take a minimum
thickness that extends off-screen, so the play area can reach the edge.

**Cells can be part full.** Four Tiny bricks share one cell, so "is this cell occupied" is the
wrong question — a cell with one quarter left in it is not a wall. Ask how full it is.

**A style has to be in a pool to exist.** `EndlessIIStyle` is the list of styles, and
`applyEndlessIIStyles` is offered a *pool* per call site — the appearance ones and the
field-changing ones. Fixed was added to the enum, to the compatibility grid, to the reference
page and to the progression, and to neither pool, so no brick could ever be given it. From the
outside that is indistinguishable from a style that is simply very rare, which is why it went
unnoticed for so long.

**Adding a power-up lengthens arrays in two places, not one.** Every per-power-up array exists
twice: in the stats file on disk and in `NSUbiquitousKeyValueStore`. Both hold whatever the last
version to write them had. `TotalStats.padded` covers the file; the cloud copy was missed, and
the twenty-ninth power-up crashed on the first launch after the update — every merge loop in
`CloudKitHandler` walked the local array's length while indexing the stored one. The same is
true of achievements, levels, packs and themes. Loops there are now bounded by the shorter of
the two in both directions, and a test reads the source to check no new one slips in.

**A contact reports the velocity *after* the bounce.** SpriteKit calls the contact handler
partway through resolving the step, so a ball's velocity read there is the one it is leaving
with, not the one it arrived with. Anything that needs the approach — which face was struck,
which way a Portal should send the ball on — has to sample it in `update`, before the physics
runs. `ballStateBeforeStep` is that sample.

**Reflecting a reported velocity bounces it twice.** Following from the note above: the wall
and ceiling handlers negated a velocity the engine had already turned round, so the ball was
sent back into the surface it had just left. At the ceiling that is a ball running along the
top of the screen; at a side wall it is the sideways part of a shallow approach being lost.
Both now reflect the *approach*, sampled before the step.

**Adjacent bricks have a seam.** Every brick is its own body, so a ball landing exactly on the
join between two of them is resolved against both at once and leaves off a corner rather than
off the flat face. `BrickSeamBounce` catches it: two bricks struck in one step are treated as
one surface. Anything else that gives one ball several brick contacts in a step needs to think
about the same thing.

---

## 9. Out of scope for the first version

- **A separate descent-pressure mode** — where the field reaching the paddle is the core
  threat. A different game; parked as a future mode.
- **iPad-specific layout** beyond the fixed ratio.

### 9.3 Pause and resume
**In scope.** A run cannot be abandoned and returned to from within the app, but it must
survive pausing *and* the app being quit — the same guarantee Classic has. The save format needs the ball array (§5.5), active power-up state including Lock, the
generated field as it stands, and the phase and schedule position so generation continues
coherently. Generation does not need to be reproducible from a seed - the field is stored
as it is today, and only one phase is planned ahead.

**Built.** Every ball beyond the first is written as four values — x, y, dx, dy — in one flat
array beside the first ball's five. The fifth value there is the paddle's x, which belongs to
the game rather than to a ball and is written once.

- The field is **optional**, so every save written before Multi-Ball existed still decodes.
  Those restore with no extras, which is what they had.
- A save is a file on disk that an older build or a bad write may have left in any state, and
  it is read at launch, where a trap is a crash on opening the app. So a ragged array — one
  not a whole number of balls — fails the consistency check and the save is discarded rather
  than read past the end, and extras claiming no first ball to be extra to are rejected the
  same way.
- No more balls come back than §5.5 allows, capped both when writing and when reading.
- Velocities are restored the way the first ball's are: into the paused-velocity store, so
  the countdown runs with the field still, and every ball starts moving at the moment play
  does. Pausing is what takes the velocities off the field, so each ball needs somewhere of
  its own to keep one — without that the extras came back stationary and dropped straight
  down, which is three balls lost to opening the pause menu.

---

## 10. Decisions

Settled in review, recorded so they are not re-argued.

| Question | Decision |
|---|---|
| Lives | **One**, exactly as Endless |
| Score | **Height alone** |
| Name | **Endless 2.0** for now |
| Ring HUD | **Endless II only** initially; may extend to other modes later |
| Multi-Ball | **In** |
| Explosion chaining | **Yes**, chains |
| Introduction schedule length | Tuned by play-testing. **Must not show everything in one run** |
| Channels | **Replaced** by narrow conflict groups (§5.1) |
| Level data refactor | **After** Endless II |
| Complete Level, Extra Ball | **Excluded** from Endless II's drop table |
| Multi-Ball's name | **Kept** — the collision went with Extra Ball |
| Laser Beam with several balls | **One beam per ball** |

## 11. Still open

1. **Does Tiny survive?** Kept unless sub-cell sizing turns out to be a rewrite rather
   than an addition — the call comes when §8.1 is built, and Big alone still gives the size
   axis if it goes.
2. **Rarity tuning.** How, rather than whether: §6.4.

---

## 12. Build phases

Each phase ends in something playable, so the mode can be judged as it grows rather than
only at the end. Nothing in a later phase is a prerequisite for testing an earlier one.

| Phase | What lands | What you can test |
|---|---|---|
| **1. The mode exists** ✅ | Endless 2.0 on the main menu, playing exactly as Endless does today, with its own stats and leaderboard | That it launches, plays and scores - and that Endless and Classic are untouched |
| **2. The ring HUD** ✅ | Only-active power-ups, ring timers, in Endless 2.0 only | Whether the ring reads better than the tray, side by side with the old one |
| **3. Simple bricks** ✅ | Spinning, Flashing, Rounded - no grid changes needed | Whether they read clearly and whether Flashing is fair |
| **4. Sizes** ✅ | Big and Tiny, on the brick grid | Whether Tiny is worth its cost, which is the open question in §11 |
| **5. Behavioural bricks** ✅ | Gravity, Moving, Directional, Exploding, Spawner, Portal | Whether explosions and cascades feel good or chaotic |
| **6. Generation** ✅ | Phases, gentle opening, the **style progression** below, and the power-up introduction schedule | The heart of it: whether a run feels varied and whether the pacing works |
| **7. Multi-Ball** | The collection of balls, and the run continuing while one survives | Performance with four balls, and whether it is as fun as it sounds |
| **8. New power-ups** | In batches, simplest first: vision, then paddle, then rules-changing | Each batch on its own, which is the only way to tune rarity |
| **9. Presentation** (code side ✅) | Scrolling backgrounds, icons, the information page | The finish. The backdrop machinery, the info pages and the reference content are built and current; what remains is §8.5's asset list - real icons, brick artwork, the mode's own menu mark, the backdrop tile, sounds - and the Quick Start Guide |

Phases 3 to 5 can be reordered freely - they are independent. Phase 6 is where the mode
stops being Endless with extra bricks and starts being its own thing, so it is worth
reaching before judging whether the whole idea works.

### 12.0 Where this has got to

Phases 1 to 6 are built. Everything below is what remains, in the order it is worth doing —
all of it presentation and reference material rather than mechanics.

**Built since:** the background selection screen and the brick types page. Both are new UI
rather than mechanics.

- **Background selection.** The settings row opened nothing and cycled a name; three of the
  four backgrounds are shades of the same purple, so the name said nothing about what had been
  chosen. It now opens a screen that swipes between scale models of the game scene, one per
  background, drawn at the device's own proportions. What a background *is* moved to
  `GameBackground` and the playfield's proportions to `GameSceneLayout`, so the model and the
  scene cannot disagree — the layout maths the scene has always used now has a home that can
  be tested, and the 1.8236 ratio is asserted across a spread of screens.
- **Brick types page.** A reference page in the shape of the power-ups one, with sections for
  the five behaviours, the ten styles and the three sizes. The compatibility lines are derived
  from `EndlessIIStyle` rather than written out, so the page cannot fall behind the game; the
  icons reproduce the placeholder look described in §8.5 deliberately, and this is where the
  page will start using the real artwork when it exists.

**Phase 7 is built.** Multi-Ball drops, adds a ball up to four, and the run continues while any
of them is in play.

- `EndlessIIBalls` holds the rules; `EndlessIIMultiBall` holds the collection. `ball` never
  changes identity — when it is the one lost, a survivor hands over its position and velocity,
  so nothing else in the scene has to know a swap happened. That is what keeps Classic and
  Endless untouched.
- Every ball gets its own contact handling: its own wall bounces, paddle angles, brick
  corrections and portal jumps. Speed, size and texture are shared across the set (§5.5).
- The drop weight falls to zero while four are in play, so it stops being offered rather than
  being collected for nothing.
- **Sticky Paddle holds every ball**, in the order they were caught: one leaves per tap, oldest
  first, and the first ball waits its turn in the same queue - so a first ball caught last goes
  last. That is the per-ball launch state §5.5 asked for, for the power-up that exists today;
  Aimed Sticky will inherit the same queue.
- The save format carries every ball, so a run paused with four resumes with four (§9.3).

Everything a power-up does reaches every ball. Giga-Ball reached all four textures and one
physics body, so three of them looked the part and bounced like ordinary balls; the same is
true of ball size, which is a scale rather than a size and has to be copied as one.

Phase 7 is complete.

**What play-testing found, and what it was.** Recorded because each of these was written when
there was only ever one ball, and the next thing built on top of the collection will meet the
same class of bug:

- A bounce off nothing in the gap below the field was the paddle being handed back to a ball
  still overlapping it. The paddle is taken out of a ball's way while the ball is underneath
  (so a Backstop can work), and a contact reported in that moment is not a landing.
- The resume countdown left the other balls running: pausing zeroed the first ball's velocity
  once per ball in play and left the rest travelling. Every ball now keeps its own heading
  across the pause and shows its own direction marker while the countdown runs.
- Losing several balls within a frame or two spent balls that were never in play, and handed
  the first ball the position of another ball that was itself about to be lost. The handover
  now takes the highest survivor, and a ball already retired is not counted twice.

**Since the last round of play-testing:** the power-up brick draws from the same eligibility
rules as the falling ones (`powerUpCanAppear`, which the drop path now asks too rather than
answering one case at a time inside its own switch); Tiny bricks ramp with height rather than
appearing at a flat rate from the first metre; and the opening field arrives the way the field
moves in play - each row entering at the top and stepping down, in lockstep, rather than each
brick fading into its own place.

**Built in play-test rounds 16 and 17**, all presentation:

- **One pop-up style.** The app had two: its own dark blurred sheet, and `UIAlertController`,
  which newer screens reached for because it is one line. `GigaBallAlert` is the app's own,
  presented as a *child view controller* so it sits inside the pause menu's blur instead of
  sliding a white card over it, and the storyboard's warning sheet was restyled to match
  rather than replaced - everything it does hangs off actions and notifications that work.
- **The daily's twists explain themselves on the pause screen**, not the briefing card: the
  briefing prints each blurb under its twist already, and the pause screen shows only an icon
  and a name, which is exactly where "what does Fog of War do again" gets asked.
- **The daily card is two containers**, details and posted score, in a column - so the result
  is its own block and still scrolls with the day.
- **A signed-out player is told, quietly.** `GameCenterHandler.notSignedInNote` is one line in
  one place, shown under the daily's title and at the foot of a finished run's score block.
  Not an alert: nothing is broken and nothing is lost, so it wears the same grey as the rest
  of the small print.
- **The lives line follows the score in the daily**, where there is no high score printed - a
  label with no text still holds its place, which had left "Last ball" stranded a third of a
  screen below the number it belongs to.
- **Classic's menu icon is the app icon, round-masked**, drawn from the icon preview art at
  runtime so it cannot fall out of step with the icon itself.

**Open, in rough priority order**

| Item | Notes |
|---|---|
| Menu breathing room, throughout the app - **done, round 74** | James, round 73: table views across the app start too close to the page title and finish too close to the bottom button row, and the whole thing feels compact. Wanted: more space at both ends, everywhere, rather than screen by screen. The screens share a nib and a navigation pattern but *not* their layouts - each is its own storyboard scene with its own constraints - so the honest first move is to find whether `limitMenuContentSize()`, which every one of them already calls from `viewDidLayoutSubviews`, is a place the gap can be applied once. It was: `UIViewController.menuListBreathingRoom` is one `UIEdgeInsets` applied as a *content* inset to every table found in the screen, from `limitMenuContentSize()`, so all twelve screens got it from one number and nothing in a storyboard moved. Two things the doing taught: these tables set `contentInsetAdjustmentBehavior = .never`, so **the content offset has to be moved with the inset** or the padding is real and invisible; and both places that ask "does this fit" - `applyScrollAffordance` and `fitGlassPanel` - measure content against the frame and had to start counting the padding as content, or a list padded just past the bottom decides it fits and refuses to scroll to its own last row |
| The grid layout - **done, all five, rounds 77-79** | App Icons and Ball & Paddle themes are grids. `PackGridCell` took them with two additions rather than a rewrite: no list button when nobody hands it a handler, and `recolour:` on `show(...)`, because a pack icon is a flat glyph and an app icon is a *picture* - templating one leaves a white silhouette, which is what the first screenshot showed. The grid is built in code over the table in `ItemsDetailViewController` and borrows its frame, because that scene serves four lists and only two want squares. **Two traps for the remaining three:** the VC had to declare `UICollectionViewDelegateFlowLayout` - without it `sizeForItemAt` is silently ignored and every square comes out 50pt, which looks like a layout bug and is a conformance one; and the back-button row shares every collection-view delegate method on these screens, so each one needs its `collectionView == grid` branch. Round 78 added the **Power-Ups and Achievements** lists, on James's call that a square carries the icon and the name while the description stays on the detail page. Their names are phrases rather than words, so the square gained a `nameSize` and the screen picks it: 13 for packs and themes, 11 for power-ups, **10 for achievements over two columns rather than three**, because "Endless Mode 1,000m Milestone" does not fit a third of a phone. The power-up grid keeps its pinned THIS RUN / OTHER headings through `sectionHeadersPinToVisibleBounds` and a supplementary view with its own dark blur backing - the same recipe the rows used. Round 79 finished with the **Bricks** reference, and its headings pin. Worth recording *why that changed*: the old table was deliberately **grouped rather than plain** so its headings would not pin, because a header floating over the rows through the table's edge fade read as a glitch. A collection view's header carries its own blurred backing, so the squares disappear behind the heading rather than through it - which is what makes pinning the better answer now rather than the same mistake again | James, round 75: the Classic pack screen's grid of squares reads better than a list, and he wants the same on **App Icons, Ball & Paddle themes, the Power-Ups reference, the Bricks reference and Achievements**. `PackGridCell` is the model - a code-built square with the art, the name, a lock and a tick, glass already applied - and `PackSelectViewController` shows the flow layout and the floor-the-column-count arithmetic that a play-test round already had to fix once. The five differ in what a square must carry: App Icons and themes need a tick for the chosen one and a lock with its unlock sentence; the two reference pages need no state at all but the Power-Ups one has **pinned section headings** a grid must keep; Achievements needs the completion badge and its date. Do them one at a time with a screenshot each - a grid of eleven packs is not a grid of fifty-one power-ups, and the cell size that suits one will not suit the other |
| Brick reference: sticky section headings - **done, round 79** | James, round 75. BEHAVIOURS, STYLES and SIZES should pin the way the Power-Ups page's do, and look the same doing it. That page's are a `viewForHeaderInSection` with its own dark blur backing and the app's lime label, plus `stickyHeaderBand` set on the table so the pinned header stays out of the edge fade - `ItemsDetailViewController` around line 176 is the whole recipe, and the band is the part that is easy to miss |
| Liquid Glass: the settings and menu row cells - **done, all six screens** | Round 62 did the cheap experiment below on the **Information screen only** (`ItemsViewController`), and the answer is that a translucent row does read against the game backgrounds. The glyph question turned out to be smaller than feared: the PNGs are flat single-colour shapes, so `.withRenderingMode(.alwaysTemplate)` throws the purple away and keeps the silhouette - no redrawing, no new assets. `SettingsTableViewCell` now carries `applyGlass()`, `setIcon(_:)` and `showTapFeedback()`, and `prepareForReuse` puts the whole card back because six screens share the nib. Round 64 rolled it out to Settings, Mode Select, Brick Types, Items Detail and the Splash resume button, and glassed those screens' close buttons to match. **What the roll-out actually cost was not the rows - it was everything the screens draw over them.** Six things had to learn about glass: the icon (template only for flat glyphs - `setIcon(_:recolour:)` has no default, because a wrong `true` flattens pack art and a wrong `false` hides a glyph), the press feedback (`setPressed`, which skips the colour, since painting the app's lime into `cellView2` puts the flat card back for the length of a touch), the state column (`setStateColour`, which *inverts* the scheme - the flat card meant "on" by being darker, including a four-step grey ramp for paddle speed), the row name (`setLabelColour`, keeping the quarter-alpha fade that means locked), the completion tick, and the swipe-up info button. The lesson for any further glass work: the material is one line, and the contrast scheme built on top of a light card is the actual job. **Still open:** whether the tint should drop below 0.24, and whether rows want the buttons' explicit rim. Locked rows on the unlock pages stay noticeably paler than the rest, because "locked" is drawn as the cell's own light `.regular` blur over the row - it reads as a state rather than a mistake, but it is lighter than anything else on a glass screen. Round 66 finished the close buttons - every screen in the app now has a glass one (About, Background, Intro, Level Selector, Level Stats, Pack Select, Stats and Item Stats joined the six from round 64). Round 67 finished it. **Every round button in the app** goes through one door now - `MainMenuCollectionViewCell.setButton(_:pointSize:rimmed:)`, which assigns the PNG first (so iOS 15 keeps exactly the button it has) and then glasses it if `systemGlyph` names a stand-in. Adding a glass button is a line in that table. `ButtonNull` is absent from it on purpose, which is how the invisible spacer stays invisible. The **pack grid** squares are glass, with the pack icon template-recoloured, and the pause screen's **home button** was the last PNG left. **Deliberately not glass:** the *pause menu itself*, which turned out to have no panel to glass - it is a full-screen dark blur with labels straight on it, and a second material over the first would only mud it; and the background chooser's **preview card**, which shows the background being chosen, so a material over it would obscure the one thing the screen exists to show. **Ruled out by James (round 68): the in-game power-up HUD stays as it is** - it sits over live play, it is the one surface that would cost frames, and it already reads. That closes the HUD question rather than leaving it pending a measurement. Round 69 did all five of James's round-68 list: the main menu's mode cells, a pack's level list, the statistics tables, the Daily Challenge cards and the pop-up's dismiss button. `SettingsTableViewCell.addGlass(behind:cornerRadius:tint:)` is the shared recipe now - it returns the effect view, or `nil` below iOS 26, so a caller uses the answer as its own "am I glass?" flag. **Only the pale pop-up button is glass**; the green one is how the pop-up says which button does the thing, and two identical shapes would not. Round 70 made a stats table **one panel with hairlines** rather than a card per row - the play test read a stack of framed rectangles as "too many edges", which it was. `addGlass(under:cornerRadius:inset:)` puts the material in the table's *superview* so it does not scroll away, inset 20 to stand exactly where the old per-row cards did, and `StatsTableViewCell.showDivider(_:)` is told by the table itself whether it is the last row. **The big play glyph: settled by measurement, not by explanation.** The collection-view path renders it smaller than `applyRoundGlass` does at the same point size, weight, colour and shadow - rounds 68-70 matched each of those in turn and the play test measured it smaller every time, on the five screens that come through the cell while the four using `applyRoundGlass` were right. `MainMenuCollectionViewCell.bigGlyphPointSize` is 34 against the helper's 28 because that is what matches on screen. If the cause ever surfaces, that constant is where to undo it. **Tidy-up owed:** `addGlass`, `glassTint`, `glassForeground` and `glassIsAvailable` are statics on a *table cell* because that is where the first two already lived and adding a file means four hand-edits to `project.pbxproj`. Six unrelated types now import their look from there. It wants its own file `SettingsTableViewCell.cellView2` is the light-grey rounded rectangle behind every row on six screens, and the glyph beside each label is a **dark purple PNG chosen to sit on light grey**. Make the cell glass and every one of those glyphs is dark-on-dark - the exact problem round 53 fixed on the play button, except there is one button and there are dozens of these. So the order is: decide the glyph treatment first (recolour the assets to white, or tint them white at runtime if they are template-capable, or keep the rows light and glass only the *panel* behind them), then apply. **Cheap experiment worth doing first:** glass one screen's cells with the glyphs left as they are, purely to see whether a translucent row reads at all against the game backgrounds - if it does not, the asset question never needs answering |
| Liquid Glass: the glyph inventory, then the rest of the UI | Rounds 52-57 settled the **recipe** on one button (`applyRoundGlass`): `.regular` material, tinted with the app's purple at 0.38 - *the one dial for edge brightness* - shaped by `cornerConfiguration` rather than clipped, `isInteractive` on, and a glyph baked white with `.alwaysOriginal` plus a soft shadow so it never depends on what the material is doing. **The gate on everything else is artwork, not code.** Every other round button is a PNG with the circle and the glyph welded into one opaque disc, and glass cannot sit behind that. Order of work: (1) decide which glyphs become SF Symbols - close, play, settings, info and leaderboard all have good system equivalents, and `xmark` in particular carries no brand identity worth keeping - and which need redrawing as monochrome templates; (2) apply the helper, which then costs a line each; (3) **a small button is the next thing to see** - the recipe is proven at 75pt and a 40pt disc has proportionally more rim to material, so the tint may want to differ by size. Beyond the round buttons, the candidates in rough order of value: the **pause menu's own panel**, the **pop-ups** (`GigaBallAlert`), the **settings and menu row cells** - currently flat light-grey rectangles, and the single biggest visual change available - and the **HUD capsule** in-game, which is the riskiest because it sits over live gameplay and glass is expensive per frame |
| Liquid Glass on the round buttons - **started, one button done** | James's 1.3 scope call. `applyRoundGlass(to:radius:)` is in `ReturnToGameButton.swift` and the big return-to-game play now wears `UIGlassEffect`, gated to iOS 26 with the pale disc as the fallback - the app supports iOS 15, and a button invisible on an older phone is a regression dressed as a feature. **The rest is an asset job before it is a code one:** every other round button is a PNG with the circle *and* the glyph baked into one opaque disc, and glass cannot sit behind a glyph welded to a disc. They need template glyphs (SF Symbols where one fits, monochrome assets otherwise), after which the helper applies unchanged. That is what FUTURE-RELEASES.md means by "in-app icons updated to Liquid Glass versions", and it is worth knowing before the rest is quoted as a code change |
| Descent measured in rows rather than seconds | James's suggestion, round 52, and the better model - a fixed number of rows is what the player actually experiences, where seconds are what the code happens to count. **The complication:** `EndlessIIClock` already supports counting turns instead of time (the sticky paddle's catches do it), so the descent tick would spend a turn per row rather than run a clock down - and the ring would show segments, which is a bonus: you would see how many rows are left. But `endlessIITimedClocks` is the single list a **Lock** freezes and its drop rule reads, and that rule asks `remaining > endlessIILockLead` **in seconds**. A row count in the same list makes that comparison meaningless. So this needs the Lock's rule to ask each clock what it means by "nearly finished" rather than assuming seconds - which is the right change, and bigger than swapping a unit |
| ~~Flipped Angle is too weak~~ | **Fixed** (round 47), and the diagnosis is shared with Inert Paddle - see the row below. The bounce term is `angleAdjustmentK * collisionPercentage * influence`, and Flipped only ever set `influence` to **-1**: a mirror of the steer you asked for. Mirroring something small is small. It is `-1.8` now, so a deliberate steer comes back close to twice as hard the other way - unmistakable the first time, and still proportional to how much steer was asked for, so a gentle catch is still a gentle mistake rather than a disaster |
| Most effective power-up, in the endless modes - **built, round 73** | Play-test round 46, three design questions answered by James in round 51. **(1) Instant power-ups score nothing** - Cull, Clear And Retreat, Infill and Wipe have no window to measure, and an invented one would invite false comparison. No note on the page saying "timed only": the list simply does not include them. **(2) Overlapping power-ups each get the full metres.** The totals will therefore sum to more than the height climbed, and that is accepted - the page says *while active*, not *because of*, which is honest about it being correlation, where splitting credit would invent a precision the measurement does not have. **(3) Descent counts**, unexcluded, and is instead *tuned* so it does not swamp the field - made rare and given its own shorter duration in round 51. **Build notes, from round 72's dig through the code, so the next attempt starts warm:** the hook is `GameScene.endlessHeight+=1` at GameScene.swift:3070 - one metre, one place, both endless modes. What is active at that moment is already assembled for the pause screen: `InGameRecents.shared.activePowerUpRings` is a list of `(index, remaining, segments)` where **`index` is a power-up index into `LevelPackSetup.powerUpNameArray`** - the same numbering the stats and unlock arrays use - so no new mapping is needed. Mayhem's own clocks are written into it by `InGameRecents` (around line 269) and the tray power-ups are appended by the caller from their timer bars, which is the only place that reading exists; check it is refreshed on the frame the metre is scored before trusting it. Storage: two 51-slot arrays in `TotalStats` (one per endless mode, since the page has a tab each), **declared optional** like `bestBallHits` for the decode-safety reason its comment gives, added to `TotalStats.padded` and to the iCloud copies in `CloudKitHandler`. Display: `StatsPage.rows(for:stats:)` currently hands the endless tabs only `heightRows(stats.endlessModeHeight)` and `heightRows(stats.endlessIIHeights)`, so it needs the metres array passed alongside. Merge rule: sum for totals, highest-wins for any best |
| ~~Inert Paddle does nothing~~ | **Not a bug, and left as it is** - James's decision, round 48. It removes the player's ability to steer by where the ball lands (`influence` 0 in the bounce term), which is invisible on a central catch because `collisionPercentage` is near zero there anyway. So it punishes deliberate play and leaves safe play alone, which is a defensible thing for a bad power-up to be. Recorded rather than deleted because it will look like a bug again to the next person who plays it: the answer is that a power-up removing a capability is only felt by a player using that capability |
| ~~Ring HUD in Classic and original Endless~~ | **Built**, to the decided design: same tray, same order, same geometry (`layoutUnit` untouched), only the indicator changes - the bar under each icon became the ring dial around it, in the Giga-Ball colour, segmented for the sticky paddle's catches. The bars are still in the scene, invisible, because their hidden state and scale are the signal the activation code writes and the save format reads - the rings draw from what they say, exactly as Mayhem's row does. Worth an eyeball in the next play test with a power-up actually caught |
| ~~In-game recents on the pause info pages~~ | **Built.** Reached from the pause menu, the power-ups page leads with what this run has seen (most recent first, unseen below alphabetical) and the bricks page leads with what was recently struck within each section. The scene records into `InGameRecents` - a power-up as it enters play, a brick on the strike, ahead of the Portal and power-up brick early-returns since those are exactly the bricks worth looking up. From the menus both pages read as they always have. The recency order itself is unit-tested; worth one mid-run look in the next play test |
| ~~Endless game-over stats~~ | **Built.** The game-over screen carries the run's numbers in one line - paddle hits, bricks destroyed, power-ups collected - and a stats button (the achievements rosette standing in until §8.5 has one) opens the detail: the headline numbers, then the run's power-up *superlatives* - most seen, most collected, most missed, each needing a count of at least two to earn the rosette (ninth round replaced the full in-order diary, which did not justify the screen). All read from what the run recorded - the screen computes nothing |
| ~~Aimed Sticky must freeze *everything*~~ | **Fixed.** The freeze covered nodes; most of the world is driven from `update` - the descent, spinners, movers, the timed clocks - and the laser cadence from a Foundation Timer, none of which node-pausing touches. The hold now gates the update-driven ticks in one place, pins the last-tick clocks to now so everything resumes where it stopped, and the laser generator skips its beat while a ball is held. Known leftover, deliberately: the *classic-style* power-up expiry bars (lasers included) run on scene actions and still drain during a long aim - Mayhem's own clocks freeze properly. Worth folding into any future pass on the classic timers |
| ~~Portal Paddle exit angle~~ | **Built.** Where the ball goes through the paddle now decides where it comes out: the swallow keeps the contact's collision fraction, and the exit applies the same angle-adjustment line the ordinary bounce uses - mirrored downward for the top exit, upright for a Portal-brick climb. Sampled from the pre-step heading, applied from `didSimulatePhysics` (§8.6). And the last turn swallows too - spending the final turn expired the clock before the paddle acted, so the last turn of Portal Paddle, Aimed Sticky and Auto-Aim all did nothing; each now delivers what it was spent on |
| ~~Wrap-Around: the paddle should straddle both walls~~ | **Built.** While the paddle overhangs an edge, a ghost sprite shows the overhang re-entering the far side, dressed like the paddle every frame and carrying a physics body of its own - so the re-entering half bounces balls. `paddleHit` measures every landing against the nearest paddle copy (`endlessIIPaddleXNearest`), so a bounce off the ghost's half bends by where the ball really sat on it. The walls wear the portal pair's colours while the wrap runs - blue left, yellow right - as asked |
| ~~Portal Paddle × Auto-Aim~~ | **Built**, to the proposed resolution: both speak in sequence - the hit still portals, and Auto-Aim aims the *re-entry* at the lowest brick worth hitting, from wherever the ball comes back in. James's alternatives (aim arrow at the top, player-chosen drop point) stay in reserve if it reads badly in play |
| ~~Sticky Paddle × Inert Paddle~~ | **Built**, to the play-test decision: both stay active - the catch still works, but the launch leaves at the angle the *inert bounce* would have produced, sampled from the pre-step heading at the catch (§8.6) and consumed at the launch, so where the ball sits on the paddle says nothing. While both run the sticky graphic wears monochrome (grey, blended per frame from the clocks like all paddle dressing), which is how the pairing says the wall is answering |
| ~~Big bricks overlap the lower-limit line~~ | **Fixed, round 80.** The line draws at zPosition 1.2 - above the bricks at 1, below the ball and paddle at 3 - so a Big brick's overhanging lower half no longer covers the kill line at the one place it matters. Drawing over the field rather than clipping around it was the cheaper of the two options the note offered and the better one: it is a one-point line at a fifth opacity, so it reads as the limit passing behind the field, and nothing has to know how tall a brick is. Destruction was already right, because the row centre is what is read. Original note follows.   Play-test screenshot: a Big brick's body extends past its row centre, so on the bottom row its lower half crosses the limit line. Options: clip the line behind oversized bricks, or accept the overlap and make sure destruction still triggers at the right moment (it does - the row centre is what is read). Cosmetic, but the line is the kill line and should stay legible |
| ~~New brick geometries~~ | **Built** (§4.12a): Convex, Concave and Wedge, as three new styles rather than a fourth axis - so they inherit the progression ramp, the motif phases, the compatibility grid, the reference page and the recents naming without any of it being written twice. The geometry is a pure tested type: every body piece is proved convex (a concave path is silently mangled by `polygonFrom`, not rejected), and each face's sprite-hiding rectangle is proved to be inside its own silhouette (the Wedge's hypotenuse runs through the node centre, so no centred rectangle fits it at any scale). **Still open from the original row: the 2×1 square size** - the power-up brick already builds one, so the machinery exists; it wants the reserve-and-build sequence generalised out of `EndlessIIPowerUpBricks` and offered as a size |
| ~~Aura rework~~ | **Built** to the decided shape (round 22): the ball bounces off bricks as ever, and a brick the glow reaches takes *one hit* rather than being destroyed - a Multi-hit steps down a stage, an Indestructible shrugs, a special fires its own rule. Once per pass, not once per frame: the glow sits over a brick for many frames, and hitting every frame stepped a Multi-hit through all four stages in a fifth of a second, which is destroying it outright with extra steps. Aura and Giga-Ball together now come to what the aura used to be alone, which is the intended good combination. The old test asserting it destroyed what it touched was rewritten to guard the *reach*, which is what it was really protecting. Original note: Play-test round 11, the third Aura report: still too powerful. The decided shape: the ball *bounces off bricks normally*, and bricks adjacent to the struck one - within the aura's boundary, in front and just to the side - take **the effect of a single hit** as if the ball had hit them (multi-hits step down, specials fire their on-hit rules), rather than being destroyed outright. Aura + Giga-Ball together should equal today's Aura, and that is the intended good combo. Most of the work is routing the neighbours through `hitBrick`'s rules without the ball's contact side |
| ~~Auto-Aim target choice~~ | **Built** (round 22). The judgement lives in `endlessIIWorthAimingAt`, so it can be asked without a running game, and it now also skips a brick that is *passable at that moment* - a Flashing brick in its faded phase has no collision category, so the shot passes through it - and a Directional brick vulnerable only from the top, because a shot from the paddle arrives at the underside. Left and right stay in: a brick up and to one side can be met on its flank. A ring is drawn on the target from `update` (never an action on a brick, §8.6) so the shot is visible while there is still a decision to make; the beam it already drew is after the fact. Original note: it should skip bricks that are pointless to hit - indestructibles, anything whose hit does nothing, and bad-power-up bricks - and aim at the next nearest worth hitting. Plus a subtle graphic showing the general direction the ball is being steered (the pull-line language `drawEndlessIIPullLines` already speaks is the natural fit) |
| Ghost Ball power-up idea  **Pulled into 1.3** (round 101, James's call). | Play-test round 11, new bad power-up: the ball is invisible until it drops below the lowest brick line - you see where it lands, not where it flies. Pool/duration/conflicts undecided; visibility is a per-frame alpha rule from `update`, like all Mayhem dressing |
| ~~Tap-to-skip the intro splash and build-in~~ | **Built** (rounds 15 and 17). The build-in's skip lands the whole field on its rows; the intro's hold now clears on a tap, running the dismissal it was going to run anyway and in the same order, because the opening field waits on `levelIntroWillClear` and the lives roll in on `levelIntroDidClear`. Original note: Play-test round 11: a tap during the level intro splash and the brick build-in should skip to their end states - the same jump-to-end-and-hold rule the app splash learned, including §12.0's second-round caution that a skipped build-in must land every brick on its row |
| ~~Big play on every pause sub-screen~~ | **Built** (round 17). One extension rather than seven copies: it finds the paused game by walking up the child chain, adds nothing where there is no run behind the screen, and the background selector takes it off itself because that screen is a picture of the playfield. Original note: Play-test round 11: settings, info and the reference pages reached from the pause menu should each carry the big centred play so the player can return to the game from anywhere, small close on the left, the screen's own extra (leaderboards etc.) on the right - the same row grammar as everywhere else. The one exception, by name: the background selection screen. Touches every MenuNavigable presented over the pause |
| ~~Stats page sections~~ | **Built** (round 28): five tabs - All, Classic, Endless, Mayhem, Daily - above the same table. The twenty-five hard-coded rows became `StatsPage`, which turns a `TotalStats` into a list of rows away from the screen, so what the page says can be tested; eleven tests do. Which stat belongs to which tab is read off where `InbewteenLevels` writes it, not decided by hand. Two sections are new numbers rather than moved ones: **Endless Mayhem** was recording heights and showing them nowhere, and the **Daily** shows days played, days posted, attempts, best day and total posted score. Rows for a mode never played are no longer added, which retires the old blanking trick of setting the *table's* row height to zero to hide one row. Streaks are the obvious missing daily stat and are daily spec phase 5, not this |
| Icon pass: settings rows and mode menu | Play-test round 11's icon list, gathered for one visit (drawn placeholders now, §8.5 art later): ball-and-paddle theme row gets a paint brush in the settings style; the info page's upward-arrows stats icon becomes *the* stats icon everywhere; game background row moves below the theme row and its icon gains a tiny paddle/ball/bricks scene; ~~the daily's main-menu icon becomes round like the others~~ (**built**: the calendar drawn on the endless icon's olive disc with its pale rim and green glow, rather than the green rounded-square power-up badge it was borrowing - beside three round icons that read as a pickup that had wandered into the menu); the Mayhem menu icon becomes the endless icon with the infinity centred and a second ball beneath - symmetric about the horizontal axis. **Round 12 adds:** every mode menu leads with its icon above its title - icon, then title, then the rest - the way the daily briefing and (round 13) the pause and game-over screens now do; the storyboard mode menus, Classic included, still need that visit. **Round 13 adds:** the new Icon Composer app icon should replace the old artwork wherever the icon appears inside the app - the About screen, the Vanilla twist badge, the Classic-mode menu icon. The `.icon` bundles cannot be read at runtime, so this one waits on an exported 1024pt PNG in the asset catalogue; the selector's own previews already use their own images and are correct |
| ~~Lock and Key~~ | **Built** (round 25). One `endlessIIClockDelta` returns zero while a Lock runs and every timed clock in the mode counts down through it, so there is one place that decides and no clock that can be forgotten; the Lock's own clock deliberately does not use it, or a run without a Key never gets its timers back. A Key clears the clock outright rather than shortening it. `endlessIITimedClocks` is the single list the freeze and the drop rule share - a timed power-up left out of it would neither attract a Lock nor be frozen by one, which from the outside looks like the Lock being broken, so a test walks every entry. Lock drops only while something has more than the fall time left; Key is weighted 30 inside its window and 0 outside it, both set per row because they are the only drops whose eligibility is live game state. **Closed** (round 31): Wipe is built, and "Wipe must not remove a Lock" is now a rule with a test on it - a Wipe that removed a Lock would do everything a Key does and more, and a Key nobody needs may as well not drop. Original note: §5.4's originals, still unbuilt. Lock freezes the timed clocks (the turn-based ones are immune by nature); Key ends it. Their conditional drop rules are most of the work |
| ~~Endless Mayhem badge on the power-ups page~~ | **Built** (round 30): an infinity mark in the state column of every Mayhem-only power-up, and a "Found in: Endless Mayhem" line on the page you open - a badge in the list and the sentence on the page, the division the brick types page already draws. The mark is the readable half of the mode's logo at eleven points; §8.5 can replace it. **Not** taken from `PowerUp.availability` as this row assumed: that field lives in `PowerUpCatalogue`, which has drifted from the shipped game (see the row below). It is taken from the index instead, which is what the game itself uses - `powerUpNameArray` is the original twenty-eight followed by Mayhem's twenty-two, and the drop probabilities are only ever set for the first twenty-eight |
| Paddle surface shapes **Pulled into 1.3** (round 100, James's call). | New power-up family (play-test idea, fourth round): convex, concave, wavy and jagged paddle tops, all *bad*, all turn-based, each making the outgoing angle harder to predict. One shape function per variant feeding the existing angle line, so they cost a curve rather than a physics body - but they conflict with the paddle group (Inert, Flipped, Auto-Aim at least), which is where the design work is |
| More twists, and more variety | Standing request from every daily round. The pool is nine live plus Vanilla; §4's table has ten more written and unbuilt. Worth a batch at a time, weights tuned against a batch actually being played |
| Ball Spin / Curve | New power-up (play-test idea, second round): the paddle's own velocity at contact grips the ball - as if there were friction between the two - and the ball leaves on a curved path, curving harder the faster the paddle was moving. Wears a grippy paddle texture while active. Conflicts with the paddle group (Aimed Sticky, Auto-Aim, Inert at least). Build note: the curve is a per-frame perpendicular nudge from `didSimulatePhysics` (§8.6 - never inside a contact), decaying over the flight, and the paddle velocity must be sampled from the touch handler, not the contact |
| Double Paddle, and an opposite-moving paddle **Pulled into 1.3** (round 100, James's call). | Play-test ideas for the next power-up batch, refined in the second round: the paddle *splits in two*, each half the width of the original - a second paddle is per-ball contact handling all over again, priced accordingly |
| ~~Field build-in for Classic and original Endless~~ | **Built** (round 22). One entry point, `prepareBuildIn`, chooses by mode: the endless modes rain their rows in as Mayhem always did, and Classic pops its bricks up *in place*, row by row from the top, with the same knock a landing row gives. Both wait for the splash screen through the existing poll, both answer the existing skip, and Classic's destinations are recorded even though they never move - a brick with none falls back to the nearest *endless* row centre, which means nothing on a Classic field. Original note: two halves. (1) Original Endless adopts Mayhem's opening build-in as it stands - rows entering at the top and stepping down in lockstep (`tickEndlessIIBuildIn` and friends); the port is mostly making that code read its row set from the classic-endless generator rather than Mayhem's. (2) Classic gets its own, different animation: the level's bricks appear *in place*, quickly, with a haptic tick as they land - no descent, because classic fields do not descend. Both must respect the skip path (§12.0's second-round build-in bug: skipping mid-fall parked bricks off their rows - destinations cleared one line too early), and neither may leave a repeating action on a brick (§8.6) |
| Global rank on the game-over screen | Play-test request, ninth round: show where the run stands on the global board, in-app. The daily already does it - `loadDailyRank` feeds the pause menu's summary and the briefing badge. The endless and classic game-overs need the same ask against their own boards: a `loadRank(leaderboardID:)` generalisation of the daily loader, called with the mode's board when the game-over screen goes up, appending to the score block when it answers. Board IDs live in `LevelPackSetup`/`GameCenterHandler`; Mayhem's own board is still on James's App Store Connect list (§8.5 side), so Mayhem shows nothing until it exists |
| Paddle-speed try-out screen | Play-test request, thirteenth round, and the largest of that round's items: tapping the paddle-speed setting opens a screen where the speed can be *felt* rather than guessed. A slider at the top from 1.0 to 3.0 in 0.1 steps, and beneath it a small square practice scene - the player's own background, paddle and ball themes, a paddle near the bottom, a ball already bouncing, no bricks. Losing the ball just relaunches it. The mock scene on the background-selection screen (`GameBackgroundView` plus its themed mock) is most of the furniture already; what is new is a live ball and paddle in it, driven by the same touch-to-paddle arithmetic the game uses so the number under test is the number that ships. Note the setting is currently an Int 1-3 (`paddleSensitivitySetting`); 0.1 steps means widening it, which touches the save format's defaults and every read of it |
| ~~Info detail pages, relaid out~~ | **Built** (round 27): the page now reads icon, name, description, facts, top to bottom, with the icon centred and at 100pt - the size the power-up art is drawn at, so it is shown rather than scaled. The name lost its fixed height, which it had only because it used to sit beside a 52pt icon; a two-line achievement name had nowhere to go before. The description centres while it is short and sets flush left once it runs past two lines, because a centred paragraph starts every line somewhere new: `descriptionIsCentred` is the rule, and it is measured rather than guessed at, so a longer description written later gets the right treatment without anyone remembering to change it |
| ~~Power-up ring style, unified and glowing~~ | **Built** (round 26). Both builders already drew the halo-and-ring pair, so the styles were already one thing; what was missing was the bloom the request kept asking for. `glowWidth` goes on the soft wide pass only - the thin bright ring on top stays crisp, because it is the one carrying the reading and a blurred timer is a timer you squint at. Original note: | Play-test request, thirteenth round: Classic and Endless draw the timer as a ring *around* the icon (the round-6 port), Endless Mayhem draws its own row differently, and the round prefers the ring. So Mayhem adopts the ring-around-the-icon treatment, and every mode's ring gains a subtle glow behind it. `PowerUpRingHUD` draws both today, so this is mostly deleting the divergence; `SKShapeNode.glowWidth` is the cheap glow and wants one visual iteration to find a width that reads as light rather than blur |
| ~~Falling power-ups glow~~ | **Built** (round 26). A halo child of the drop, so it falls with it and is removed with it. The colour is derived from the multiplier column, where the good/bad judgement already lives, rather than from a second list of which drops are good - a list would be wrong the first time a judgement changed, and this way a new power-up gets the right halo the day it exists. Original note: | Play-test request, thirteenth round: a subtle halo behind each falling power-up in the colour of its own icon. The drop is an `SKSpriteNode` with the icon's texture; the halo is a second node behind it, tinted from the same palette the icon uses, so the two cannot disagree about what colour the power-up is |
| ~~Stats on every game-over screen~~ | **Built** (round 15). `RunSummary` gained a score, a count of levels cleared and a flag for which kind of run it was, and the detail screen reads that flag rather than assuming - it was showing a classic run a height of 0m and a dash where bricks-per-metre belongs. Original note: Play-test request, thirteenth round: the run-stats door should not be endless-only. Classic and daily game-overs get it too - and on the daily it is a small stats button to the *right* of the big Home, beside the leaderboard button. Needs `RunStatsViewController` to say something sensible for a classic run (score, level, bricks, power-ups) where today it assumes height |
| Safety paddle power-up  **Pulled into 1.3** (round 101, James's call). | Play-test idea, tenth round: a second, fixed paddle just below the lowest brick row. Good because it keeps the ball up in the field longer; bad because it stops the ball reaching the bricks from below - deliberately double-edged, like Gravity. Build notes: a static body at `finalBrickRowHeight - brickHeight` spanning some fraction of the width; it must ride the descent question carefully (the field moves, the paddle does not), and its contact must *not* spend paddle turns or count as a paddle landing - it is furniture, not the paddle |
| Drift power-up **Pulled into 1.3** (round 100, James's call). | Play-test idea, tenth round: bricks and falling power-ups drift sideways while it runs. Field-batch shaped: a per-frame x nudge from `update` (never a repeating action on a brick, §8.6), wandering bricks' wall limits still respected, drops' `PowerUpDrop` action replaced by a drift-aware fall while the clock runs. Interacts with Wrap-Around (drifting off one side should wrap while it runs) and with the row discipline - bricks must land back on column centres when it ends, or the crush and generation logic drifts with them |
| ~~Stats table icons~~ | **Built** (round 30): every row on the statistics page carries an SF Symbol in a fixed gutter - fixed rather than each icon sitting against its own label, because the symbols are different widths and left to themselves they make a ragged edge down the page. The name is a property of the row in `StatsPage`, beside the label it belongs to, so it cannot drift from it. Every name is from the first two SF Symbols releases: the app runs on iOS 15 and a later symbol draws *nothing* rather than failing, which a modern simulator would never show. A test asks for all thirty-three images |
| ~~Glow around the power-up rings~~ | **Built** (round 26), with the ring style item above - the same `glowWidth` pass serves both, which is what they were always asking for twice. Original note: | Play-test request, tenth round: a subtle glow around the ring dials. `PowerUpRingHUD` draws them; SKShapeNode has `glowWidth`, which is the cheap version - worth one visual iteration on the simulator to find a width that reads as glow rather than blur |
| ~~Classic pack-completion score tally~~ | **Built.** Every game over and every pack completion now counts its number up, not only Single Level Mode and the endless height. The hold-back was that a level inside a pack carries its score into the next one, so counting it would be counting a total still running - but this screen is only reached when there is no next one, which is what made the old condition wrong rather than cautious |
| ~~Classic mode menu redesign~~ | **Built** (round 29): the screen is headed "Classic Mode" with the mode's own logo under it, the way the two endless screens are - it used to be headed "Level Packs", which says what is on the screen rather than which mode you are in. The eleven packs are square cells three across, so all of them are visible at once instead of a list you scroll. A cell opens the pack's level list; the play badge in its corner still starts the pack straight away. *(Round 33 swapped those: the cell plays, the corner button lists. Round 36 moved the list mark to the top-left with the completion tick mirroring it top-right, sized the logo up with more air below - shrinking on scroll to give the room back - and removed the bottom play button for the second time in the screen's history.)* The pack icons moved into `LevelPackSetup` beside the pack names, because the same eleven file names were written out as a switch on this screen *and* on the mode menu |
| Grid background scaled to the marker grid | Needs the actual artwork's pitch measured against brickHeight - a visual-iteration task, not a blind one |
| ~~`PowerUpCatalogue` has drifted from the shipped game~~ | **Resolved**, James's call: the two it was missing went in (**Cull** and **Auto-Aim**, both built, both Mayhem's), and **Randomised Bounce** stays because it is to be built - see the row below. The file is a design document that may run *ahead* of the game and may never fall *behind* it, and `testTheCatalogueMayRunAheadOfTheGameButNeverBehindIt` is that rule: an entry leaves the ahead-list by being built, and the behind-list must always be empty. Auto-Aim went in without the conflict it looks like it should have with Aimed Sticky - Aimed Sticky owns the launch from a held ball, Auto-Aim redirects an ordinary bounce, and the scene runs both; declaring a conflict this file cannot enforce is how it drifted in the first place |
| Build Randomised Bounce, the fifty-second power-up | The last catalogue entry with no game behind it, and now the only one. §5.4 has it as uncommon, harmful, timed, extending its own duration: while it runs, the angle the ball leaves a surface at is randomised rather than reflected. Build notes: the approach direction must be sampled in `update` before physics, not read off the contact, or it bounces twice (§8.6) - `ballStateBeforeStep` is that sample, and it is the same trap Portal already has to avoid. It is a clock, so it joins `endlessIITimedClockPaths`, which is what makes a Lock freeze it and a Wipe clear it without either being edited. Follow Wipe's round for the array checklist: about a dozen parallel lists, the two counters in the stats file, the probability array and the texture array |
| ~~Sticky Paddle: the ball bounces before it sticks~~ | **Fixed** (round 35), James's call on scope: the intent of the original modes is preserved, not every bug. `catchStickyBallBeforeStep` runs from `update` after `recordBallStatesBeforeStep`: if a catch is armed, the ball is descending, and this step would carry its underside through the paddle top, it is caught *there* - moved to where it was landing, stopped, stuck - and no bounce ever happens. The landing x is interpolated from the pre-step state, judged against the same band `paddleHit` uses, wrap-ghost included; Aimed Sticky is left to its own contact path, as are Multi-Ball's extra balls (their queue has its own ordering). The lookahead is a fixed sixtieth, not `endlessIIPaddleFrameDelta` - that delta is set under a Mayhem-only guard and is zero in Classic, which would have made the fix a no-op in the mode that reported it. An early catch is invisible because the catch pins the ball to `ballStartingPositionY` regardless. Original note: | Play-test round 33, **diagnosed round 34.** The catch is made in `paddleHit`, which is called from `didBegin(_:)`. The ball and the paddle *collide* as well as report contact, so by the time that contact arrives SpriteKit has already resolved the bounce and moved the ball - the catch then zeroes the velocity and snaps `position.y` back to `ballStartingPositionY`, and the snap is what is being seen. It is §8.6's first trap in a new place: a contact reports the state *after* the engine has acted. **The fix is to catch in `update`, before physics**, from `ballStateBeforeStep` - if a sticky catch is armed, the ball is descending, and its pre-step position is above the paddle top while this step would carry it below, catch it there and let no bounce happen at all. **Do not** solve it by taking the paddle out of the ball's `collisionBitMask` while sticky is armed: the sticky band is narrower than the paddle, so a ball landing outside the band must still bounce, and a ball passing through the paddle is far worse than a ball that flickers. Sticky Paddle is one of the original twenty-eight, so this changes Classic and the original Endless too - it needs a few levels of play-testing in both before it ships, per the Scope note in CLAUDE.md |
| Auto-Aim with Sticky Paddle, as one control | Play-test round 33, James's design: with both running the player can aim *and* reposition. Letting go of the screen leaves the ball on the paddle; the ball only launches on a **tap**. A swipe **on or below the paddle** moves the paddle; a swipe **above the paddle** moves the aim arrow. Today the two run side by side with no shared gesture model, so this is a touch-handling job in `GameScene`'s pan handling plus the aim marker `refreshEndlessIIAutoAimMarker` already draws. Note the catalogue deliberately records no conflict between them - this is why |
| Shaped bricks face up or down | Play-test round 33: the new brick shapes (Convex, Concave, and the others whose silhouette has a top and a bottom) should exist both ways up. In Endless Mayhem the choice is a 50/50 roll per brick. Generation-side: the style already varies per brick, so this is an orientation flag beside it, drawn mirrored - and it must not disturb the row centre a brick's `position.y` carries (§8.6) |
| App icon and theme pickers as grids | Play-test round 33: the app icon picker and the ball & paddle theme picker are list views; they should be grids with the images bigger and more prominent - the artwork is the whole point of both screens and a 40pt thumbnail in a row wastes it. `ItemsDetailViewController` serves both (senderIDs 0 and 1). `PackGridCell` and the pack screen's flow-layout sizing are the pattern to follow, **including the floor** on the cell width |
| The Glow background, reworked | Play-test round 33: the version built in round 19 is not liked. What is wanted instead: a gradient from the Giga-Ball yellow-green into the dark purple, the whole thing staying dark so it never competes with the game's own graphics, and the yellow-green reading as *cloudy and blurry* over the purple rather than as a clean gradient band. `GameBackground.glowImage` is the one to replace; it already seeds its own randomness so the picture never reshuffles between launches, which must stay true |
| Thousands separators outside the game scene | Play-test round 33: James wants grouped numbers everywhere except in the game itself. The statistics page has them (`StatsPage.grouped`); still to do are the pack and level high scores, the endless run lists, the game-over and pack-complete summaries, and the daily's score lines. **Nothing drawn by `GameScene` may group** - the score changes several times a second and a separator appearing as it crosses a thousand is movement where the eye is already watching |
| iPad resize audit | Play-test round 35: iPadOS 26 resizes every app and ignores `UIRequiresFullScreen`, so multitasking arrived without being adopted. A window-scene minimum of 420x640 is set in `SceneDelegate` so the window can never go below a phone's width - but there is no API to cap the maximum or the ratio, so the audit is real work: every menu screen at split view, slide-over, and the tall-and-thin and short-and-wide extremes, checking `limitMenuContentSize` and the storyboards' constraints hold. The play zone is safe by construction (fixed 1.8236, `GameSceneLayout` asserts it); the menus are the exposure |
| ~~Run summaries said every run was endless~~ | **Fixed** (round 36), found under "remove bricks per metre in classic": `RunSummary`'s classic fields - `score`, `levelsCleared`, `isEndless` - were added in round 13 and **never passed at the one construction site**, so their defaults held and every run claimed to be endless. Three symptoms from one cause: a classic run's detail page led with "Height 0m", carried "Bricks per metre", and the pause summary never showed its levels-cleared line. The fields are passed now. The lesson is §12.0-worthy on its own: a struct field with a default is a field the compiler never makes anyone set |
| ~~Aimed Sticky arrow reach~~ | **Lengthened** (round 36), third time of asking: the arrow now runs from the held ball to almost the lowest brick row (`finalBrickRowHeight`, less a ball's grace), with the old round-10 length kept as the floor for a catch high up the field. Each previous lengthening was a fixed multiple of ballSize; going to the thing itself ends the series |
| ~~Return-to-game button dropping taps~~ | **Fixed** (round 36), most probable cause: the button is installed in `viewDidLoad` and starts frontmost, but the settings and info screens keep adding views after that, and a transparent view laid over it eats taps without covering it visually - "doesn't always work" is exactly what that failure looks like. `keepReturnToGameButtonFrontmost` re-fronts it from `limitMenuContentSize`, which every menu screen already runs on every layout pass. If the play test still catches a dead tap after this, the diagnosis is wrong and the next suspect is the gesture recognisers |
| ~~Resume put bricks off their rows~~ | **Fixed** (round 37): the save derived each brick's row from its on-screen `position.y`, which is only its row *once it has arrived*. Quit during the opening build-in and the bricks are still in flight, so whatever height each had reached was saved as its row - a resumed run came back with bricks below the bottom row (screenshotted at the very start of a Mayhem run). The save now reads `endlessIIBuildInFinalY`, the destination the animation is carrying each brick to, falling back to the brick's own position once the build-in has finished and emptied it. §8.6's "a brick's `position.y` is its row" trap, reaching the save format |
| ~~Wrecking Ball had no haptic~~ | **Fixed** (round 37): its branch in `hitBrick` returns before the type switch, so it reached no haptic at all. It gets the *heavy* one now rather than the light tap every other brick gets - of every hit in the game it is the one that should land hardest |
| ~~Power-up HUD on the pause screen~~ | **Built** (round 42): `PausedPowerUpHUD`, a UIKit row on the pause screen, with each icon opening a `GigaBallAlert` carrying that power-up's name and description. It **looks** identical without **being** the same code: every number is read from `PowerUpRingHUD` rather than copied - the colour, the glow radius, the stroke widths, the icon size and spacing - and the arc is literally the same `ringPath` function, mirrored into UIKit's coordinates so a second set of trigonometry cannot drift from the first. The reading comes from `InGameRecents.activePowerUpRings`, captured at the same moment the pause snapshot already takes. It does not animate, by James's scoping, which is what made a static row the right answer rather than snapshotting a live scene |
| ~~Average hits per ball, and the best single ball~~ | **Built** (round 38). The average is arithmetic on two totals and needs no storage; the **best** cannot be recovered from totals, so `TotalStats.bestBallHits` is new - optional, for the same decode-safety reason the Endless 2.0 and daily fields are, and with `longestBallRun` handling absent-means-none. `hitsOnThisBall` counts, `ballLost` closes the tally, and `runBestBallHits` carries the run's own best to the end-of-game stats including the ball still in play when it ended. The iCloud copy went in **with the field rather than after it** (CLAUDE.md's standing warning), and merges highest-wins in both directions, unlike the running totals beside it which only ever climb |
| Trajectory Line: two bounces, not one | Play-test round 38, James's answer to the round-37 question: one or two brick bounces is acceptable, beyond that is not. `BallPath` stops at the first brick today and its header explains why - the scene's corrections are applied *at* a bounce, so error compounds. Two is the agreed budget. Build notes: the predictor must replicate the angle nudges away from horizontal and vertical, and the seam resolution, or the second leg is confidently wrong; and the line should fade with each bounce so it shows its own declining confidence |
| Power-up HUD on the pause screen | Play-test round 37, scoped in round 38: **it may be built differently from the in-game HUD so long as it looks the same, and it does not need to animate.** That removes the hard part - a static UIKit row of icons with their ring fractions drawn once, rather than snapshotting SpriteKit or driving a live scene behind a menu. Tapping an icon opens a `GigaBallAlert` with that power-up's name and `powerUpDescriptionArray` entry |
| Trajectory Line past the first brick | Play-test round 37 asked why it stops. Answered in `BallPath`'s own header: the predictor is arithmetic, and the scene applies corrections *at* each bounce (angles nudged off horizontal and vertical, a two-brick seam resolved as one face), so error compounds per bounce. A line drawn through a busy field would confidently show a path the ball will not take, and "a line that says you will hit that brick and does not is a lie the game told". If it is wanted anyway, the predictor must replicate those corrections exactly, and the honest presentation fades the line with each bounce |
| ~~Pause-menu buttons animating across each other~~ | **Fixed properly** (round 38), and it was one missing line. Every screen the pause menu opens hides it first - `moveToItems` calls `hideAnimate`, `openRunStats` calls `hideAnimate` - and **`moveToSettings` did not**. So the pause menu stayed fully drawn underneath, its own play and close buttons in the bottom row, while the settings screen's identical row animated in on top of them: two rows of buttons in the same place, each running its own entry animation. Round 21 fixed a *different* screen with the same symptom, which is why it came back. The second door is now shut too: `PauseMenuViewController` conformed to nothing, so `MenuNavigation.goForward` had no one to tell - swiping forward into Settings put it over a pause menu still fully drawn. It conforms to `MenuNavigationPresenter` now |
| iPhone 17 device pass | Play-test round 37: the build is going to a tester on an iPhone 17. The 17 Pro *simulator* is what every visual check this session was made on, so layout is covered - but frame rate, thermals and the 120Hz ProMotion cadence are device-only questions. Note `StickyCatch.stickyLookahead` is a fixed 1/60, so at 120Hz it looks two frames ahead rather than one; harmless by design, but it is the one place the refresh rate is assumed |
| ~~A ball was lost and the run continued (Mayhem)~~ | **Fixed** (round 40): the primary ball's loss could be reported twice. Its handover to a survivor is deliberately deferred to `didSimulatePhysics`, because a position written inside a contact does not stick (§8.6) - and in the window between the contact and the handover the ball is still at the bottom with the survivor still in `endlessIIExtraBalls`. A second contact in that window found two balls in play, read it as another carry-on, and handed the ball a survivor for the second time: two losses counted, one handover done, and a one-life run carrying on with a ball it should not have had. The extras already had a repeat guard - retired, so caught by `parent == nil` - and the primary ball, which is never retired, had none. It has one now |
| ~~Force-quit resume rebuilt the field instead of restoring it~~ | **Fixed** (round 41), and it was the *save* rather than the restore. The brick arrays are only collected in `Playing` and `Paused`; every array not collected falls back to `previous?...` when the `SavedGame` is composed. So a save written in any other state married this run's height and score to **another moment's bricks** - which is how a resumed Mayhem run came back with a field it had never played, different types in different places. The fallback is right for Classic, where a save between levels has no field to record and the next level builds its own; an endless run has no such moment, because its field *is* the game. An endless run now writes all of the save or none of it, leaving the last good save alone rather than composing a half-stale one |
| ~~Wrecking Ball must destroy Indestructible bricks too~~ | **Fixed** (round 48). Round 44 cleared the obvious suspects and said the cause was upstream of `hitBrick`; it was not, and the note was wrong. It was *downstream*: the wrecking branch ran, scored, counted and called `removeBrick` - and `removeBrick` **declined**, because two guards inside it exempt the two Indestructible textures from ever being taken off the field. That exemption is correct for every other caller; an Indestructible surviving is the whole of what it is. `removeBrick(node:sprite:force:)` now lets one caller overrule it, and exactly one does |
| ~~Paddle Halo shrinks with the paddle~~ | **Fixed** (round 44): the reach was measured from `paddle.size.width`, the paddle's *current* width, so a Shrink Paddle took the halo down with it and it stopped reaching the bricks - two bad power-ups compounding into one that switched a good one off. It now measures from `paddleWidth`, the nominal width, because the halo is a field the paddle projects rather than part of the paddle: how far it reaches is not the paddle's business |
| ~~Auto-Aim rarely hits what it aims at~~ | **Explained and fixed in round 103**, and "rarely" was generous - see the round-88 row below for the full account. The round-39 theory here (centre-aim ignoring the ball's radius) was never the story: the redirect was not being called at all |
| ~~Restarting Mayhem leaves the old score on screen~~ | **Fixed** (round 50). "Until the first brick is hit" was the whole diagnosis: `write` hangs a strip of per-character nodes off the label and blanks the label's own text, and nothing on the restart path wrote to it again - so the previous run's height stayed up until the new run's first brick happened to call `showHeightLabel`. The restart handler clears the strip and writes the zero itself, because a restart always begins at zero and the HUD should say so before the ball is launched. The two milestone watermarks are reset with it, or the new run's first thousand passes unremarked because the *old* run had already crossed it |
| ~~Game over: swap home and replay~~ | **Built** (round 49): on an endless or Mayhem game over, replay takes the big centre slot and home the small one on the left, because after an endless run another go is what almost everybody wants next. A classic game over keeps the old arrangement - the pack is finished with, so home is the likelier answer. Both the pictures and the actions ask the same `endlessGameOver`, which already existed and already meant exactly this condition, so the button and what it does cannot disagree |
| ~~Trajectory Line: two bounces, fading with distance~~ | **Built** (round 42). `BallPath.predict` takes a `brickBounces` budget - two for the Trajectory Line, zero for the Landing Marker, which answers a different question and must still stop at the first brick. The slab test that finds the brick already knew which face the ray entered through; it simply was not asked, so the bounce reflects off the face actually met. **The fade is the honesty**: the line is drawn as short segments whose alpha falls and whose `glowWidth` grows with distance *along the whole path*, so the blur carries across a bounce rather than restarting at it. Drawn solid, a two-bounce line claims a precision the predictor does not have; drawn fading it says where the ball is going and admits it is less sure the further it looks. A second collection sharpens it, so a deepened Trajectory Line is a genuinely clearer one |
| Aimed Sticky arrow, fuzzy like the trajectory | Play-test round 39: the same treatment as above, so the two aiming aids speak one visual language |
| Power-up HUD on the pause screen | Play-test rounds 37-39. **It must look identical to the in-game HUD**, though it need not share its code and need not animate. So: a static UIKit row matching `PowerUpRingHUD`'s geometry and colours exactly. Tapping an icon opens a `GigaBallAlert` with that power-up's name and description |
| ~~Play button still wrong between pause views, and on the backgrounds view~~ | **Fixed** (round 45), and my round-39 hypothesis was wrong - re-fronting could not resurrect a removed button, so that was never it. The real cause: **eight screens each install their own**, and a screen opened from a screen is a *subview* of it, so three deep left three buttons alive at once in the same place, each running its own screen's entry and exit animations. Round 38 fixed the *other* button row - the small round icons - which is why this survived it. The backgrounds view is the same fact from the other side: it called `hideReturnToGameButton`, which removed the button from *its own* view, and the one still visible belonged to the settings screen underneath. The rule is now enforced on every layout pass, self-correcting: a screen with something open on top of it has no button, a frontmost screen installs one if it is missing, and a screen that has asked not to have one (`wantsReturnToGameButton`) never gets it back |
| ~~Info button on a swipe-up settings cell still toggles~~ | **Fixed** (round 49), second report. Round 21 added a time-based guard - a row toggle arriving within 0.4s of the info button's own press is the same press and is ignored - and it worked only when the button's `touchUpInside` was delivered *before* the row's selection. That ordering is not guaranteed, and when the row won the race the stamp was stale, the guard passed, and the setting flipped before the pop-up appeared. The press is stamped on **touch-down** now, which always precedes both, so the guard holds whichever order the ups arrive in. Stamped on the up as well, so a slow press still shields the toggle behind it |
| ~~Settings will not scroll~~ - **measured, round 92** | The scroll view was never broken. Set programmatically to 60 it clamped to 37 - its legitimate maximum - and *stayed there*, so it moves and holds; a hit test in the middle of the table returns the table itself, so nothing overlays it; its pan and `isScrollEnabled` are both on. What was wrong is that there is very little to scroll and the **edge fade was drawing across a last row that was already fully visible**: `remaining` did not count the bottom content inset, and after round 74 a list resting at the top sits at an offset of minus the *top* inset, so the fade thought a padding's worth of content was still below. A row that looks cut off when it is not is exactly what makes a short list read as one that will not scroll at all. Original notes follow, because the ruling-out is still worth keeping.   Six rounds on this, so here is the state rather than another theory. **Ruled out with evidence:** the scroll affordance (content 624 in bounds 611 with 32/24 of inset, so 69 points of travel and `isScrollEnabled` true, measured from the running app); the back swipe (logged - it is asked whether to begin on a vertical drag and answers no); `delaysContentTouches` (set true from `giveMenuListsBreathingRoom` since round 89, and the storyboard flags on the Settings and Information tables are **identical** anyway, which is the finding that matters - the two scenes differ in their *content*, not their table). **Not yet done, and the next thing to do:** hit-test the middle of the Settings table with `view.hitTest(_:with:)` and log the class that comes back. If it is not the table or one of its cells, whatever is on top is the answer. Three attempts at this failed for reasons that were mine - a build that had not recompiled, and taps landing on empty space because the app resumed into a paused game - not because the diagnostic is wrong |
| Two pop-up types, and only one of them is `GigaBallAlert` | Found in round 89 and worth knowing before touching either: the confirm pop-ups that matter most - **MAIN MENU, RESET BALL, RESET DATA, SWIPE UP** - are `WarningViewController`, a storyboard screen with its own title, text and three buttons. `GigaBallAlert` is the newer type used by the twists, the closed challenge, free play, the swipe explainer and a power-up's description. So round 82's icons above titles, round 89's coloured glass on the confirm button, and round 85's "main menu pop-up needs a home icon" all land on *different* screens than they look like they do. The home icon James asked for belongs to `WarningViewController`, which has no icon slot at all yet. Worth making them one type before either grows again |
| A loop-breaker to replace the random kick | Round 100. James confirms the removed random kick was load-bearing: it broke loops, and the Portal bricks make loops badly - a well-aligned portal pair can cycle the ball for ever even with the deactivation period. The replacement must be targeted where the kick was scattershot. Two layers: **(1) portal drift** - each transit through the same pair applies a small cumulative exit-angle drift, so geometry that maps onto itself cannot keep doing so, deterministic and felt only inside the loop; **(2) a loop detector** - at each bounce record a quantised (position, heading) signature in a small ring buffer, and when the same signature recurs about three times in a short window, apply the existing shallow-angle escape jitter once. Nothing touches the bounces that were never looping, which is what the old kick got wrong |
| Splash screen: the ball and paddle form the app icon | Round 100, James's idea, art his fallback if code cannot do it justice: a small ball-and-paddle graphic above the GIGA-BALL logo on the launch splash, animating in with the glow and settling into the app icon's composition. The icon is a paddle and a lofted ball, drawable as two rounded shapes and a circle, so a code attempt is worth one session before falling back to artwork |
| Prominent buttons in the Phone app's solid-glass look | Round 100, from a screenshot of the iOS 26 Phone keypad: fully saturated colour with glass lighting rather than translucent tint. Same API as the lime confirm and play buttons already use; the difference is an opaque colour base under clear glass so the material contributes lighting only. A tuning pass on `prominentTint` and `addColouredGlass`, worth doing beside the existing buttons for comparison |
| ~~Laser Beam appears to do nothing~~ **feedback rebuilt, round 102** | The first question was answered by reading: it is in the pool (weight 3, rare), the collect case fires, and the fire destroys each ball's column exactly as the description promises. What failed was the *read*: it fired the instant the paddle caught the icon, at the ball's column where the player's eyes are not, silently, for a third of a second - a rare power-up whose one showing is that easy to miss reports as doing nothing. Now it is the two-pass construction at field size (wide additive bloom under a bright white core), twice the linger, with the laser's own sound. James then clarified (round 103) that the beam **was working more recently** - the "does nothing" sighting was a single occasion some builds back, possibly a mistake, and has not recurred - so the drop-rarity suspicion stands down unless it comes back, and the rebuilt feedback ships as a straightforward improvement rather than a fix |
| Game-over screen: stats sit too close to the scores | Play-test round 97, endless modes: move the stats block down to sit just above the big bottom button, separating it from the score block above. Layout-only, in `PauseMenuViewController`'s game-over arrangement |
| ~~Landing Marker misses by a little, worse at shallow angles~~ | **Built (round 105)**, and the round-97 report was the diagnosis: "as if it's expecting the ball to travel a little further before it contacts the paddle". `endlessIIVisionBounds()` handed the predictor `paddle.position.y` - the centre line - where contact is the ball's bottom against the paddle's *top*, as `catchStickyBallBeforeStep` already judged it. The predictor adds the ball's radius itself, so the one missing term was `paddleHeight/2`: the prediction ran half a paddle deeper than the real surface, and at a 2:1 shallow approach that half-paddle of depth cost a full paddle-height of sideways error. One line in the bounds fixes the Landing Marker *and* the Trajectory Line's final segment together, because both read the same `path.landing` - the line's off-paddle bounce continuation now also starts from the true contact point. Tested in the reporter's terms: the bounds must name the same surface the sticky catch judges against, and a shallow approach must land where the ball actually arrives |
| Game Center boards, round 95 status | James: **Endless Mode 2 best height is live**, and both new *sets* are live - Endless Mode 2 Leaderboards and Daily Challenge Leaderboards. The other three boards are still in review, so anything that reads them has to keep tolerating an empty answer until they clear |
| The pause menu's outer buttons sit too close to the edge | Play-test round 95: on the in-game pause screens, where the middle button is the big 75pt play, the close sits nearer the screen edge than it does elsewhere. The spacing is computed in each screen's `collectionViewLayout()` from the row's width less three cells - which spreads the outer two as far apart as the row allows. The daily challenge screen already solved this by pinning its outer buttons 55 points in from the edge; the collection-view rows want the same treatment |
| ~~Descent should not hold the field back over a gap~~ **built, round 99** | Play-test round 94: with Descent running, clearing the bottom bricks leaves a gap and the field still steps one row at a time, because Descent owns the cadence while it runs (`endlessIIDescentSuspendsCadence`, §5.4, added so the two would not double-step). What is wanted is the ordinary rule underneath it: **while the bottom row is empty the normal descent applies**, closing the gap as it always would, and Descent resumes its own step once there is a brick on the bottom row again. So the suspension needs to be conditional on the field having something in its bottom row rather than absolute - `countBricks` already computes exactly that, which is what makes this small |
| Play-test round 88: Auto-Aim, magnetism and a crooked ball | **Auto-Aim never hits the brick it is aiming at** - **fixed in round 103**, and the play-test's wording was exact. Neither of the suspects this row named was the cause: `endlessIIApplyAutoAim` was built in round 22, documented, and covered by tests that called it directly - and **no bounce in the scene ever called it**. The marker drew, the turns were spent, and the ball left at the ordinary bounce angle; only the Portal Paddle re-entry (aimed inline, round 88's other fix) ever actually aimed. `paddleHit` now asks the aim last, after the bounce has chosen its angle, and a test drives the real paddle bounce so the wire cannot silently drop out again - a lesson in what a passing suite is evidence of, alongside round 62's unlinked dylib. Two accuracy refinements went in with it: the target choice now refuses a brick the launchable arc cannot reach (`endlessIIAimCanReach` - `autoAimAngle` clamps to the arc, so a shallower target would be marked and then missed as the clamp bends the shot up underneath it), judged from the launch point by marker and redirect alike so the promise and the delivery stay the same thing; and **the target ring is now prominent** (0.9 alpha, thicker stroke, glow), which was this row's third item. The skip-no-benefit gap was closed in round 22's follow-up (`endlessIIWorthAimingAt`, row above). **Paddle Magnetism reaches too high**: built - the pull now wakes only below `finalBrickRowHeight + brickHeight*2`, the field's bottom couple of rows. **And a ball that changes direction slightly with no brick and no power-up involved** - investigated in round 98. Every angle writer is contact-driven and every `didSimulatePhysics` effect is gated by its clock, but `ballHorizontalControl` carried a **random kick**: one correction in ten got up to five degrees of random deflection, on every correcting path including the seam bounce, which resolves a frame after the visible contact - a kick that lands mid-flight to the eye. **Removed in round 98 - and round 99 says that was not it**: James reports the ball changing position mid-scene with nothing around, and that the issue **appeared only a few builds ago**, which makes it a regression to trace, not a 2020 behaviour. The markers and the kill line carry no physics bodies (checked, round 99), so they cannot deflect anything. **The tripwire is built (round 104)**, and building it produced a new prime suspect. `CrookedBallTripwire` (pure comparison in `BallPath.swift`, tested; scene half DEBUG-only) runs last in `didSimulatePhysics` and compares the main ball frame to frame: a heading bend past half a degree *or* a position jump no frame of flight could cover, on a frame where no contact fired and no writer left a note, prints a loud `CROOKED BALL, unexplained` line with position, heading and the Perspective Zoom flag (zoom bends the *apparent* path of a straight ball - a sighting by eye with zoom on and no line is the camera, not the physics). Every deliberate writer now announces itself via `crookedBallNote` - contact, seam-bounce, wrap, portal-exit, paddle-portal, handover, horizontal-escape - and a trip explained by anything rarer than an ordinary contact prints quietly with the writer's name, so a sighting can be matched to what moved the ball. **The new suspect: `breakHorizontalRuns`**, found by enumerating writers for the instrument. It went in with the ceiling-run fix (`06a5d4b`, 2026-08-06 - a couple of days before the sightings were first reported), runs every frame from `update` in **all modes**, and kicks any ball within `minAngleDeg` (10°) of horizontal out to 10-16° - a several-degree bend, mid-flight, no contact, at an arbitrary moment, which is the report word for word. The timeline fits and the previous three suspects (seam resolver, portal/wrap leak, aim freeze) do not fit "recent" nearly as well. Next play-test with the debug build on the console: a sighting alongside a `horizontal-escape` line is the confirmation. The fix is then a design call, because the escape is load-bearing (a horizontal ball can never be lost or played): likely soften it - narrower trigger band, gentler bend, or defer the correction to the ball's next wall bounce where a bend belongs |
| Play-test round 85: the long list | Queued verbatim so nothing is lost, roughly in the order they were given. **Sizes and spacing:** daily challenge level previews slightly larger; app icon images larger in their squares; stats table cells taller and more padding between title, tab bar and table; achievement titles over two lines with taller squares if needed; detail-view cells slightly taller; the endless menus' header row sits far above the previous-runs table and should come down; game-over replay glyph bigger to suit the bigger button. **Behaviour:** choosing an app icon or a theme should return to the settings list; the theme row should show the chosen theme as its icon, the way the app icon row does; the power-up reference wants sticky headings reading CLASSIC GAME MODES and ENDLESS MAYHEM, in the bricks page's style; the game-over More Stats view should use the stats page's table style; the main-menu pop-up needs a home icon. **Stats:** rename "Best single ball" to "Most hits on a single ball" and drop the "hits" suffix from its value; total play time per mode; duration stats beside height for both endless modes. **Mayhem bugs, and the most urgent of the lot:** with Aimed Sticky running, new rows kept descending while the standing field stayed paused, and after a pause-and-resume bricks descended *below the paddle* - the descent must be frozen for the whole time the aim is in progress (**built, round 87** - the field waits for the aim); and Aimed Sticky cancelling the angle-benders and vice versa is **built, round 99** - most recent wins across the whole group, Portal Paddle untouched, and a cancellation landing mid-aim still owes the held ball its launch. **Trajectory:** the line is not fuzzy enough, and the fuzziness should *increase* with distance from the ball (**built, round 106**: the round-42 fade kept the stroke at a fixed width, so the far end read as a thin crisp core with a faint halo, not a blur. The stroke now swells as the certainty falls - 1.5pt at the ball to 3.5pt at the far end - the glow grows on a square so it arrives mostly over the far half, where the guessing is, and the near end is a touch brighter so the contrast makes the fade legible. Glow per segment stays modest deliberately: `SKShapeNode` pays for glow, and four balls can put four lines of ~45 segments each on screen. Visual tuning, so the judge is the next play-test) |
| Settings icons that answer to their setting | Play-test round 85, and it **forks on a decision only James can make.** Wanted: a diagonal slash through music, perspective zoom and swipe-up-to-pause when off; the sound waves dimmed when sound is off; the vibration waves dimmed when haptics are off; and the paddle-speed icon gaining or losing speed lines with the speed chosen. The current icons are flat PNGs, one image each, so **dimming or removing part of one is artwork, not code** - the parts are not separable. Two ways: (a) new art per state, James's side, §8.5, which keeps the drawn look; or (b) move these six to SF Symbols, which has exactly these variants for free - `speaker.wave.2.fill` and `speaker.slash.fill`, the `.slash` forms, and variable-value symbols whose fill follows a number, which is the paddle-speed request precisely. (b) is a day's work and changes how those six rows look; (a) is no code at all. A slash *overlay* drawn in code is a third option and the worst of both - it would sit over art that was not drawn to carry one |
| Game scene: smoothness pass | James, round 84: "occasionally the game can feel stuttery, or the ball's path can feel a bit weird just before or after a bounce - I also notice it when a power-up starts falling." Three separate smells, and worth treating as three: **(a) the stutter on a power-up appearing is fixed (round 85)** - `SKTexture(imageNamed:)` holds a name and decodes the file the first time it is *drawn*, so all fifty-one power-up textures were decoding on the frame their power-up first appeared, on the main thread, mid-bounce; `SKTexture.preload` at scene setup moves that off the render path. Two more spawn-time costs are left and both are smaller: `addPowerUpGlow` builds an `SKShapeNode` with a `glowWidth` per drop, which forces an offscreen pass and would be cheaper as a preloaded radial sprite; and the selection loop reduces two array *slices* per iteration, which is O(n²) allocation for a fifty-one entry table and wants prefix sums - left alone deliberately, because it is the weighting logic and has no test around it; **(b) "weird just before or after a bounce"** is §8.6's territory and should be read against it first - anything sampling a *reported* contact velocity rather than `ballStateBeforeStep`, or adjusting an angle in `didBegin` rather than `didSimulatePhysics`, will read as the ball behaving oddly around the moment of contact; **(c) general stutter** wants measuring before changing anything - a Time Profiler and the SpriteKit debug counters on James's own device, not the simulator, which is not evidence about frame rate. Do not optimise without a measurement; the app is far more likely to be hitching on a spawn than to be short of frame budget |
| Quick Start Guide: a What's New page | Round 84. The guide is five image assets (`IntroView1`-`5`) rendered by `IntroContainerView`, so a sixth page is **artwork, not code** - James's side, §8.5. The pop-up that greets an updating player is built (round 84, `WhatsNew`) and its words are the copy the page would carry |
| ~~Pop-ups gain an icon above the title~~ | **Built, round 82.** `GigaBallAlert.show` takes an optional `symbol`, drawn above the title in the app's green with the title's own glow, and all six call sites name one: a calendar for a closed challenge, dice for the twists, a controller for free play, a hand for the swipe gesture, and the power-up mark for a power-up's explanation. Optional, and absent means no icon rather than a placeholder - a pop-up with nothing to illustrate should not invent something. Two things the doing taught: `symbol` has to sit *after* `message` in the signature, because Swift requires arguments in declaration order and every existing call names `message` first; and the icon draws `.center` with masking off, for the reasons the round buttons learned - aspect-fit would blow a 30pt symbol up to fill the stack, and a masked layer cannot draw the glow outside its own bounds. Original note follows.   Play-test round 39: an appropriate icon above each pop-up title, in the Giga-Ball green/yellow with the same glow the title wears. `GigaBallAlert` is the type |
| Remove the play button from the in-game backgrounds view | Play-test round 39 - see the third-report row above; likely the same cause |
| Cloud background | Play-test round 39: same purple-to-dark gradient as Gradient, with a Giga-Ball yellow/green cloud drifting gently and slowly behind the game. **Live**, unlike every existing background, which are still images - so this is the first animated one and needs a decision about cost per frame. Supersedes the queued Glow rework |
| Liquid Glass across the UI | Play-test round 39 asks to start now rather than at 1.4. FUTURE-RELEASES.md has it as a 1.4 item, sequenced after the safe-area work so components are not restyled onto a layout about to be rewritten. James has seen the statistics tab bar (a stock `UISegmentedControl`, which is Liquid Glass for free on iOS 26) and wants that everywhere. **Start with the round UI buttons**, which are the most repeated element and the least entangled with layout |
| Achievements review | Play-test round 39: review how achievements work and how they are presented when earned |
| ~~Classic force-quit should resume on the between-levels screen~~ | **Fixed** (round 41), the same bug from the other end. The save advances `levelNumber` on that screen, which is right - the next level is the one to build - but it recorded no sense of the player not having *started* it, so a resume ran straight in. `SavedGame.pausedBetweenLevels` says so now (optional, so older saves decode and behave exactly as they did), and the resume enters `InbetweenLevels` instead of play. The save is cleared on the way, because the anti-cheat rule stands: a run that has been resumed must not be resumable again from the same moment |
| Liquid Glass moved into 1.3 | **James's call** (round 40), overriding FUTURE-RELEASES.md's 1.4 placement. The sequencing caveat still stands and should be read before starting: it was placed after the safe-area work so components are not restyled onto a layout about to be rewritten. Starting with the round UI buttons is the lowest-risk entry - they are the most repeated element and the least entangled with layout. The statistics tab bar is the model, and the reason it looks right is that it is a stock `UISegmentedControl`: adopting system controls is most of the work, not hand-styling |
| App Store review readiness pass | A deliberate pre-release review against the guidelines. The daily's test clock is the known must-fix; the pass should hunt for others. Includes the anti-cheat sweep: a finished game must never be resumable (a live report), and every path that posts to a board should be checked for what a dishonest player could replay or restore |
| A scatter cluster | ~~§6.2.1's third kind~~ **Built** - Buckshot, Ghost Field, Shrapnel |

**Fixed in the second wide play-test round, recorded here because each was reported with a
screenshot:** skipping the opening build-in parked bricks above the play zone (the snap
sweep's destinations were cleared one line too early, so mid-fall bricks took the
nearest-row fallback - a brick still waiting out its delay sat above the top row, whose
nearest row is above the field); a personal best on a multiple of ten drew the best line
*and* a ten-metre tick in the same row (the milestone now always wins, the rule a best on
a hundred already had); the lower-limit line dropped to tick subtlety (alpha 0.12, hairline)
while keeping its width and warm colour; Ball Steering's smoothing went 0.45 → 0.7 - close
to 1:1 with a hint of inertia, per the second-round note; the endless mode screens lost
the headline Best Height figure (the run table's best row wears the emphasis instead); and
the pack screen gained the big centred play button the other screens have, which continues
the campaign at the furthest unlocked pack.

The new power-ups appear on the power-ups page already — the page derives from the arrays
that define them, so all forty-eight are listed with their icons, timers and descriptions.
What it does not yet show is Endless Mayhem's turn-based distinction; worth a look in phase 9.

Tap to skip the game-over height tally is **built** — the gesture is on the pause menu and does
not cancel touches, so every button on the screen keeps working.

**Backlogged**

| Item | Blocked on |
|---|---|
| Global leaderboard lines on the height markers | The Endless 2.0 boards existing in App Store Connect. Until they do, scores fail to post silently |
| Artwork and sound for everything new | §8.5. Deliberately last, while mechanics are still moving |
| ~~Ring HUD in Classic and Endless~~ | **Moved to the open queue** - the second play-test round decided the design that kept it here: the old modes keep their tray, order and geometry, and only the indicator becomes the ring. `layoutUnit` never moves, so the brick-size worry dissolves |
| ~~Wrap-around applying to the paddle, Moving bricks and explosions~~ | **Built**, first time, the way §5.4 wrote it up |

### 12.1 Style progression, as part of phase 6

Styles arrive the way power-ups do (§6.3), and for the same reason: a player who never gets
far should still meet everything eventually, and a player who gets a long way should be
meeting combinations rather than single tricks.

Three things ramp with height, independently:

| | Near the start | Deep |
|---|---|---|
| **How often a brick has a style at all** | Rare — most of the field is plain | Common enough to shape how a field is played |
| **How many styles a brick may carry** | One | Two, and rarely two on several bricks at once |
| **Which styles are offered** | The readable ones — Rounded, Big, Tiny | Everything, weighted so the field-changing ones stay the minority |

**The ramp is eased, not linear.** A thousand metres is the right place for the deep figures
to land, but a straight line puts a hundred metres a tenth of the way there — and most players
do not often pass a hundred metres. A run that is still nine parts plain bricks by then has
shown them almost nothing of the mode, which is precisely what §2's *reachable novelty* rules
out. The curve is steep early and flattens, so most of the variety arrives in the first couple
of hundred metres and the rest of the climb is the rare things getting likelier. The endpoints
are unchanged.

**Rare, not absent.** Every style keeps a small floor probability from the first row, the
same rule §6.3 sets for power-ups. Somebody who never passes 20m should still have met a
Portal, and met it as a surprise rather than as the thing that ended the run.

**Varied, not escalating.** Depth raises what is *possible*, not what is *guaranteed*. A
deep field that is entirely styled bricks is as monotonous as a shallow field with none, so
the ramp raises the ceiling and leaves the roll to chance.

### 12.2 What is left, and in what order

Phases 1 to 7 are built. What remains is phase 8, phase 9, and two things that fell out of
earlier phases and are small enough to carry alongside them.

**Phase 8 — the new power-ups, in four batches.** Twenty-three of them (§5.4), which is far
too many to judge at once: rarity can only be tuned against a batch that is actually being
played, and a mode that gained all of them in one build would be unreadable. Each batch ends
playable and is worth a round of play-testing on its own.

| Batch | What lands | Why these together | The question it answers |
|---|---|---|---|
| **8a. Vision** ✅ | Trajectory Line, Landing Marker | Both draw what the ball is *about* to do and change no rule. One predictor serves both, and it is pure geometry - testable rather than eyeballed | Whether four balls means four lines, and whether being told where the ball will land makes the mode easier or just calmer |
| **8b. The paddle** ✅ | Aimed Sticky, Magnetism, Portal Paddle, Paddle Halo, Ball Steering, and the three bad ones - Inert Paddle, Flipped Angle, Reversed Controls | Every one of them changes what the paddle does, so they conflict with each other and want tuning against each other. Aimed Sticky inherits the queue Sticky Paddle already has (§5.5) | Whether a mode where the paddle keeps changing its rules is exciting or exhausting - and whether the bad ones are funny or just unfair |
| **8c. The field** ✅ | Descent, Cull, Clear And Retreat, Laser Beam, Wrecking Ball, Aura, Infill, Wrap-Around | These act on bricks rather than on the ball, and each one has to be thought about against every brick style that already exists - Wrap-Around alone touches the paddle, Moving bricks and explosions (§5.4) | Whether a power-up that rewrites the field is a relief or a loss of the thing being played |

**8c is built, seven of its eight.** Cull takes half the field at random and scores all of it,
including the indestructibles the ordinary destroy path refuses to score; Clear And Retreat
destroys the lowest occupied row and steps everything else up exactly one row, so every
brick lands on a row centre again; Laser Beam burns one column per ball in play, each from
its own x; Infill (the bad one) adds six bricks in random empty cells, arriving the way a
Spawner's do. The clocks: Wrecking Ball makes the ball's own hits destroy whatever
they strike - through the ordinary destroy path, so they score, roll power-ups and count
like any hit, and the ball still bounces - and Aura destroys what the glow around each ball
touches, growing on a second collection. Descent drives the field's own one-row step on a
timer, just under two rows a second, suspending the normal bottom-row cadence while it runs
- the grid-preserving reading of "moves down continuously", because a brick's position.y is
its row and a field that drifted off its centres would break everything that reads them.
Height, markers, new rows and the unscored destruction at the lower limit all come free,
because the step is the same step the field has always made. Everything else destroys like a crush: roles react,
nothing rolls a power-up. All of it spares Portals and power-up bricks, and the Aura also
spares hidden bricks - an invisible brick it silently ate would never have been seen at all.

**Wrap-Around is built, and with it phase 8's mechanics are complete.** It never touches the
wall physics: the walls stay where they are, the ball still contacts them, and while the
clock runs the contact is answered with a teleport to the far side instead of a bounce -
deferred to didSimulatePhysics like every position written during contact resolution (§8.6),
keeping the pre-step heading, which is what makes the two sides one surface. The paddle is
free to overhang an edge and wraps once its centre crosses; a Moving brick whose run to the
wall was clear carries on from the far one (blocked mid-field, it bounces as ever); an
explosion against a wall reaches round it. The side walls wear the portal yellow while they
are exits, and a paddle overhanging an edge when the walls come back is pushed inside them.

**Revisions from the 8b play-test, recorded because they changed §5.4's table:**

- **The whole paddle batch is turn-based** - five paddle hits per collection, like the sticky
  paddle, not ten seconds. The contact is the turn, whatever the paddle then does with it,
  and the ring shows the turns as segments. A power-up spent by using reads differently from
  one that evaporates while the ball is away at the top of the field.
- **Magnetism's cap opens with proximity** (five times the far cap at the paddle - "very hard
  to miss" was the request), the paddle wears magnet red, and the pull is drawn as lines that
  brighten as it strengthens. **Ball Steering went to 1:1 with a tiny bit of inertia**, and
  draws a line from paddle to ball. **Portal Paddle** wears portal blue with the yellow exit
  strip along the top - the strip also appears whenever exactly one Portal brick is in play,
  because a single portal's exit is the top and nothing said so.
- **Auto-Aim is a new paddle power-up** (uncommon, five turns): every bounce off the paddle
  is aimed at the lowest brick, nearest first among equals - the brick threatening the run is
  the one worth a free shot. It overrides only the outgoing angle; catches, swallows and
  turns spent all happen first.
- **The mode is renamed Endless Mayhem.** Internal identifiers stay `endlessII`; the rename
  is one line, because every screen reads `GameMode.name`.

**Second-round revisions, from playing the first round's answers:**

- **Aiming is its own moment.** An Aimed Sticky catch freezes the world the way the pause
  menu does - every ball, brick and laser holds where it is, headings preserved - the drag
  chooses the angle, and lifting the finger fires the ball and lets play go in the same
  frame. Two other answers were tried first: a frozen paddle read as the game pausing by
  accident, and a live paddle made one drag do two jobs.
- **The Portal Paddle and Portal bricks connect after all.** While the paddle's clock runs,
  every portal joins one network: a paddle hit exits at a random Portal brick (climbing), a
  brick hit exits at the paddle (always upward - a ball exiting a paddle downward would be
  exiting the game), and only with no bricks in play does the paddle's portal still use the
  top. The yellow strip now marks the top only while the top is genuinely the exit.
- **Auto-Aim only spends its shot on bricks worth hitting**: never an Indestructible, never
  a brick holding a bad power-up. The bad set is derived from the multiplier column plus
  Lose A Ball, whose chip is blank because losing the ball speaks for itself.
- **A Fixed brick hardens as it anchors**: the first hit locks it in place *and* turns a
  plain brick into a fresh Multi-Hit, so digging it out costs the full ladder. Play-testing
  found the two-hit version dead on arrival - hit twice in quick succession, it never came
  into play. A brick already multi-hit keeps its own ladder; hits already taken are not
  refunded.
| **8d. The rules** | Lock, Key, Wipe, Randomised Bounce | The ones that act on *other power-ups*. They need the rest of the set to exist before they mean anything, and Lock and Key only drop in each other's company | Whether a power-up about power-ups reads at all in the moment |

Each batch needs the same four things, and none of them is optional: entries in every
power-up array (§8.6's trap - the stats file *and* the iCloud store), a weight in the
allocation table and the introduction schedule (§6.3), an eligibility rule where the power-up
only makes sense sometimes (`powerUpCanAppear`, which the power-up brick reads too), and a
drawn placeholder icon so it looks like a power-up rather than a gap.

**Carried alongside, whenever they fit:**

| Item | Notes |
|---|---|
| A scatter cluster | §6.2.1's third kind - particular bricks in a *random* arrangement rather than a drawn one. Needs a generator rather than a grid, which is why it did not come with the other two |
| The new power-ups on the power-ups page | Written against what exists, so it follows each batch rather than leading it |

**8a is built.** `BallPath` walks the path forward - turning at the walls, stopping at the
first brick, honest about the ball's radius - and is pure arithmetic with its own tests. The
line is drawn per ball, faint, and re-asked every frame, because a stale line pointing through
a brick that has already been destroyed is the lie the feature must not tell; it is also
capped at a handful of bounces, because every bounce is a place the scene's own angle rules
may nudge the real ball. The marker is a ghost of the ball on the paddle's line. Both run on
their own clocks (extend on re-collection; the third Trajectory Line lengthens the line),
report themselves to the ring HUD since they have no tray slot to be read from, and survive a
pause-and-quit through the active-power-up arrays. The weights are guarded by mode inside
`buildNewEndlessRow`, which builds rows for *both* endless modes - a flat weight there would
have quietly added them to the original Endless.

**8b is built.** All eight run on `EndlessIIClock` - one type for every timed power-up the
mode owns, so extending, deepening, pausing, expiring, saving and the ring read the same
everywhere - and the arithmetic of each effect is a pure function in
`EndlessIIPaddleEffects`, tested on its own. The scene is *asked* rather than rewritten: the
bounce's angle line multiplies by one influence value (Inert 0, Flipped -1), the touch
handler multiplies by one direction value (Reversed -1), and the body-writing effects -
Magnetism's speed-preserving curve, Ball Steering's clamped nudge, the Portal Paddle's
re-entry at the top - all run from `didSimulatePhysics`, §8.6's one safe place. The halo
destroys like a crush: roles react, nothing rolls a power-up. Aimed Sticky owns the launch
while it runs (launchControl): any ball landing on the paddle is held into the same queue
Multi-Ball built, the arrow defaults to the bounce the ball would have taken, dragging swings
it - and while aiming, the paddle deliberately does not move, which is this batch's
sharpest play-test question.

**Phase 9's code side is done.** The info pages derive their content, so they were already
current when phase 8 finished; what was genuinely stale has been fixed - the timer column
now carries its own units (seconds, catches, or paddle hits - the page used to guess the
unit from the number, and nine turn-based power-ups made that guess wrong nine times), and
the Fixed style's description says what anchoring now costs. The scrolling backdrop runs on
a placeholder awaiting its tile. Everything left in phase 9 is asset work and the Quick
Start Guide, which are not this codebase's to make - §8.5 is the list.

**Phase 9 — presentation.** Scrolling backgrounds, the real artwork and sound (§8.5), and the
information pages finished against a mode that has stopped moving. Deliberately last: a
placeholder that reads correctly is worth more than finished art for something that might
still change.

**Still blocked on something outside the code:** the Endless 2.0 leaderboards existing in App
Store Connect (until they do, scores fail to post silently), and the ring HUD in Classic and
Endless, which changes `layoutUnit` and therefore brick size on levels people hold years of
scores on.
