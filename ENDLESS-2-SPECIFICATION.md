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
| **Clear And Retreat** | — | Uncommon | Yes | Extends duration | Destroys the lowest **two** occupied rows and **holds the field there** for eight seconds. **Timed since round 136** (play-test round 126: "it should be timed and it should raise the lowest brick level by 2 bricks"). Instant, it was self-defeating: it made a gap, and the cadence exists to close exactly that gap, so the retreat was gone inside a second and the power-up read as doing nothing. The hold is the retreat - no cadence, no Descent, no new rows while it runs. It costs the run its tempo, since height only comes from the field descending, and gives that height back the moment it ends and the field drops into the room that was made. Nothing is lifted any more: the lowest *level* rises by the two lowest rows being destroyed, which is what the name says and needs no rule for a brick pushed off the top |
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

### Which way a shaped brick faces

"Flip horizontally and vertically the asymmetrical brick types like wedge so they appear in
different orientations in the app. No need to separate textures for this" (James, round 154).
Both reflections are applied to the *node*, so one texture serves all four orientations and
the drawn shading turns over with the shape.

**The vertical flip is a game change rather than a picture change**, and it closes §12.0's
"shaped bricks facing down". Every shaped brick used to face up, and the field descends to
meet the ball, so nearly every hit lands on a brick's underside: a field of domes and wedges
was a field of flat undersides, and the shapes were doing far less than they read as doing.
Half of them now point down, where the ball actually arrives.

Only the Wedge is mirrored - a mirrored dome is the same dome - but all three faces are
flipped. The geometry reverses its winding when *exactly one* reflection is applied, because
each one flips it and two are a rotation; a body wound the other way is a brick the ball
passes through, so there is a test on it. The orientation is recorded on the brick and
carried in the save, or a resumed field would answer the ball differently from the one the
player left (round 150's lesson, one level further in).

### How a shaped face wears its art

**`SKShapeNode.fillTexture` does not stretch its texture to the path.** It lays it in at the
texture's own point size, so a face filled that way shows a *crop* of the picture, and how
much of it depends on how big the file happens to be.

That was true from the day Rounded was built and nobody could see it: the classic brick is a
white rectangle with a hairline edge, and a crop of a white rectangle is a white rectangle.
The retro art has a bevel, so when it arrived at full resolution (round 154) every shaped
brick in the retro theme started showing a magnified corner of its own bevel - James, round
156, with screenshots: "some are 4 times too big and some are 4 times too small". Four times
is one doubling in each direction, which is exactly what the file's own size had done.

The art is now drawn by a **sprite that is told its size** - the cell, read back off the
face's own path so it survives Breathing changing `brick.size` every frame - and the shape
node stops painting. No clipping is needed, because the drawn faces are silhouettes already.
A texture redrawn at any resolution now lands the same, which is the property the tests hold.

Convex and Concave keep the old fill until they are drawn, because a fill that is
approximately right beats a dome that is not drawn at all. That is one more reason their art
is the next batch worth having.

### Shaped brick faces — the first batch, and what is still to draw

James delivered twenty-eight on 16 August 2026: a Rounded and a Wedge texture for every
brick type that has one, in both the classic and the retro theme. They are in the catalogue
as the plain texture's name with `Rounded` or `Wedge` on the end, which is what
`endlessIIBrickTextureName` builds them from - so a new brick type needs one line there and
two files, and nothing else.

Before them, Rounded and Wedge drew their faces by stretching the brick's *rectangular*
texture into the shape's path. It read correctly and was never quite right: a stretched
rectangle puts its highlight in the wrong place and runs its shading off the edge of the
shape rather than along it.

**Still to draw:** Convex and Concave, both themes, both of which keep the stretched
rectangle until they exist. `GameScene.shapedArt(for:)` returns nil for them and a test says
so, so the day they are drawn the change is two lines.

**The retro resolution question is closed**: James redrew the six plain retro textures at
56×28 the same evening, so the whole retro set now matches its shaped faces and the classic
set. The other note stands, by his decision: the retro theme has no Indestructible texture of
its own and is not getting one - those bricks wear the classic art, and now the classic shaped
art, which is right rather than a substitute.

### Wrecking ball textures — three still to draw

James delivered thirty-six on 16 August 2026 (thirty-three, then glass): a spiked ball for each of
the twelve ball themes, in each of the three ball colours (normal, Giga-Ball,
Undestructi-Ball). They are in the catalogue as `ballWrecking<Body><Theme>`, where the body
is `Normal`, `Giga` or `Undestructi` and the theme is the empty string for classic, and
otherwise `3D`, `Ice`, `Outline`, `Square`, `Pixel`, `Split`, `Candy`, `Glow`, `Rainbow`
or `Retro`. Note `Glow` is the theme the code has always called the giga *look* - it is
index 9 in the ball arrays, and the files use James's word for it.

**Complete** as of the following round: James drew the glass three the same evening, so all
thirty-six exist. The nil answer is still there for a theme with no art - it is now held
against an index that does not exist rather than against glass - because a ball wearing
somebody else's spikes is worse than a ball wearing none.

Two of the delivered files arrived misnamed and were placed by what they actually are:
`ballWreckingGigaRainbow Copy` is the giga rainbow (there was no other), and
`ballWreckingGigaCandy Copy` is the *undestructi* candy - it is the grey-blue of
`candyUndestructi`, not the yellow-green of `candyGiga`, and undestructi candy was otherwise
missing. Worth confirming.

The spikes are drawn at the texture's own proportions against a 50pt plain ball, so the
overhang is whatever the art says: 64pt for most themes, 72 for the candy cane, and 50 for
the square theme, whose spikes are drawn inside the square. A redrawn texture with longer
spikes is longer-spiked in the game the day it lands, with no number to change.

### Power-up icons — two drawn placeholders left

Every one is a `static let` in `PowerUpIcon.swift`, drawn at 120×120 into the standard
rounded-square badge, green for beneficial and red for harmful. To replace one: add the
asset (e.g. `PowerUpMagnetism.png`) and hand `PowerUpIcon.artwork` its name — the drawing
stays as the fallback, so a misspelled name looks like the day before the art arrived,
which is why `PowerUpArtworkTests` pins each drawn icon as *bigger than the placeholder
canvas*. The `applyPowerUp` switch matches on the scene textures, so the drop, the brick
and the page all come from the same place, which they do today via `PowerUpIcon`.

Round 176's Desktop drop retired twenty-four at once (plus new art for Double Paddle and
Mirror Paddle, and replacements for the four round 169 installed). Two names differ from
the code's: `PowerUpRandomBounce` is `randomisedBounce`, `PowerUpTrajectory` is
`trajectoryLine`.

Still placeholders: Portal Paddle, Wrap-Around and Ball Spin (round 183's new power-up, which also wants the grippy paddle texture its design asks for). Cluster's art arrived in round 182. The Daily Challenge badge and the ten
twist icons are drawn too, and are a different visual family (purple, not green/red).

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
| Build-in rain / Clear And Retreat | `endlessRowDownSound` (borrowed) | `runEndlessIIBuildIn`, `endlessIICollectClearAndRetreat` |
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

**A velocity written before `addChild` is lost.** A body attached to a node that is not yet
in a physics world does not keep the velocity it is given - the write silently vanishes when
the node arrives in the world. Cluster's burst hung motionless in the air until the release
set velocities *after* `addChild` (round 179). Position survives; velocity does not.

**One collision can be reported as more than one contact.** The block and the frame both
answer to a ball, and a manifold can carry several points - so a handler that does something
*unidempotent* per `didBegin` does it twice for one hit. Two wrap teleports are a round trip
that looks exactly like a bounce (round 177). Note the subject once per frame, and make the
response ask whether it still applies.

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
| **Play-test round 200: the morning list** | James's fourteen plus a crash. **Built in round 200:** ~~the crash~~ (the Cluster contact force-unwrapped a node that a double-contact had already removed - see that round's row below); ~~autosave~~ (a crash cost James ~250m because nothing saved between pauses; endless runs now save every 10m of climb from the row step); ~~softer wall haptic~~ (intensity 0.4); ~~wall haptic repeating against the wall~~ (hysteresis - arriving and leaving shared one half-point threshold, so a trembling thumb read as endless fresh arrivals; leaving now takes 20pt of deliberate movement); ~~safety paddle haptic on pass-through~~ (a climbing ball is ignored entirely now - the contact fired as the bar's bits restored while still edge-touching, and it also *rewrote a climbing ball's velocity*, which is one real jitter source found); ~~safety paddle position~~ (one full row below the line, measured from the line the player sees); ~~line opacity~~ (0.22 to 0.11 - safe to dim now, the old brightness fights were zPosition bugs in costume); ~~mirror paddle shadow~~ (the paddle's own texture, black, translucent, a child of the paddle behind its pixels and in front of the mirror); ~~magnetism~~ (the whole span is the magnet: the pull aims at the nearest reachable point of the paddle to the ball's *own landing*, so a ball already hitting the paddle gets no turn at all and inertia decides - the old fixed target a third out from centre was exactly the "preventing the ball from hitting the centre" James saw). **Still open, below as their own rows:** the jitter audit, the safety-paddle cap rendering, the paddle-family power-up parity, the two Drifts, the Gravity review, the timer-end redesign, and power-up-brick gating. |
| **Ball jitter - one cause found, audit open** | Round 200: "the ball still sometimes feels jittery like it's speeding up and slowing down constantly... it seems to happen when certain power ups are enabled. I've noticed it with safety paddle." **Found and fixed with the Safety Paddle**: the pass-through contact was rewriting a climbing ball's velocity through the bounce arithmetic every time the bar's collision bits restored while the ball still edge-touched it. **The audit still owed**: the continuous effects each write velocity per frame - Magnetism turns it, Ball Steering writes position, Ball Spin rotates it, Gravity accelerates it - and any of them interacting with a contact's own correction in the same frame is a speed wobble. The next sighting wants the power-up ring in the screenshot so the suspect list is short. **Round 201 built the speed tripwire**: `CrookedBallTripwire` now trips on a 2%-in-one-frame speed change with no contact to blame - far past renormalisation drift, well inside what a hand feels as a stutter - and `crookedBallWatch` prints it as "speed wobbled" beside the bends and jumps. The next play-test sighting will name its own cause in the console. |
| ~~**Safety paddle cap rendering**~~ - **fixed, round 201, analytically** | "The rounded edges of the safety paddle don't look the same as the main paddle." They could not: the paddle wears the *whole-texture* rect at standard width and switches to the protective cap rect only when a resize stretches it (`paddleCenterRectZero`/`Plus`), while the bar wore the cap rect always - two different renderings of one picture, the paddle scaling its caps uniformly and the bar holding them at native size. All three paddle twins (safety bar, mirror, the mirror-day shadow) now copy `paddle.centerRect` *live*, so they wear whatever nine-slice state the paddle itself is in - and the mirror re-copies on resize, which also fixes its ends stretching flat under Expand. Split Paddle's segments keep their own rects on purpose: they are narrower than the texture, which is round 182's unchanged lesson. |
| **Paddle-family power-up parity - first cell built (round 203)** | The safety bar now follows the paddle's width live, the way the mirror has since round 180 and the split segments already did - Expand and Shrink reach all three surfaces, with the nine-slice re-copied so the fresh width does not stretch the old state. The rest of the matrix stands as below. Round 200, the big one: "the safety paddle, mirrored paddle, split paddle power ups should match power ups of the main paddle: shrink, expand, sticky, aimed sticky, portal paddle, lasers, ball spin grippy texture, different shaped paddles." Today the mirror tracks width (round 180) and everything else is the main paddle's alone. This is a matrix - three surfaces by eight-plus effects - and each cell is its own design question (what does a *sticky* safety paddle do with the ball it catches? whose lasers are the split halves'?). Wants James's cell-by-cell answers before code: propose defaulting to *visual* parity (textures, shapes, width) everywhere and *behavioural* parity only where the answer is obvious (width changes), with sticky/lasers/portal per-surface decisions listed for play-test. |
| ~~**Two Drifts, one per direction**~~ - **built, round 201** | The sixty-fourth power-up. The existing Drift is **Drift Right** now and always slides left-to-right; **Drift Left** (index 63) is its mirror, at the same weight so neither direction is the common one. The icon is mirrored *in code* from whatever the right's art resolves to - placeholder today, the real PNG the day it lands - rendered out to real pixels because `SKTexture(image:)` ignores a UIImage's orientation flag. **They share one clock**: collecting the other direction mid-drift reverses the field and extends the time - a dial, not two coats of the same paint - and the HUD ring mirrors its icon to say which way the field is sliding. The direction rides in the save now (it was a coin flip nobody needed to remember; it is part of which power-up is running), with older saves restoring rightward. The display order shows the pair side by side on the reference page. The suite caught the one array the edit missed, which is the entire reason the loud-failure convention exists. |
| ~~**Gravity power-up review**~~ - **map round 204, rebuilt round 205; wants old-mode play-testing** | Round 200: "it works quite strangely... make it more robust, more polished and more predictable." **The archaeology, complete - every place that touches the ball under gravity:** (1) *Collect* sets `physicsWorld.gravity` to (0,-1.5), flips the ball's `affectedByGravity`, runs a 10s x multiplier timer whose end **defers to the next contact** if the ball is in flight - the exact pattern Giga-Ball had before round 203. (2) *Deactivation contacts*: paddle, backstop, and top wall - **but the top-wall one is gated `endlessMode == false`**, so in the endless modes a pending end waits for a paddle or backstop touch specifically, which can be a long time. (3) *Per frame*, gravity is switched **off below `paddle.y + ballSize*4` and on above it** - a hard band, toggled every crossing. (4) **`ballSpeedControl`, the renormaliser that holds the whole game's speed constant, is entirely disabled under gravity**, and `ballHorizontalControl`'s corrections are skipped while the ball is above the band - so speed and angle are free-range in most of the field and only governed near the paddle. This is the heart of the strangeness: the ball genuinely accelerates without bound on the way down and dies on the way up, then gets snapped by corrections the moment it enters the band. (5) *Anti-stuck*: fifty consecutive frames of exactly zero velocity teleport the ball back to the paddle. (6) *Resume* re-applies gravity with the remaining time and the same deferred end. (7) *Restart* sets `affectedByGravity = true` unconditionally - harmless while the world's gravity is zero, but a trap for any redesign that stops zeroing it. (8) The crooked-ball tripwire lists "gravity" as a standing excuse, so nothing under gravity is ever reported. **Built in round 205, on James's approval** - see that round's row. Original proposal: (Classic and original Endless carry the leaderboards): keep the world-gravity arc but renormalise to a *band* - `ballSpeedLimit*0.6...1.4` say - each frame instead of not at all, so the arc still reads as gravity but can never run away or stall; end at zero through round 203's mechanism, with one renormalise-to-limit on the way out so the handback is smooth; and reconsider the hard on/off band, which may be better as a falloff. Play-test in the old modes either way. **As built:** the pull is the scene's own now, applied every frame from `didSimulatePhysics` - `physicsWorld.gravity` stays at zero and the ball's `affectedByGravity` stays false, so nothing else can be caught by a global that is never switched on, and the restart trap is disarmed by construction. Strength is unchanged at 225pt/s² (the engine's old (0,-1.5) times SpriteKit's 150 points per metre), because changing the feel and the mechanism in one breath would make it impossible to tell which did what. The speed is held in a 0.6-1.4 band; the hard switch four ball-widths up is a ramp to full strength at six; the end is at zero with a handback to exactly the run's speed; and **every ball is pulled**, where the old engine flag pulled only the first and left a Multi-Ball's extras floating serenely through the same field. **One real bug was designed in and caught by a test before it shipped**: the first draft enforced the speed floor by scaling the vector up, which multiplies the vertical component too - it hands back the climb gravity has just taken, and a ball near the floor climbs for ever. That is the hang this power-up has always had, reproduced exactly. The floor is made up *horizontally* now: gravity owns the vertical outright and the shortfall goes across, so the ball arcs over and drifts instead of hanging. The ceiling still scales the whole vector, which keeps the arc's shape. |
| ~~**Power-up timers ending on a paddle-hit, not at zero**~~ - **built, round 203; wants old-mode play-testing** | The review found the set is smaller than feared: only **Giga-Ball** deferred to the next contact (Undestructi-Ball and ball-size already end at zero, and Gravity's deferral is a different mechanism, left to the Gravity review). The redesign asks the stuck question directly: at the bar's end the power-up ends immediately unless a ball is currently *inside a brick's footprint* - checked by frame intersection, because a giga ball passes through bricks and the engine reports no contact for a body that does not collide - and a deferral that does happen is ended by a per-frame tick the moment every ball comes clear, measured in frames rather than in paddle round-trips. Mayhem's multi-ball is covered: a giga *extra* ball inside a brick holds the deferral too, by test. The old contact-based deactivations stay as harmless backstops. Both the collect and the resume paths carry the new rule. **Classic and original Endless carry the leaderboards - a few levels of old-mode play-testing before this ships.** |
| ~~**Power-up bricks gated by kindness, per run**~~ - **built, round 202** | "Good power ups only, then introduce bad power ups higher up, but not really bad ones, then worse ones even higher", with per-run randomness. The harmful set now carries authored **severity tiers** (`EndlessIIProgression.powerUpSeverity`: mild / bad / disastrous - a starting guess, and tuning it is one edit to one table, the same promise §6.4 makes about weights). Each run draws two gate heights into its schedule: bad joins at 50-120m, disastrous at 160-280m - **and disastrous can never arrive before bad, whatever the draws land on**; there is a test on the rule rather than on today's ranges. Mild nuisances (Fast Ball, Shrink Paddle, the points penalties) were never held back - the note is about run-turners, not annoyances. **The gate reads at the brick draw only**: a falling drop can be dodged, a brick's gift goes off in your hand, so the brick is held to a kinder standard than the sky. The heights ride in the schedule as optionals, so a round-192 save decodes and reads the range midpoints. Inert Paddle, Reversed Controls, Jagged and Split Paddle are the disastrous four; both Drifts carry the same tier by test. |
| **Progressive disclosure in Endless Mayhem** - James's round 190 design, the biggest thing left | Quoted whole because the shape matters: "Not everything is available at the start. This includes brick types and power ups and brick sequences and combinations of things. Each game, what is and isn't available at the start is different so each game feels very unique. The standard brick types and power ups are always available. As the player progresses higher, new bricks and power ups are introduced. Again the order that they are introduced is different for every game. Brick density can remain fairly even through the periods where new items are introduced. Density should generally rise with height, but new item introduction should also rise with height. Item rarity is still a factor. Rarity for items can be tweaked again so it's slightly different for each game. Although a generally rare power up shouldn't all of a sudden become the most common one. The number of items available at the start should also differ between games, and the timing and speed at which they are introduced should also differ. The goal is that each game of Endless Mayhem feels unique, it doesn't get stale, and within each run of the game, it feels fun, engaging and new elements and challenges are being introduced at an enjoyable rate." **Round 192 built the first half of this, and it turned out to be an extension rather than a rewrite** - §6.3's schedule already shuffled *which* styles and power-ups a run introduces and in what order. What it did not do is vary anything else, so every run opened with the same amount available and filled up at the same speed. Now: `openingStyles` and `openingPowerUps` are drawn per run, so how much is in play at metre zero differs; `styleSpacing` and `powerUpSpacing` are drawn per run, so the pace differs; and `rarityTweak` gives each power-up its own per-run multiplier. The tweak's range is deliberately narrow and there is a test on the reason - the luckiest a run can be to a Rare still leaves it rarer than the unluckiest it can be to a Common, so "a generally rare power up shouldn't all of a sudden become the most common one" is a property of the numbers rather than a hope. **And the schedule is saved with the run**, which it never was: it lived only on the scene, so a resumed Mayhem run reshuffled the lot and came back stocked differently from the one that was paused. That was already a bug and would have been a much worse one once the opening set varied. **Round 193 added the sequences and the quickening.** Set rows and phases now join the schedule too ("brick types and power ups and *brick sequences* and combinations of things") - shuffled per run with their own opening counts, so two runs meet different landmarks at the same depth. **An authored `minimumHeight` is a floor the schedule may only push down from, never lift**, because a row gated at 150m is gated there for what it does to a field, and a lucky shuffle must not put it in front of somebody at 20m; there is a test on that. And introductions **quicken with depth** - each successive gap is a little shorter than the one before it, floored so a long run never turns into a flood - which is what "new item introduction should also rise with height" asks for, where a constant spacing had the rate flat all run. Two things James's note states outright are now enforced rather than assumed: **Standard and the original game's power-ups are never held back**. That one caught a real flaw before it shipped - with the opening set shuffled, a run could draw an opening whose every phase was gated above zero, leaving *nothing* available at the start and `pickPhase` falling back to Standard on every draw, silently. **Still to build:** density is not yet coupled to the introduction rate ("density can remain fairly even through the periods where new items are introduced") - the least concrete part of the note and the one most likely to want a play-test judgement rather than a guess. **This supersedes §6.1's fixed progression and §6.3's exposure rules** - those introduce things in one order, the same every run, which is exactly the staleness this is aimed at. It wants a per-run *schedule*, drawn once at launch: a starting set (the standard bricks and power-ups plus a varying number of others), an order and a set of heights for the rest, and a per-run tweak to rarity that is bounded so a rare item never becomes the common one. Two things to get right that the note implies rather than states: the schedule has to be **saved with the run** (§9.3), or a resumed game would draw a different one and the field would change under the player - round 150's lesson; and a power-up introduced at height must not appear in the ring, the reference page's "this run" section or the unlock counters before it is available, or the screens will say it was there all along. Worth building the schedule as its own testable type before touching the generator, the way `DailyChallengeGenerator` was. |
| **Endless Mayhem brick sequence design** | Round 190, a heading James left open - the sequences themselves are still to be designed, and progressive disclosure above says which of them a given run may draw. Ask before building. |
| ~~**Mazes of indestructible bricks, dotted with normal ones**~~ - **built, round 194** | Round 190: "Mazes of indestructible bricks dotted with normal bricks so they don't just fly by". A brick sequence rather than a new type: Indestructibles already exist and already survive everything, so this is a generator shape. The dotting is the design point - a pure indestructible maze is a wall the ball rattles off with nothing to earn, and the normal bricks are what make the player want to get in there. Wants a rule for how the maze meets the descent, since an indestructible row that reaches the bottom zone leaves on the same terms as any other row - which turned out to need nothing, because `moveEndlessModeRowDown` already clears the bottom zone before the field steps, so a maze descends past like anything else and can never stall the field. **Three of them, as set rows**, which is where multi-row shapes live: **Catacomb** (110m, posts above and below with ordinary bricks in the aisles, open from either side), **Warren** (190m, pockets reachable from below with a mostly closed lid) and **Bastion** (280m, two ways in and a lid with two slots). Three rows each, because §6.2's existing rule is that a set row is a landmark punctuating the field rather than the field - a longer stretch of this character is what the **Fortress** phase is for. The dotting is written down as a rule about the whole catalogue rather than about these three, so anything heavy added later has to obey it: a pattern made mostly of indestructibles must contain something worth breaking. **That test immediately condemned an existing shape** - the Comb was a row of nothing but indestructibles, which is exactly the wall-that-flies-by James was describing - so two of its gaps carry an ordinary brick now. Three gaps are still open, so it is no harder to get through; going through it is simply worth something. |
| **Play-test round 169: the list, queued** | James's morning list, kept whole so nothing is lost, and struck item by item as each is built. **UI:** ~~(a)~~ **done, round 169** - the screens with *no* big centre button - main menu Settings, main menu Information, the Classic pack view - should use the **wide** small-button position, not the narrow one; only a row with a big centre button pulls its small buttons in to 55pt. That is a partial undo of round 157's "everything out to 55", and `menuButtonWideInset` is the number it wants. ~~(b)~~ **done, round 169** - in Settings, **Game Background moves to between Ball & Paddle Theme and Sounds**. **Gameplay:** **(c) half done, round 172** - **Clear And Retreat** should not merely remove the bottom two rows - it should move every row up two and take the lower-limit line up two with them, "as if the game is set 2 rows higher". **The line is done**: while the clock runs the lower limit sits two rows higher, so the room the clear makes is room the descent cannot take straight back, and the drawn line says so. Safe because the field is held for the whole duration, so nothing generates or steps against a floor that is temporarily elsewhere. **The lift landed in round 177**, on James's call that the top two rows may simply hide behind the HUD - see that round's row. ~~(d)~~ **fixed, round 171** - **the field stops descending after a pause**: seen after Clear And Retreat and a pause; pausing again and resuming started it again. James's read was that a pause taken *while a row is moving down* kills the descent animation on resume. **It was not the pause.** `moveEndlessModeRowDown` sets `endlessMoveInProgress` and the new row's own action clears it on completion - so if those bricks leave before the action finishes, which is exactly what Clear And Retreat does to them, the completion never runs. `countBricks` was the only other writer and it wrote from *inside* its loop over the bricks: so the flag ended up as whatever the last brick examined happened to say, and on an **empty** field the line was never reached at all, leaving a flag nothing could clear and a guard that refused to generate another row for the rest of the run. Pausing appeared to fix it because the ball reset on the way back through clears the flag by hand. It is gathered across the whole field and written once now, empty field included. ~~(e)~~ **fixed, round 170** - **a Mayhem run came back as a Classic one**: the extra-ball container, the score and the multiplier all appeared, and the pause screen read 0m at a real height. Reproduced by force-quitting during Mayhem and resuming; not reproducible in the original Endless. **The cause**: the mode lived only in a `UserDefaults` key written once when the run started, and a force quit can lose that write before it reaches disk. A missing key reads as zero, which is Classic. It only showed in Mayhem because Classic and the original Endless share a HUD - losing the key while playing Endless leaves a run that still looks and plays like Endless, which is exactly why it could not be reproduced there. **The fix**: the save carries its own mode now, optional so every older save decodes as it did, and a resumed run takes the mode from its save and writes the key back for everything that asks the key rather than the save. The splash's resume card reads the save too - it had been offering to resume "Endless Mode" into a Mayhem run. ~~(f)~~ **fixed, round 172** - **Descent** moves the field down too fast and at a variable rate. Both halves had causes: the step was 0.55s, just under two rows a second, which reads as the field falling rather than descending - it is a row a second now, still the mode's biggest single source of height over its fixed six seconds. And the *variable* rate was the countdown being zeroed the moment it came due, **before** the guards that refuse a step while one is animating or an aim is holding the field: a refused step threw its whole interval away and the next arrived an interval late, so the cadence wandered between one and two seconds depending on what the field happened to be doing. It is subtracted on the step that is actually taken now, so the phase survives a long frame or a short hold. ~~(g)~~ **found and fixed, round 180** - **Aimed Sticky's ball in the middle of the paddle**: the round-175 rule-outs were all correct and all about the extras, which is why they found nothing - the stale offset was the *main ball's*. The aimed catch set `ballIsOnPaddle` without recording where the ball landed, and `releaseBall` zeroes `ballRelativePositionOnPaddle` - so the follow snapped the caught ball to `paddle.x + 0`, the centre, one frame after the catch. Round 180's Ghost Ball sighting ("the ball suddenly appeared back on my paddle") was the same snap seen in worse light. The catch records its landing offset now, as the extras always did. ~~(h)~~ **fixed, round 172** - **Aimed Sticky should not move the paddle** - the drag sets the arrow only, unless Sticky Paddle is also running, in which case above the paddle aims and on or below it carries the paddle. Round 155 gave every aim that second behaviour; two decisions on one finger, and the aim is the one the power-up is for. `AimHoldControl.intent` takes a `paddleMayMove` now, so the rule stays where it can be tested. ~~(i)~~ **fixed, round 174** - after a force quit and restart mid-Mayhem, a **Directional brick's open face had changed**. The save recorded the role and not the side, so `makeDirectional` rolled a fresh one on the way back in - a brick whose rules change while the player is not looking, which is worse than a hard brick. `SavedBrick.vulnerableSide` carries it now, written before the role is applied so the roll is skipped, which is the bargain `makeFace` already makes with a shaped brick's orientation. Optional, so older saves restore with a rolled side as they always did. ~~(j)~~ **built, round 173** - an **invisible brick alone on Mayhem's bottom row flashes** when the ball hits the paddle, through the very interaction Classic uses. Classic's own rule asks whether anything visible is left *anywhere*, because there a hidden brick is a brick you cannot find; Mayhem asks it of the **bottom zone** as well - the test the descent itself uses to decide what holds it up - because a hidden brick down there stops the field, stops the height, and gives no reason for either. Anchored bricks are excluded: one does not block the descent, so it is not what needs explaining. ~~(k)~~ **built, round 175** - **Breathing bricks** may step between any two size classes, including down to nothing, and need enough room around them not to overlap a neighbour when they grow. Both ends moved: the bottom of the breath is 0 rather than half a cell, and below `solidBelow` the brick carries no body - the arrangement a Flashing brick already has in its passable phase, and necessary anyway because `SKPhysicsBody(rectangleOf:)` returns nothing for an empty rectangle, which would be a brick you can neither see nor hit. The top is `ceiling`, measured **once at birth** from the cells around the brick and capped at a Big brick: measuring every frame would interrupt a breath whenever a row arrived beside it, which reads as the brick stuttering rather than the field filling. A hemmed-in brick keeps to its own cell, which is exactly what every breathing brick did before, so a crowded field looks unchanged. ~~(l)~~ **fixed, round 172** - a **Big brick overlapping a Fixed brick**: the Fixed brick destroys it. The existing crush rule answers "is this brick descending onto an anchor", which is the other way in; this needs no descent at all, because **a Fixed brick anchors when it is struck** and a Big brick's other half may already be over the cell it anchors in. `endlessIIResolveAnchorOverlaps` sweeps for it each frame - it does nothing until something is anchored - and insets the frames before comparing, so neighbours that merely touch are not read as overlapping. |
| **Play-test round 176: the list, done** | James's evening list, all four built. ~~(a)~~ **fixed, round 176** - the **Game Centre button on the stats screen sat too narrow**, short of the close button's mirror image. `layoutMenuButtonRow` shares the row's leftover width between the buttons, so the row's width is an input - and the stats screen was the only one laying its row out from `viewDidLoad` alone, at the storyboard's width rather than the device's. It joins every other screen in calling `collectionViewLayout()` from `viewDidLayoutSubviews`, and `MenuButtonRowTests` pins the arithmetic as width-dependent, which is the fact that makes the second call necessary. ~~(b)~~ **done, round 176** - the **pause-presented Settings and Information (children included) take the narrow position; the main-menu versions keep the wide one**. They are one screen each, reached from two places, and what tells the openings apart is the 75pt play that `ReturnToGameButton` adds - a subview, not a row cell, so the row's own `sizes` cannot see it. `carriesReturnToGameButton` names the question once, `layoutMenuButtonRow` asks it for the shared rows, and `alignCloseButtonWithReturnToGame` is the same rule for the hand-built closes (Settings, the reference pages, Intro, Paddle Speed) - it moves the storyboard's leading pin to 55pt only when the play is on the screen, so the menu-opened versions never move. The background selector stays wide automatically: it hides the play, and the same flag drives both. ~~(c)~~ **fixed, round 176** - **Mayhem was still coming back from a force quit as Classic**, round 170's fix notwithstanding. Round 170 answered the lost `UserDefaults` key; this was a second, independent cause in `resumeBrickCreation`: the Mayhem rich-field restore returned **before** the `levelNumber == 0` branch that calls `prepEndlessMode` - the only place a *resumed* run is dressed as endless, because a resume never goes through `Playing`'s `switch levelNumber`. So `endlessMode` stayed false and Classic's score, multiplier and ball container drew over a descending field - and the original Endless could not reproduce it because that mode falls through to the cell path, which reaches the prep. `powerUpProbAllocation` sat in the same trap, so a resumed Mayhem run also dropped nothing. Both are hoisted **above** the rich-field return - and above rather than below it because `prepEndlessMode` calls `resetEndlessIIBricks`, which would otherwise empty the spinner/flasher/breather lists the restore had just filled. Verified on the simulator by force-quitting mid-run: the resume card reads Endless Mayhem with a height, and the run comes back wearing Mayhem's HUD over the same bricks. ~~(d)~~ **in, round 176** - **twenty-six power-up icons from the Desktop**: see §8.5, which now lists the two placeholders left. |
| **The ball's 5 degree turn near the low brick line - found and fixed** | Round 190, James: "still seeing the ball change angle in mid air in Endless Mayhem, again around the low brick level line. It seems to be changing by ~5deg which is why I think it's got something to do with the ball stuck prevention functions." It was the loop-breaker, and his 5 degrees was the giveaway - that is the exact floor of the old `5 + random(0...3)` kick. **Two causes, both closed.** (1) `BallLoopDetector` counted its three matching bounces across the *whole* 24-bounce history, which is far too generous for Mayhem: dense descending field, ball rattling among the bottom rows, and an ordinary rally revisits the same half-brick cell at a similar heading three times inside two dozen bounces without ever being stuck. The count is taken over the last nine now - room for a four-bounce cycle to prove itself and no room for a rally that comes back every eighth bounce. (2) The kick is **1 degree now, doubling** while the same loop keeps proving itself, capped at 8 where the old flat one sat: James's own suggestion, and it means a false positive costs a degree nobody can see while a real loop still comes free. And the reason this survived so long is instrumentation: `crookedBallWatch` stays deliberately silent when a frame's only excuse is "contact", so a loop-breaker kick *at* a contact was filed as an ordinary bounce and never printed. It leaves a note with its size now, so the next sighting names itself. |
| ~~**iPad: the pause and game-over screens lay out in a 420pt box**~~ - **fixed, round 191** | Rounds 188 and 189 measured it and ruled things out; 191 read the runtime frames and found it. It was **two things holding hands**, which is why neither reading nor the isolated test found it. (1) `PauseMenuViewController.collectionViewLayout()` *set the container's width by hand*: `if view.frame.size.width <= 414 { container = view width } else { container = 414 }`. Every iPhone is at or under 414, so on a phone that line is the full width and invisible; on a 1032pt iPad it is a 414pt box. (2) The storyboard carried a **size-class variation** excluding the container's leading and bottom constraints by default and including them only for `widthClass=compact` - so on a phone the constraints sized the box and the hand-set frame was ignored, and on an iPad the constraints were gone and the hand-set frame was all there was. Each half is harmless with the other absent. Both are gone: the variation is removed so the constraints hold in every size class, and the layout *reads* `containterView.bounds.width` instead of deciding it. The screen then wanted two things every other menu screen already had - `limitMenuContentSize()` from `viewDidLayoutSubviews`, which it had never called, and the row spacing recomputed when the width changes rather than once at load. Home is in its corner on an iPad now and the button row is centred on the capped column; a phone is pixel-identical, checked side by side. The diagnosis came from `os_log` read back with `simctl spawn log show`, which is how to get runtime values here - the console is otherwise unavailable. |
| **Presentation sites handed a child the wrong rect - `frame` where `bounds` was meant** | Round 188. `MenuNavigation` already carried the note - "bounds, not frame: the parent's frame lives in the grandparent's coordinates" - and the six older sites never got the fix: the pause menu, the in-between screen, and four stats/detail screens all did `child.view.frame = self.view.frame`. Every screen in this app is a child view added over another, so that rect is measured in the grandparent's space; it is also the wrong *size* whenever a transform is in play, because a frame is the transformed bounding box, and both the pause menu's parallax and the menus' 1.15 dismissal scale make it lie. All six go through `fillSelf(with:)` now, which clears the transform first (`MenuNavigation`'s other hard-won note), assigns `view.bounds`, and sets an autoresizing mask - the mask being the half that matters on iPad, where a frame assigned once never notices the window resizing under it. This did **not** fix the row above, which is recorded there as ruled out. |
| **iPad: the reference grids take more columns, not bigger cards** | Round 186, found by looking - the screen-by-screen pass the iPad audit had been asking for. With round 182's aspect cap applied a 13-inch iPad leaves the menus about 830pt, and the power-ups, bricks, achievements, app-icon and theme grids were all a flat three across: three 270pt squares with a 12pt name under a picture scaled up to match. The phone's grid photographed and enlarged, in other words, which is the thing the cap was meant to stop. `PackSelectViewController.columns(fitting:base:)` asks instead how many *reference-sized* cards fit - the card a 393pt phone produces at that grid's own count - so an iPad shows seven across at the size they were drawn, and the whole Classic set plus most of Mayhem's now fits one screen. `max(base, …)` means it can only ever add columns, so every phone from the 320pt ones up is untouched by construction, and a test sweeps every window iPadOS 26 can hand the app to prove no card ever strays far from the size it was drawn at. The **pack grid keeps its flat three** deliberately: it is a fixed handful of cards sized to fill the screen without scrolling, and spreading six packs into one row is a different screen rather than a better one. |
| **Play-test round 185: the list after the overnight batch** | James's five, all built. ~~(a)~~ **done** - the in-game power-ups screen's "This run" cells carry the same status word the HUD carries: **Active**, **Falling**, **Missed**, **Brick**. `InGameRecents` already knew each sighting's fate - the cells simply never asked. Written on the card itself rather than in a legend, so a glance down the grid reads as a run history. ~~(b)~~ **done** - the game-over and completion screens print the board's own leader beside the placing: "12th / 843 on the Endless Mode board · Best 1,204m". No extra Game Center round trip - `loadRank` was *already* asking for `NSRange(location: 1, length: 1)`, the first place, and throwing the returned entry away to read only the local player's rank. The unit is `GameMode.leaderboardUnit` rather than a mode test at the printing site, because the endless boards are `endlessBestHeight` boards and the classic packs are points. A board Game Center answered for with no entries yet prints the placing alone rather than "Best 0". ~~(c)~~ **fixed, and the unit was the bug.** Round 180 read "±25°" as degrees added to the bounce, so a shallow 15° bounce could be sent to -10° - below `minAngleDeg`, where `breakHorizontalRuns` picks it up and re-aims it, *every frame*, which is exactly the vibrating and glitching James described. It is now ±10% **of the angle itself**, as asked: a 90° bounce moves by up to 9°, a 15° bounce by 1.5°, and nothing can be pushed under the floor by construction. ~~(d)~~ **fixed at both ends.** Round 182 found the stale queue entry; what it missed is that `endlessIIAimMoved(to:)` **returns whether it took the touch**, and the touch handler discarded that return - so a touch during an aim ran the aimer *and* then moved the paddle anyway. That is the paddle-jumps-under-your-thumb half. The stuck half has a backstop now too: `tickEndlessIIAimHold` ends any hold that has no target left, so a queue that empties without going through the release path cannot leave the aimer owning every touch. ~~(e)~~ **done** - four HUD icon pairs from the Desktop, three of them wired through `PowerUpIcon.hud`. **And round 184's (b), half of it:** the two-row shift James saw when he collected Clear And Retreat was the *field*, not the animation - round 177's lift was one write, so the whole field arrived two rows higher in a single frame. It glides over a third of a second now, and the hold is extended to cover the glide at both ends, because a brick mid-slide is between rows and a brick's `position.y` is its row (§8.6). The stutter half is still unproven and wants a retest. |
| **Play-test round 184: the overnight list** | James's nine. **Eight built, one half-answered** - see (b). Struck individually below. ~~(a)~~ **fixed** - the zone rule stands down entirely on a **Fog of War** day. Round 173's flash exists to explain a brick the player has no way of knowing about; on a fogged day every brick starts hidden *by design*, so the zone is nearly always all-hidden and the flash fired on every landing. Explaining the fog to the player who chose the fog is the twist being handed back. Nothing to do with the resume - a fresh fogged run does it too. **(b) half-answered, and honestly so.** A real and serious performance bug was found and fixed on the way: round 180's self-healing recount ran `countBricks` in *every brick's* build-in completion, so each new row swept the whole field a dozen times - hundreds of bricks, every row. It is debounced to one sweep per row now (`endlessIIRecountAfterBuildIn`). **But I could not tie that to Clear And Retreat specifically**, and the lift itself is guarded to fire only when the lift changes, so it is not a per-frame cost. If the stutter survives this, it wants a repro with the power-up in hand. **The two-row shift is found and fixed in round 185**, and it was not the collection animation at all - it was the field. Round 177's lift is a single write, so the whole field arrived two rows higher in the frame the power-up was caught in: nothing in the wrong place, everything there in no time, which is exactly what a two-row jump looks like to the eye watching the power-up it just caught. It glides now, over a third of a second, with `endlessIIFieldIsHeld` extended to cover the glide at both ends - because mid-slide every brick is between rows, and a brick's `position.y` is its row (§8.6). The stutter is *not* answered by that and still wants a retest: round 184's O(n²) recount fix may already have cured it. ~~(c)~~ **fixed, and the cause is arithmetic rather than feel**: the ball was drawn toward the paddle's *centre*, and a paddle's centre can never come closer to a wall than half its own width - so the outer half-paddle of every field was unreachable by construction, however well it was played. The steering target is now led by the paddle's own speed (`steeringLead`), which is exactly the inertia James asked for: sweep toward a wall and the ball runs ahead of the paddle and arrives at the column beside it; hold still and the lead is nothing, so a parked paddle steers as it always did. Capped at 30% of the field so a flick cannot pin the ball to a wall. ~~(d)~~ **done** - it takes the paddle's own width, height and picture (including the Retro theme's separate art, which Double Paddle learned about in round 166), tinted the Giga-Ball lime and nine-sliced so its rounded ends survive at any paddle width. The old 0.42-of-the-field constant is kept as `endlessIISafetyPaddleLegacyWidth` for the reasoning it carries. ~~(e)~~ **fixed, and not where it looked**. The list was *already* newest-first by appearance and a test had said so since round 8. What it did not do was move a power-up when it was **caught**: a drop that fell early and was collected late sat far down the list under everything that had merely fallen since, though catching it was the freshest thing on the screen. A catch now moves its sighting to the front; every appearance is still its own entry. ~~(f)~~ **done, to James's own suggestion** - the halo stands at the centre of the field at the paddle's height rather than riding the paddle. Sweeping side to side swept the glow across the whole width, which cleared the bottom rows as fast as a thumb could waggle, and in a mode where the bottom rows *are* the height that is the run being played for you. Standing still it still asks something: the bricks it reaches are the ones the field brings over the middle. ~~(g)~~ **fixed** - anchoring calls `removeAllActions()` to stop a descent already under way (it must, or the brick finishes moving after being pinned), and stopping an action leaves the node wherever the animation had got to. A brick's `position.y` *is* its row (§8.6), so a brick pinned between two is read as being on neither. The anchor now lands it on the nearest row centre, using the field's own grid rather than a second opinion about where the rows are. ~~(h)~~ **done** - told from the *clamp* rather than from the paddle's position, because a paddle already against the wall and pushed harder does not move at all, and that is exactly the moment worth feeling. Fires once on arrival rather than every frame a thumb leans on the edge, and stays silent while Wrap-Around runs, where there is no wall to hit. ~~(i)~~ **found at last, two years of rounds later.** `FixedWidthNumberNode` kept a stored array of its character nodes *beside* the children those nodes actually were - a second copy of "which children exist". The moment the two disagree, and a decode restoring children without a plain Swift array is exactly that, `show` finds no characters, builds a fresh set and adds them **on top of** the ones already there: both sets then draw the same digits in the same place, a pixel apart. James's repro is the clue that names it - pausing and leaving the app, over and over, without quitting. The array is derived from the children now, so they cannot drift; four tests cover it, including the restored-children state itself. |
| **Play-test round 182: the list after the first proper play of Split Paddle** | Five, all built. ~~(a)~~ **Split Paddle**, renamed from Double Paddle - *for the player only*: the id, the `endlessIIDoublePaddle` clock key and the asset name stay put, because that key is written into save files and a run left mid-split on the shipped build has to come back split. The gap is **two ball widths** now (James: "still too small - go with 2 ball widths"), and the segments keep their rounded ends: they nine-slice their texture with the very trick James named, the one an expanding paddle already uses (`paddleCenterRectPlus`). The cap rects are named constants now rather than literals inside that method, because two things want them - and a segment cannot simply copy `paddle.centerRect`, which is the *unprotected* whole-texture rect at standard width, which is what was squashing the ends. ~~(b)~~ **Ghost Ball hides what the ball is wearing**: the Aura's ring takes the ball's own alpha each frame. The Wrecking Ball's spikes already did, by being children of the ball - the Aura is the one decoration hung on the scene instead, which is why it was the one still showing. Only the drawing follows: the reach, the strikes and the clock are untouched, and a test proves it by striking the same field ghosted and unghosted and comparing. ~~(c)~~ **Aimed Sticky's stuck paddle**, which is three symptoms from one stale entry - and the same root the round-169 "ball in the middle of the paddle" and round-180 "ball back on my paddle" reports were circling. A held ball *can* reach the bottom (a portal or a wrap drives the paddle out from under it), and the queue survived that by *skipping* nodes that had left the scene. The primary ball never leaves the scene, only moves, so **its** entry could never be skipped: it stayed at the head of the queue for the rest of the run, `endlessIIAimTarget` never went nil, and `endlessIIAimMoved` takes every touch while there is a target - which is a paddle that has stopped moving. The ball meanwhile had been handed a survivor's position and heading by the carry-on rule, so it "flew off in the wrong direction" and ended up wherever that left it. `endlessIIBallWasLost` releases a lost ball from the hold and ends the aim hold if it was the one being aimed; `pruneEndlessIIHeldBalls` keeps the queue and its offsets in step besides. ~~(d)~~ **The iPad caps its shape, not its size** - see the row below. ~~(e)~~ Ten refined icons from the Desktop, including **Cluster's real art**, which retires its placeholder. |
| **Round 181: a force quit early in a run could leave the app unable to start** | Found while chasing something else, and the most serious thing this session turned up: **the app hung on the splash screen for ever**, with the title and credits showing and no way past. Reproduced from a *clean install* - start an Endless Mayhem run, force-quit within the first few seconds, relaunch. The cause is that `resumeGameToLoad` and the save are **two different keys written at two different moments**: the flag goes down when the run starts, the save is written later, so a quit in between leaves the flag set with nothing behind it. `SplashViewController` then asked the flag alone, correctly refused to draw a resume prompt it had no data for (drawing it would have unwrapped a nil and trapped - the crash loop the save format was written to end), and **never dismissed**, because `removeAnimate` is only ever reached on the `gameToResume == false` path. The crash had become a hang, which is worse: a crash at least says so, and a hang looks like a dead app. The question is now asked once, where both halves are actually in reach - `SavedGame.canResume(from:)`, the flag **and** a save that loads - and the splash clears the stale flag as it goes, so the state cannot outlive one launch. Tested five ways in `SavedGameTests` (flag alone, save alone, both, undecodable save with the flag set, fresh install) and verified on the simulator as a straight A/B: the same broken container hangs on the old binary and reaches the menu on the new one. |
| **Play-test round 180: the morning list** | James's seven, all built. ~~(a)~~ **rebuilt, round 180** - **Double Paddle**: the gap is measured off the *ball* now (`endlessIIDoublePaddleGapBalls`, a ball and a half) - the old 14%-of-paddle gap was almost exactly one ball, so the ball nearly never fitted and the middle read as solid, which was also (as it happens) the report's "gap shouldn't collide": the gaps carry no rectangle at all, there was just no gap the ball fitted through. A longer paddle makes **more segments, not longer segments**: `endlessIIDoublePaddleLayout` fixes the segment at the standard paddle's half and fits as many as the span takes with at least the minimum gap between; leftover width widens the gaps, never the pieces; a shrunken paddle gives up piece, never gap. And it **ends on paddle hits** - the honest finding is that its twelve seconds were in the Lock's freeze list but in *no run-down loop*, so it never ended by any road; James's ruling made hits the design rather than the workaround. ~~(b)~~ **done, round 180** - **Randomised Bounce** was already an offset on the honest angle rather than a fresh roll; the spread comes down from ±35° to James's ±25°, which is the difference between a nudge and what the play test called "totally random". ~~(c)~~ **fixed, round 180** - **the flash-then-disappear's second cause**: Classic's all-hidden trigger ("is everything you could still hit invisible") still ran in Mayhem, and Mayhem's Fixed bricks wear the Indestructible texture that check deliberately ignores - so a moment where the only visible bricks were Fixed walls read as an empty field, and every paddle hit flashed the mode's ordinary hidden bricks on and straight off. The Classic rule is now scoped out of Mayhem entirely; the zone rule is the mode's own answer. ~~(d)~~ **fixed, round 180, and it closes (g) of round 169's list too** - **the ball appearing on the paddle**: it was the aimed catch all along. The on-paddle follow places the ball at `paddle.x + ballRelativePositionOnPaddle`, and `releaseBall` zeroes that offset - so a caught ball sat at its landing spot for one frame and then snapped to the paddle's *centre*, which reads as a teleport (and mid-Ghost-Ball, as an apparition). The extras' branch had always recorded its offset in `endlessIIHeldOffsets`, which is exactly why round 175's hunt through the extras ruled everything out: the main ball's branch was the one with the stale memory. It records its landing offset now. ~~(e)~~ **done, round 180** - **Mirror Paddle** wears the Giga-Ball lime at full blend (re-tinted after every dress refresh, because a texture write ships with whatever colour is lying around) and stands a step behind the real paddle, so when the two cross the white one in front is yours. Its ring counts down now for the same reason Double Paddle's does: the twelve seconds were wired to nothing; it ends on paddle hits, spent by the real paddle only, since `endlessIIMirrorPaddleHit` deliberately spends nothing. ~~(f)~~ **fixed, round 180** - **bricks stopping short of the bottom**: the step chain recounts 0.075s after a step begins, and the build-ins run 0.05s on the same frame-quantised clock - one hiccupped frame leaves an action alive at the recount, round 171's honest flag refuses the step, and *nothing asked again* until the next brick was destroyed. The build-in's completion now calls `countBricks()` itself, so the cadence is self-healing: when the last animation genuinely ends, the zone question is asked once more. Untestable in a unit test (it lives in an `SKAction` completion), so it wants a play-test eye on a long quiet descent. |
| **Play-test round 177: the bedtime list** | James's five, plus a decision. ~~(a)~~ **done, round 177** - **Clear And Retreat lifts the bricks now**, with James's ruling on the round-172 question: "I think it's ok if the top 2 rows just get hidden behind the HUD. They're there, but effectively out of the game and hidden from view." `tickEndlessIIRetreatFloor` moves the line *and* every brick together - anchored ones included, because this is the frame moving rather than the conveyor conveying - and both come back down when the clock ends, however it ends. One variable drives both, which is what keeps a resume honest: a save taken mid-retreat stores rows with the lift subtracted (`endlessIICanonicalRestingY`, the same thinking as saving a build-in's destinations), and the restored clock's first tick lifts the restored field exactly once. In one write, not an action, for §8.6's reason. ~~(b)~~ **fixed, round 177** - **every brick flashed on a paddle hit and then disappeared, recurring**. James suspected Descent; it was round 173's own trigger doing its job and the *flash* overreaching. The off-phase hid everything wearing the ordinary brick texture - safe in Classic, where the interaction only ever fires when nothing wearing it is visible, and field-swallowing in Mayhem, whose coloured bricks all wear `brickNormalTexture` and whose trigger (a hidden brick alone in the bottom zone) fires with the rest of the field in plain sight. A field of freshly hidden bricks then re-arms Classic's own all-hidden rule on every later paddle hit, which is the "kept happening". The flash now remembers exactly which bricks it revealed (`invisibleBrickFlashRevealed`, on the scene rather than captured, because a second flash replaces the first's pending action) and the off-phase restores only those. Descent was incidental - it just marches rows into the zone. ~~(c)~~ **fixed, round 177** - **Wrap-Around: the ball wrapped once then went back to bouncing off the walls** while the paddle wrapped happily the whole time. One wall hit can be reported as more than one contact, and every note used to be its own teleport - two notes are a round trip that lands the ball back on the wall it struck wearing the engine's bounce, which *is* a bounce as far as the eye can tell. The paddle never suffered because its wrap is a position rule with no contact in it. `endlessIIWrapTook` notes a ball once per frame now, and `applyEndlessIIWraps` only wraps a ball whose pre-step heading actually points into the wall it is beside, so a late or duplicate note finds a ball mid-flight and stands down. ~~(d)~~ **done, round 177** - **the daily level splash shows every twist**. The storyboard gives the splash's third label a fixed one-line height, so `numberOfLines = 0` had nothing to grow into and every twist after the first was clipped - the same fixed-height trap that swallowed the run-kind line twice (rounds 14 and 15). The box now grows a line-height per twist. Verified on the simulator against a two-twist day (Power Shower + Fog of War, `testDayOffset` 1, put back to live afterwards). ~~(e)~~ **done, round 177** - **Fog of War: launching before the fade has finished takes the field at once**. `snapDailyFogShut`, called from `releaseBall` so it covers every launch - which is why it only touches what the fog still owns: the taking list (scheduled or mid-fade) and the pending list (build-in never reached them), never a brick a strike has revealed, which a later launch must not take back. |
| ~~Cluster, a new power-up~~ | **Built, round 178**, to the round-169 design: twelve tiny balls burst upwards from the paddle's centre at random angles in a 25-155° spread, each a single hit on whatever it meets and destroyed on contact. The deciding implementation idea: **each ball is a free-flying laser bolt dressed as a tiny ball**. It wears the laser's category - so every brick already tests contact with it without touching a single brick body - and `hitBrick`'s laser path already does one-hit-then-gone for every type: Portals struck not entered, power-up bricks spent, Directionals asking which face. What it adds over a laser is the ball-ness: it bounces off the *side* walls (the contact branch declines to remove it there; the engine does the bounce), dies at the ceiling, and leaves quietly at the bottom without costing a life - because as designed it is **ammunition, not Multi-Ball**: never in `endlessIIExtraBalls`, never dressed by Giga or Aura or spikes, and the lasers-fired statistic does not count it. In code the burst lives in `EndlessIIClusterBurst.swift`, because the word "cluster" already belongs to the row generator's designed brick formations (`EndlessIICluster`) - two unrelated ideas sharing one favourite word, and the test suite already had an `EndlessIIClusterTests`. Uncommon, good, weight 4; drawn placeholder icon (§8.5); instant, so no clock, no ring, nothing for a Lock or a save to care about. |
| ~~Real artwork for four power-up icons~~ | **In, round 169.** `PowerUpLandingMarker`, `PowerUpLock`, `PowerUpMultiBall` and `PowerUpWreckingBall` retire four of §8.5's drawn placeholders, and the two round `LandingMarkerIcon` / `WreckingBallIcon` go where a round icon belongs - inside the ring HUD, which had been drawing the rounded-square badge in a circle. **How a placeholder retires is now one word**: `PowerUpIcon.artwork(_:_:)` takes the asset name and keeps the drawing as its fallback, so art arriving under the name an icon already carries changes nothing else, and a half-drawn set is never a half-broken app. The Disabled variants are installed and unused: they are the old modes' tray convention, and these two power-ups are Mayhem-only, where the HUD shows only what is running. Worth a word from James on whether they were drawn for something else. |
| Menu breathing room, throughout the app - **done, round 74** | James, round 73: table views across the app start too close to the page title and finish too close to the bottom button row, and the whole thing feels compact. Wanted: more space at both ends, everywhere, rather than screen by screen. The screens share a nib and a navigation pattern but *not* their layouts - each is its own storyboard scene with its own constraints - so the honest first move is to find whether `limitMenuContentSize()`, which every one of them already calls from `viewDidLayoutSubviews`, is a place the gap can be applied once. It was: `UIViewController.menuListBreathingRoom` is one `UIEdgeInsets` applied as a *content* inset to every table found in the screen, from `limitMenuContentSize()`, so all twelve screens got it from one number and nothing in a storyboard moved. Two things the doing taught: these tables set `contentInsetAdjustmentBehavior = .never`, so **the content offset has to be moved with the inset** or the padding is real and invisible; and both places that ask "does this fit" - `applyScrollAffordance` and `fitGlassPanel` - measure content against the frame and had to start counting the padding as content, or a list padded just past the bottom decides it fits and refuses to scroll to its own last row |
| The grid layout - **done, all five, rounds 77-79** | App Icons and Ball & Paddle themes are grids. `PackGridCell` took them with two additions rather than a rewrite: no list button when nobody hands it a handler, and `recolour:` on `show(...)`, because a pack icon is a flat glyph and an app icon is a *picture* - templating one leaves a white silhouette, which is what the first screenshot showed. The grid is built in code over the table in `ItemsDetailViewController` and borrows its frame, because that scene serves four lists and only two want squares. **Two traps for the remaining three:** the VC had to declare `UICollectionViewDelegateFlowLayout` - without it `sizeForItemAt` is silently ignored and every square comes out 50pt, which looks like a layout bug and is a conformance one; and the back-button row shares every collection-view delegate method on these screens, so each one needs its `collectionView == grid` branch. Round 78 added the **Power-Ups and Achievements** lists, on James's call that a square carries the icon and the name while the description stays on the detail page. Their names are phrases rather than words, so the square gained a `nameSize` and the screen picks it: 13 for packs and themes, 11 for power-ups, **10 for achievements over two columns rather than three**, because "Endless Mode 1,000m Milestone" does not fit a third of a phone. The power-up grid keeps its pinned THIS RUN / OTHER headings through `sectionHeadersPinToVisibleBounds` and a supplementary view with its own dark blur backing - the same recipe the rows used. Round 79 finished with the **Bricks** reference, and its headings pin. Worth recording *why that changed*: the old table was deliberately **grouped rather than plain** so its headings would not pin, because a header floating over the rows through the table's edge fade read as a glitch. A collection view's header carries its own blurred backing, so the squares disappear behind the heading rather than through it - which is what makes pinning the better answer now rather than the same mistake again | James, round 75: the Classic pack screen's grid of squares reads better than a list, and he wants the same on **App Icons, Ball & Paddle themes, the Power-Ups reference, the Bricks reference and Achievements**. `PackGridCell` is the model - a code-built square with the art, the name, a lock and a tick, glass already applied - and `PackSelectViewController` shows the flow layout and the floor-the-column-count arithmetic that a play-test round already had to fix once. The five differ in what a square must carry: App Icons and themes need a tick for the chosen one and a lock with its unlock sentence; the two reference pages need no state at all but the Power-Ups one has **pinned section headings** a grid must keep; Achievements needs the completion badge and its date. Do them one at a time with a screenshot each - a grid of eleven packs is not a grid of fifty-one power-ups, and the cell size that suits one will not suit the other |
| Brick reference: sticky section headings - **done, round 79** | James, round 75. BEHAVIOURS, STYLES and SIZES should pin the way the Power-Ups page's do, and look the same doing it. That page's are a `viewForHeaderInSection` with its own dark blur backing and the app's lime label, plus `stickyHeaderBand` set on the table so the pinned header stays out of the edge fade - `ItemsDetailViewController` around line 176 is the whole recipe, and the band is the part that is easy to miss |
| Liquid Glass: the settings and menu row cells - **done, all six screens** | Round 62 did the cheap experiment below on the **Information screen only** (`ItemsViewController`), and the answer is that a translucent row does read against the game backgrounds. The glyph question turned out to be smaller than feared: the PNGs are flat single-colour shapes, so `.withRenderingMode(.alwaysTemplate)` throws the purple away and keeps the silhouette - no redrawing, no new assets. `SettingsTableViewCell` now carries `applyGlass()`, `setIcon(_:)` and `showTapFeedback()`, and `prepareForReuse` puts the whole card back because six screens share the nib. Round 64 rolled it out to Settings, Mode Select, Brick Types, Items Detail and the Splash resume button, and glassed those screens' close buttons to match. **What the roll-out actually cost was not the rows - it was everything the screens draw over them.** Six things had to learn about glass: the icon (template only for flat glyphs - `setIcon(_:recolour:)` has no default, because a wrong `true` flattens pack art and a wrong `false` hides a glyph), the press feedback (`setPressed`, which skips the colour, since painting the app's lime into `cellView2` puts the flat card back for the length of a touch), the state column (`setStateColour`, which *inverts* the scheme - the flat card meant "on" by being darker, including a four-step grey ramp for paddle speed), the row name (`setLabelColour`, keeping the quarter-alpha fade that means locked), the completion tick, and the swipe-up info button. The lesson for any further glass work: the material is one line, and the contrast scheme built on top of a light card is the actual job. **Still open:** whether the tint should drop below 0.24, and whether rows want the buttons' explicit rim. Locked rows on the unlock pages stay noticeably paler than the rest, because "locked" is drawn as the cell's own light `.regular` blur over the row - it reads as a state rather than a mistake, but it is lighter than anything else on a glass screen. Round 66 finished the close buttons - every screen in the app now has a glass one (About, Background, Intro, Level Selector, Level Stats, Pack Select, Stats and Item Stats joined the six from round 64). Round 67 finished it. **Every round button in the app** goes through one door now - `MainMenuCollectionViewCell.setButton(_:pointSize:rimmed:)`, which assigns the PNG first (so iOS 15 keeps exactly the button it has) and then glasses it if `systemGlyph` names a stand-in. Adding a glass button is a line in that table. `ButtonNull` is absent from it on purpose, which is how the invisible spacer stays invisible. The **pack grid** squares are glass, with the pack icon template-recoloured, and the pause screen's **home button** was the last PNG left. **Deliberately not glass:** the *pause menu itself*, which turned out to have no panel to glass - it is a full-screen dark blur with labels straight on it, and a second material over the first would only mud it; and the background chooser's **preview card**, which shows the background being chosen, so a material over it would obscure the one thing the screen exists to show. **Ruled out by James (round 68): the in-game power-up HUD stays as it is** - it sits over live play, it is the one surface that would cost frames, and it already reads. That closes the HUD question rather than leaving it pending a measurement. Round 69 did all five of James's round-68 list: the main menu's mode cells, a pack's level list, the statistics tables, the Daily Challenge cards and the pop-up's dismiss button. `SettingsTableViewCell.addGlass(behind:cornerRadius:tint:)` is the shared recipe now - it returns the effect view, or `nil` below iOS 26, so a caller uses the answer as its own "am I glass?" flag. **Only the pale pop-up button is glass**; the green one is how the pop-up says which button does the thing, and two identical shapes would not. Round 70 made a stats table **one panel with hairlines** rather than a card per row - the play test read a stack of framed rectangles as "too many edges", which it was. `addGlass(under:cornerRadius:inset:)` puts the material in the table's *superview* so it does not scroll away, inset 20 to stand exactly where the old per-row cards did, and `StatsTableViewCell.showDivider(_:)` is told by the table itself whether it is the last row. **The big play glyph: settled by measurement, not by explanation.** The collection-view path renders it smaller than `applyRoundGlass` does at the same point size, weight, colour and shadow - rounds 68-70 matched each of those in turn and the play test measured it smaller every time, on the five screens that come through the cell while the four using `applyRoundGlass` were right. `MainMenuCollectionViewCell.bigGlyphPointSize` is 34 against the helper's 28 because that is what matches on screen. If the cause ever surfaces, that constant is where to undo it. **Tidy-up owed:** `addGlass`, `glassTint`, `glassForeground` and `glassIsAvailable` are statics on a *table cell* because that is where the first two already lived and adding a file means four hand-edits to `project.pbxproj`. Six unrelated types now import their look from there. It wants its own file `SettingsTableViewCell.cellView2` is the light-grey rounded rectangle behind every row on six screens, and the glyph beside each label is a **dark purple PNG chosen to sit on light grey**. Make the cell glass and every one of those glyphs is dark-on-dark - the exact problem round 53 fixed on the play button, except there is one button and there are dozens of these. So the order is: decide the glyph treatment first (recolour the assets to white, or tint them white at runtime if they are template-capable, or keep the rows light and glass only the *panel* behind them), then apply. **Cheap experiment worth doing first:** glass one screen's cells with the glyphs left as they are, purely to see whether a translucent row reads at all against the game backgrounds - if it does not, the asset question never needs answering |
| Liquid Glass - **the roll-out is done; one candidate left, and it is the risky one** | Rounds 52-57 settled the **recipe** on one button (`applyRoundGlass`): `.regular` material, tinted with the app's purple at 0.38 - *the one dial for edge brightness* - shaped by `cornerConfiguration` rather than clipped, `isInteractive` off, and a glyph baked white with `.alwaysOriginal` plus a soft shadow so it never depends on what the material is doing. **Round 195 audited this row, which had gone badly stale** - it still read "started, one button done", and the work had in fact finished: `MainMenuCollectionViewCell.systemGlyph` maps all seven round buttons (close, info, settings, play, restart, home, leaderboard) to SF Symbols, which is exactly the inventory this row asked for, and `applyRoundGlass` covers the seven UIKit ones beside them. The settings and menu row cells were already marked done; the **pop-ups** went glass in round 59 (`GigaBallAlert`, `.regular` tinted a little heavier than a button's, because a card is a surface to read words off rather than a mark to spot); and there is no separate **pause menu panel** to dress - that screen is content over the blurred game rather than a card. What is left is the **HUD capsule** in-game, and it is left for a reason: it is an `SKShapeNode` with a flat 0.15 white fill, not a UIKit view, so `UIGlassEffect` does not reach it at all. Dressing it means either a UIKit overlay above the scene or faking the material in SpriteKit, over live gameplay, at a per-frame cost, in the modes carrying the leaderboards. Worth doing only with a clear reason and a frame-rate measurement. |
| Liquid Glass on the round buttons - **started, one button done** | James's 1.3 scope call. `applyRoundGlass(to:radius:)` is in `ReturnToGameButton.swift` and the big return-to-game play now wears `UIGlassEffect`, gated to iOS 26 with the pale disc as the fallback - the app supports iOS 15, and a button invisible on an older phone is a regression dressed as a feature. **The rest is an asset job before it is a code one:** every other round button is a PNG with the circle *and* the glyph baked into one opaque disc, and glass cannot sit behind a glyph welded to a disc. They need template glyphs (SF Symbols where one fits, monochrome assets otherwise), after which the helper applies unchanged. That is what FUTURE-RELEASES.md means by "in-app icons updated to Liquid Glass versions", and it is worth knowing before the rest is quoted as a code change |
| ~~Descent measured in rows rather than seconds~~ | **Built, round 178**, to the shape this row predicted. A Descent is `endlessIIDescentRows` (six) now, spent one per row *taken* - a hold or a slow animation delays a row but can no longer eat it, so every collection is worth exactly the same height, which was the point of James's round-52 suggestion. The ring shows six segments, in the HUD and on the pause screen. The predicted complication was real and answered the predicted way: `EndlessIIClock` carries `countsTurns` and answers `outlastsALockDrop(lead:)` itself - a seconds clock needs more left than the fall takes, a rows clock outlasts any fall because rows do not decay - so the Lock's drop rule stopped assuming seconds, and a Lock is rightly worth dropping over a Descent down to its last row. Descent stays in the timed list because a Lock should freeze it, and the freeze now truly reaches it: the pacing accumulator runs on `endlessIIClockDelta`, closing a quiet leak where the raw frame delta let a locked Descent keep stepping while its clock stood still - free rows for the length of every freeze. The flag is not in the save format; the restore path sets it the way `collect(turns:)` does. |
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
| ~~Ghost Ball power-up idea~~ **Built, round 125.** | Twelve seconds, uncommon, harmful, extending its own duration. The ball is invisible while it is above `finalBrickRowHeight` and reappears below it, so the line it comes back at is the field's own bottom and moves with the descent without the rule being told. **Dressing only** - the tick sets alpha and touches nothing else, which is what makes a handicap this strong survivable: the ball you cannot see is exactly the ball that was always there, and the Trajectory Line still draws its path, which is a counterplay worth leaving in. The one failure that would cost a run is a ball left invisible by an expired power-up, so the tick puts every ball back on the frame the clock ends and the reset does the same; both are tested. The weight is the tunable if it reads as too punishing in play. Original note: Play-test round 11, new bad power-up: the ball is invisible until it drops below the lowest brick line - you see where it lands, not where it flies. Pool/duration/conflicts undecided; visibility is a per-frame alpha rule from `update`, like all Mayhem dressing |
| ~~Tap-to-skip the intro splash and build-in~~ | **Built** (rounds 15 and 17). The build-in's skip lands the whole field on its rows; the intro's hold now clears on a tap, running the dismissal it was going to run anyway and in the same order, because the opening field waits on `levelIntroWillClear` and the lives roll in on `levelIntroDidClear`. Original note: Play-test round 11: a tap during the level intro splash and the brick build-in should skip to their end states - the same jump-to-end-and-hold rule the app splash learned, including §12.0's second-round caution that a skipped build-in must land every brick on its row |
| ~~Big play on every pause sub-screen~~ | **Built** (round 17). One extension rather than seven copies: it finds the paused game by walking up the child chain, adds nothing where there is no run behind the screen, and the background selector takes it off itself because that screen is a picture of the playfield. Original note: Play-test round 11: settings, info and the reference pages reached from the pause menu should each carry the big centred play so the player can return to the game from anywhere, small close on the left, the screen's own extra (leaderboards etc.) on the right - the same row grammar as everywhere else. The one exception, by name: the background selection screen. Touches every MenuNavigable presented over the pause |
| ~~Stats page sections~~ | **Built** (round 28): five tabs - All, Classic, Endless, Mayhem, Daily - above the same table. The twenty-five hard-coded rows became `StatsPage`, which turns a `TotalStats` into a list of rows away from the screen, so what the page says can be tested; eleven tests do. Which stat belongs to which tab is read off where `InbewteenLevels` writes it, not decided by hand. Two sections are new numbers rather than moved ones: **Endless Mayhem** was recording heights and showing them nowhere, and the **Daily** shows days played, days posted, attempts, best day and total posted score. Rows for a mode never played are no longer added, which retires the old blanking trick of setting the *table's* row height to zero to hide one row. Streaks are the obvious missing daily stat and are daily spec phase 5, not this |
| Icon pass - **audited round 199: mostly built or overtaken; two live pieces** | Play-test round 11's icon list, re-checked against the app as it stands. **Overtaken by better answers:** the theme row was to get a paint brush, and since round 85 it shows *the theme you are actually wearing*, which beats a generic glyph the same way the App Icon row's own artwork does; the background row's move happened in round 169. **Built:** the daily's round main-menu icon; the Mayhem icon's symmetric second ball (see `GameMode.menuIcon`, and tonight's screenshots); the pause, game-over and in-between screens leading with the mode icon. **Still live:** (1) the storyboard mode menus - Classic, Endless, Mayhem - still put the title above the icon, where round 12 asked for icon-then-title the way the daily briefing does; a storyboard visit, best done with the simulator open. (2) The Icon Composer app icon inside the app (About, Vanilla badge, Classic menu icon) still waits on an exported 1024pt PNG - **James's side**, since `.icon` bundles cannot be read at runtime. The background row's tiny paddle/ball/bricks scene and "the stats icon everywhere" stay queued as §8.5 art rather than placeholders worth redrawing twice. |
| ~~Lock and Key~~ | **Built** (round 25). One `endlessIIClockDelta` returns zero while a Lock runs and every timed clock in the mode counts down through it, so there is one place that decides and no clock that can be forgotten; the Lock's own clock deliberately does not use it, or a run without a Key never gets its timers back. A Key clears the clock outright rather than shortening it. `endlessIITimedClocks` is the single list the freeze and the drop rule share - a timed power-up left out of it would neither attract a Lock nor be frozen by one, which from the outside looks like the Lock being broken, so a test walks every entry. Lock drops only while something has more than the fall time left; Key is weighted 30 inside its window and 0 outside it, both set per row because they are the only drops whose eligibility is live game state. **Closed** (round 31): Wipe is built, and "Wipe must not remove a Lock" is now a rule with a test on it - a Wipe that removed a Lock would do everything a Key does and more, and a Key nobody needs may as well not drop. Original note: §5.4's originals, still unbuilt. Lock freezes the timed clocks (the turn-based ones are immune by nature); Key ends it. Their conditional drop rules are most of the work |
| ~~Endless Mayhem badge on the power-ups page~~ | **Built** (round 30): an infinity mark in the state column of every Mayhem-only power-up, and a "Found in: Endless Mayhem" line on the page you open - a badge in the list and the sentence on the page, the division the brick types page already draws. The mark is the readable half of the mode's logo at eleven points; §8.5 can replace it. **Not** taken from `PowerUp.availability` as this row assumed: that field lives in `PowerUpCatalogue`, which has drifted from the shipped game (see the row below). It is taken from the index instead, which is what the game itself uses - `powerUpNameArray` is the original twenty-eight followed by Mayhem's twenty-two, and the drop probabilities are only ever set for the first twenty-eight |
| ~~Paddle surface shapes~~ - **built, round 149**: Convex, Concave, Wavy and Jagged, the fifty-sixth to fifty-ninth power-ups. | New power-up family (play-test idea, fourth round): convex, concave, wavy and jagged paddle tops, all *bad*, all turn-based, each making the outgoing angle harder to predict. One shape function per variant feeding the existing angle line, so they cost a curve rather than a physics body - but they conflict with the paddle group (Inert, Flipped, Auto-Aim at least), which is where the design work is |
| More twists, and more variety | Standing request from every daily round. **Round 187 built the first batch since launch: Mirrored and Upside Down**, both Classic-only and both layout-only, so one reflection in `brickCreation` reaches all hundred-odd levels without touching any of them - and stands down on a resume, where the save already holds the turned-over field. They arrive in a new `layout` category, which is where the interesting part was: a new *twist* is kept out of an older day's pool by its activation date, but a new *category* is drawn by index out of `Category.allCases`, so a fourth entry would have turned every past day's `roll(3)` into a `roll(4)` and rewritten challenges people had played. Categories carry activation dates of their own now, and a golden-record test pins thirty days of the launch window to the challenges they drew before any of this existed. **Round 195 added No Pausing**, the nerve twist, in a `nerve` category of its own - it contradicts nothing, so it can land beside anything, which is where its teeth are. **Round 196 added Brick Swap** - three deterministic remaps (Hardened, Softened, Veiled) drawn from the day key on the twist's own seeded stream, with completability guaranteed by test. **Round 197 added Time Trial** - ninety seconds of ball-in-flight time, the countdown centre-top in the HUD, the whistle ending the run through the same path as running out of lives, and the clock riding in the save so a pause cannot refill it. **Round 198 added Mayhem Bricks** - the style chance tripled for the day, capped at the motif phase's own 85, stacking untouched; scoped to Endless Mayhem only because the original Endless has no style machinery to elevate, and the port that would need is queued as its own question in the daily spec's §13. The pool is fifteen live plus Vanilla; §4's table has four more written and unbuilt - Blackout, Mayhem Rules, Landslide, Always On (and Sudden Death parked) - Blackout wants a monochrome render path, Time Trial a clock in the HUD, and Always On the curated subset in §4.1. Weights still want tuning against a batch actually being played |
| ~~Ball Spin / Curve~~ | **Built, round 183**, to the note's own design. The paddle's speed is sampled once a frame in the paddle tick (`tickEndlessIIPaddleTravel`) rather than read at the contact, for the reason the note gives: by contact time the engine has resolved and the same frame's touch has often moved the paddle again. A bounce grips the ball at a rate signed by the paddle's direction - nothing below 60pt/s, growing to a quarter-turn per second at 1400 - and `applyEndlessIIBallSpin` turns the heading from `didSimulatePhysics`, decaying to a quarter of itself each second so the curve is sharpest off the paddle and straight by the time the ball reaches the field. **A rotation, not the perpendicular nudge the note suggested**: a nudge changes the ball's speed, and the speed is the one thing the whole angle discipline rests on - turning the heading curves the path and leaves the speed exactly alone. The conflict with the paddle group is handled where it actually bites rather than as a flag nothing reads: a *caught* ball is never gripped, and a ball caught mid-curve gives its curve up, so an aimed launch leaves at the angle the aim chose. Turn-based like the rest of the batch (five hits). **Still wanted**: the grippy paddle texture the note asks for, which is art (§8.5), and a drawn placeholder icon until James draws one. |
| ~~Double Paddle~~ - **built, round 151**, the sixtieth power-up and the last of the three James pulled into 1.3 at round 100. The **opposite-moving paddle** beside it is **built, round 168** as Mirror Paddle, the sixty-first power-up - and the row's price was right this time: it is somewhere else on the screen, so it is a real second node with a real second contact path. It stands level with the paddle and holds the mirrored x, so it covers the side the player has just left, which is where the ball they cannot reach is. Beneficial and the only one of this batch that is, though double-edged: two paddles near the centre are one paddle. **Its own collision category**, the Safety Paddle's lesson applied a second time - the paddle's would spend a turn and count a landing, and Aimed Sticky, Portal Paddle and Magnetism would all answer it, so a ball could be caught by a power-up on a paddle nobody is touching. It bounces through `PaddleBounce` at influence 1 rather than the backstop's arithmetic, because it is a paddle and not furniture; it takes the paddle's size when Expand or Shrink writes one; it wears the paddle's own dress, asked of `paddleRetroTexture` first, which is round 166's lesson; and it is never stranded. | Play-test ideas for the next power-up batch, refined in the second round: the paddle *splits in two*, each half the width of the original - a second paddle is per-ball contact handling all over again, priced accordingly |
| ~~Field build-in for Classic and original Endless~~ | **Built** (round 22). One entry point, `prepareBuildIn`, chooses by mode: the endless modes rain their rows in as Mayhem always did, and Classic pops its bricks up *in place*, row by row from the top, with the same knock a landing row gives. Both wait for the splash screen through the existing poll, both answer the existing skip, and Classic's destinations are recorded even though they never move - a brick with none falls back to the nearest *endless* row centre, which means nothing on a Classic field. Original note: two halves. (1) Original Endless adopts Mayhem's opening build-in as it stands - rows entering at the top and stepping down in lockstep (`tickEndlessIIBuildIn` and friends); the port is mostly making that code read its row set from the classic-endless generator rather than Mayhem's. (2) Classic gets its own, different animation: the level's bricks appear *in place*, quickly, with a haptic tick as they land - no descent, because classic fields do not descend. Both must respect the skip path (§12.0's second-round build-in bug: skipping mid-fall parked bricks off their rows - destinations cleared one line too early), and neither may leave a repeating action on a brick (§8.6) |
| ~~Global rank on the game-over screen~~ | **Built, round 160.** The game-over screen carries one more line under the run's numbers: "3rd / 1,204 on the Endless Mode board", in the same grammar and the same grey as the daily's "Posted, 3rd / 200 on today's board" - because it is now literally the same label and the same method. `loadDailyStanding` became `loadRank(leaderboardID:)`, `DailyStanding` became `LeaderboardStanding`, and `updateResultLine` answers for every mode. **Which board a run stands on is `GameMode.runLeaderboard(packNumber:)`**, a pure function with tests: each endless mode's own best-height board, and for a classic run *the pack's total-score board* - not the per-level boards in `levelLeaderboardsArray`, which exist in App Store Connect but have had nothing posted to them for years, so a rank asked of one would be a place won under forgotten rules. Nil, and so silent, in Single Level Mode and the Tutorial. **Mayhem needs no special case**: its board does not exist yet, the load comes back empty, and the line stays off - it will appear by itself the day James creates it. **Two things the doing turned up.** The pack board IDs were written out twice, in `gameCenterSave` counting from zero and in the level selector keyed by `packNumber`, two offsets apart; they live in `LevelPackSetup` now and a test holds the three arrays in line. And the line was *crushed* on the classic game-over - the fullest screen the app has - because the 22pt above it and the 20pt below were both required, asking 42pt of the 34pt the layout guarantees between the score block and the stats, and a label with default compression resistance is what gives. It is 8pt required and 20pt wanted either side now, with the label's resistance raised to required, so the margins bend and the words never do. Verified on the simulator in both modes. Original note: Play-test request, ninth round: show where the run stands on the global board, in-app. The daily already does it - `loadDailyRank` feeds the pause menu's summary and the briefing badge. The endless and classic game-overs need the same ask against their own boards: a `loadRank(leaderboardID:)` generalisation of the daily loader, called with the mode's board when the game-over screen goes up, appending to the score block when it answers. Board IDs live in `LevelPackSetup`/`GameCenterHandler`; Mayhem's own board is still on James's App Store Connect list (§8.5 side), so Mayhem shows nothing until it exists |
| ~~Paddle-speed try-out screen~~ | **Built (round 110)**, and James's round-109 question - "is it still in the backlog?" - is answered twice over: it was in this open list rather than backlogged, and it is now done. `PaddleSpeedViewController` (programmatic, like the daily's screens, so it cost one file rather than a storyboard scene) carries the slider and a live `PaddleSpeedScene` beneath it - one paddle, one ball, four walls, no bricks, and a ball that gets past is served again rather than lost, because a practice field that can be failed is a game and this is a ruler. The paddle is moved by `GameScene.touchesMoved`'s own line, the finger's travel times the factor, so the number being chosen is the number that ships. **The setting is now the factor itself**, not an index: `PaddleSpeed` owns the storage, reads a player's old 0-4 index once and converts it (so years on x1.25 open the screen on x1.25), keeps writing the nearest old step to the legacy key because a settings file is a save format like any other, and uses `object(forKey:)` rather than `integer(forKey:)` - the old index's first value was 0, so "absent" and "x1.00" were the same answer and a fresh install would have been handed the slowest paddle. The row shows the number and opens the screen instead of cycling, and its five hard-coded greys became a ramp derived from the value. **Round 121 rebuilt it on James's play-test.** Quarter steps rather than tenths - nine a thumb can land on, and every one of the five old settings lands exactly on a step. The slider moved *below* the field, where the thumb already is, because reaching over the thing being judged put a hand across the only part of the screen worth looking at. The field is now the **player's own play area**: shaped by `GameBackgroundView.modelledSize` (the background paints a letterboxed model of the whole screen, so a container of any other shape gets dead space either side and a ball that leaves the picture while still inside the field), wearing their chosen background, ball and paddle. The ball is a real physics body with the game's own restitution, friction and damping instead of hand-integration in `update`, which is what made it jittery. **And the drag was being eaten**: `MenuNavigation`'s back-swipe began on *any* horizontal pan anywhere on the screen, and `cancelsTouchesInView` then cancelled the touch underneath - the paddle moved once and went dead. `gestureRecognizerShouldBegin` now applies the same edge test the handler does, so a mid-screen drag can never start a page turn. Same shape as the round-97 settings-scroll bug, one axis further in. **Round 122** took the second play-test: quarter steps, the field at the play area's own width with everything inside it 1:1 - ball and paddle sized from `GameSceneLayout`, the ball at `ballSize*37.5` (the game's nominal speed), and the paddle the same clearance above the floor that it has above the kill line in play, which is also the room a thumb needs. **The stutter was compositing**: a transparent `SKView` over a Core Graphics background over a blur is three layers redrawn every frame. The background is baked once into an image and lives *inside* the scene, so the view is opaque. Two traps met on the way: `drawHierarchy(in:afterScreenUpdates:)` captures what the window server drew, and a view that has never been on screen captures black - `layer.render(in:)` is what works; and a required width fighting a required 24pt side margin left autolayout to break one of them, which is why the field first came out two thirds as wide as the game. Original note - play-test request, thirteenth round, and the largest of that round's items: tapping the paddle-speed setting opens a screen where the speed can be *felt* rather than guessed. A slider at the top from 1.0 to 3.0 in 0.1 steps, and beneath it a small square practice scene - the player's own background, paddle and ball themes, a paddle near the bottom, a ball already bouncing, no bricks. Losing the ball just relaunches it. The mock scene on the background-selection screen (`GameBackgroundView` plus its themed mock) is most of the furniture already; what is new is a live ball and paddle in it, driven by the same touch-to-paddle arithmetic the game uses so the number under test is the number that ships. Note the setting is currently an Int 1-3 (`paddleSensitivitySetting`); 0.1 steps means widening it, which touches the save format's defaults and every read of it |
| ~~Info detail pages, relaid out~~ | **Built** (round 27): the page now reads icon, name, description, facts, top to bottom, with the icon centred and at 100pt - the size the power-up art is drawn at, so it is shown rather than scaled. The name lost its fixed height, which it had only because it used to sit beside a 52pt icon; a two-line achievement name had nowhere to go before. The description centres while it is short and sets flush left once it runs past two lines, because a centred paragraph starts every line somewhere new: `descriptionIsCentred` is the rule, and it is measured rather than guessed at, so a longer description written later gets the right treatment without anyone remembering to change it |
| ~~Power-up ring style, unified and glowing~~ | **Built** (round 26). Both builders already drew the halo-and-ring pair, so the styles were already one thing; what was missing was the bloom the request kept asking for. `glowWidth` goes on the soft wide pass only - the thin bright ring on top stays crisp, because it is the one carrying the reading and a blurred timer is a timer you squint at. Original note: | Play-test request, thirteenth round: Classic and Endless draw the timer as a ring *around* the icon (the round-6 port), Endless Mayhem draws its own row differently, and the round prefers the ring. So Mayhem adopts the ring-around-the-icon treatment, and every mode's ring gains a subtle glow behind it. `PowerUpRingHUD` draws both today, so this is mostly deleting the divergence; `SKShapeNode.glowWidth` is the cheap glow and wants one visual iteration to find a width that reads as light rather than blur |
| ~~Falling power-ups glow~~ | **Built** (round 26). A halo child of the drop, so it falls with it and is removed with it. The colour is derived from the multiplier column, where the good/bad judgement already lives, rather than from a second list of which drops are good - a list would be wrong the first time a judgement changed, and this way a new power-up gets the right halo the day it exists. Original note: | Play-test request, thirteenth round: a subtle halo behind each falling power-up in the colour of its own icon. The drop is an `SKSpriteNode` with the icon's texture; the halo is a second node behind it, tinted from the same palette the icon uses, so the two cannot disagree about what colour the power-up is |
| ~~Stats on every game-over screen~~ | **Built** (round 15). `RunSummary` gained a score, a count of levels cleared and a flag for which kind of run it was, and the detail screen reads that flag rather than assuming - it was showing a classic run a height of 0m and a dash where bricks-per-metre belongs. Original note: Play-test request, thirteenth round: the run-stats door should not be endless-only. Classic and daily game-overs get it too - and on the daily it is a small stats button to the *right* of the big Home, beside the leaderboard button. Needs `RunStatsViewController` to say something sensible for a classic run (score, level, bricks, power-ups) where today it assumes height |
| ~~Safety paddle power-up~~ - **built, round 143**, the fifty-fourth power-up. A second paddle stands under the lowest brick row for twelve seconds: it keeps the ball up in the field, and while it is there the ball cannot reach the bricks from below - double-edged by design, like Gravity. **Round 167 took that second half away, on James's call:** "the ball shouldn't contact it when coming from below, it should pass through it". A bar the player was *given* that bounces a shot which would have reached the field reads as the ball being cheated rather than as a price. It is one-way now, done exactly as the real paddle steps out of a ball's way - the bit is cleared on *the ball's* body rather than on the bar's, so with four balls in play each gets its own answer about one surface, and it goes solid only once a ball is clear above it rather than when its centre passes, because a ball made solid mid-overlap is one the engine shoves aside. It has **its own collision category** rather than borrowing one, which the notes below had already worked out and building it confirmed: the paddle's spends a paddle turn and counts a landing, and Aimed Sticky, Portal Paddle and Magnetism all answer paddle contacts; a screen block's is read by *shape*, so a wide, short bar would have been taken for the ceiling and deactivated Giga-Ball on touch. It does not descend, it is removed by the tick that finds its clock stopped (never stranded), and it comes back with its clock on a resume. One trap found in the building: `SKPhysicsBody(rectangleOf:)` with a zero width hands back a node with **no body at all** - a safety paddle the ball falls straight through - so the size is floored. Original notes, kept because they are the reasoning: **Pulled into 1.3** (round 101, James's call), sharpened in round 125 by building the two beside it. It is the first of this batch to need **a physics body of its own**, which is why it was left for a round with a play-test in it rather than added blind: the body's category decides everything about how the ball meets it. `paddleCategory` is wrong - the contact would spend paddle turns and count as a landing, which the note below already forbids. `screenBlockCategory` is the closest fit, but `didBegin` branches on the *shape* of a screen block (`width < height` means a side wall), so a wide, short safety paddle would fall into the top-block branch and want checking against that. The rest follows the pattern rounds 124 and 125 used: a clock in `endlessIITimedClockPaths`, a collect case, the twelve arrays, and the node created on collect and removed when the clock ends - with the same must-not-strand rule Ghost Ball has, since a safety paddle left behind after its timer would change the field for the rest of the run. Original note - play-test idea, tenth round: a second, fixed paddle just below the lowest brick row. Good because it keeps the ball up in the field longer; bad because it stops the ball reaching the bricks from below - deliberately double-edged, like Gravity. Build notes: a static body at `finalBrickRowHeight - brickHeight` spanning some fraction of the width; it must ride the descent question carefully (the field moves, the paddle does not), and its contact must *not* spend paddle turns or count as a paddle landing - it is furniture, not the paddle |
| ~~Drift power-up~~ - **built, round 148**, the fifty-fifth power-up and the first of the three James pulled into 1.3 at round 100. | Play-test idea, tenth round: bricks and falling power-ups drift sideways while it runs. Field-batch shaped: a per-frame x nudge from `update` (never a repeating action on a brick, §8.6), wandering bricks' wall limits still respected, drops' `PowerUpDrop` action replaced by a drift-aware fall while the clock runs. Interacts with Wrap-Around (drifting off one side should wrap while it runs) and with the row discipline - bricks must land back on column centres when it ends, or the crush and generation logic drifts with them **Round 167: it shuddered instead of drifting, and now it goes round the sides.** James: "the bricks should slowly drift from left to right or right to left". Round 148 had it turn round at the wall, and what that produced was not a sway but a shudder - *any* brick reaching a wall turned the whole field round, and on a field that spans the width there is nearly always a brick near an edge. Measured in play: the direction flipping every one or two seconds and the field never travelling more than 22 points, about half a cell. Travel needs somewhere to go, so the doorway Wrap-Around opened is open whenever Drift runs: a brick that runs out of field comes back at the other side, shifted by the field's whole width, which is a whole number of columns - so it lands on a column centre and the cells the generator and the crush speak in stay the cells everything else means. Ten seconds now carries the field four and a half cells. **Known and worth a look:** a brick mid-crossing is drawn half outside the wall. Wrap-Around draws the paddle's overhang as a ghost on the far side and the same could be done here, which is the tidier answer if it reads badly. |
| ~~Stats table icons~~ | **Built** (round 30): every row on the statistics page carries an SF Symbol in a fixed gutter - fixed rather than each icon sitting against its own label, because the symbols are different widths and left to themselves they make a ragged edge down the page. The name is a property of the row in `StatsPage`, beside the label it belongs to, so it cannot drift from it. Every name is from the first two SF Symbols releases: the app runs on iOS 15 and a later symbol draws *nothing* rather than failing, which a modern simulator would never show. A test asks for all thirty-three images |
| ~~Glow around the power-up rings~~ | **Built** (round 26), with the ring style item above - the same `glowWidth` pass serves both, which is what they were always asking for twice. Original note: | Play-test request, tenth round: a subtle glow around the ring dials. `PowerUpRingHUD` draws them; SKShapeNode has `glowWidth`, which is the cheap version - worth one visual iteration on the simulator to find a width that reads as glow rather than blur |
| ~~Classic pack-completion score tally~~ | **Built.** Every game over and every pack completion now counts its number up, not only Single Level Mode and the endless height. The hold-back was that a level inside a pack carries its score into the next one, so counting it would be counting a total still running - but this screen is only reached when there is no next one, which is what made the old condition wrong rather than cautious |
| ~~Classic mode menu redesign~~ | **Built** (round 29): the screen is headed "Classic Mode" with the mode's own logo under it, the way the two endless screens are - it used to be headed "Level Packs", which says what is on the screen rather than which mode you are in. The eleven packs are square cells three across, so all of them are visible at once instead of a list you scroll. A cell opens the pack's level list; the play badge in its corner still starts the pack straight away. *(Round 33 swapped those: the cell plays, the corner button lists. Round 36 moved the list mark to the top-left with the completion tick mirroring it top-right, sized the logo up with more air below - shrinking on scroll to give the room back - and removed the bottom play button for the second time in the screen's history.)* The pack icons moved into `LevelPackSetup` beside the pack names, because the same eleven file names were written out as a switch on this screen *and* on the mode menu |
| Grid background scaled to the marker grid | Needs the actual artwork's pitch measured against brickHeight - a visual-iteration task, not a blind one |
| ~~`PowerUpCatalogue` has drifted from the shipped game~~ | **Resolved**, James's call: the two it was missing went in (**Cull** and **Auto-Aim**, both built, both Mayhem's), and **Randomised Bounce** stays because it is to be built - see the row below. The file is a design document that may run *ahead* of the game and may never fall *behind* it, and `testTheCatalogueMayRunAheadOfTheGameButNeverBehindIt` is that rule: an entry leaves the ahead-list by being built, and the behind-list must always be empty. Auto-Aim went in without the conflict it looks like it should have with Aimed Sticky - Aimed Sticky owns the launch from a held ball, Auto-Aim redirects an ordinary bounce, and the scene runs both; declaring a conflict this file cannot enforce is how it drifted in the first place |
| ~~Build Randomised Bounce, the fifty-second power-up~~ | **Built (round 124)**, and the catalogue's ahead-list is empty for the first time - `testTheCatalogueMayRunAheadOfTheGameButNeverBehindIt` now asserts emptiness rather than this one name. Fifteen seconds, uncommon, harmful, extending its own duration; while it runs every corrected bounce leaves at its angle thrown off by up to 35 degrees either way. **It is applied in `ballHorizontalControl`**, the one door every corrected bounce already passes through - paddle, wall, brick, backstop, seam - whose `angleDegInput` is taken from the *approach* rather than the engine's reported velocity, so §8.6's double-bounce trap is avoided by construction rather than by care. It is clamped back inside the launchable arc: a bad power-up may be unfair, but not to the point of handing the player a ball that never comes down, which is the one heading the game refuses everywhere else. It joins `endlessIITimedClockPaths`, so a Lock freezes it and a Wipe clears it without either being edited, and it is applied *before* the loop-breaker so a ball thrown into a repeat is still broken out of it. The array checklist took the whole dozen (icon, name, both unlock lists, description, multiplier, timer, display and pack order, the two stats counters, the unlock array, the probability array and the texture array) and the suite failed loudly in three places until they were all fed - which is exactly what it is for. Original note: the last catalogue entry with no game behind it, and now the only one. §5.4 has it as uncommon, harmful, timed, extending its own duration: while it runs, the angle the ball leaves a surface at is randomised rather than reflected. Build notes: the approach direction must be sampled in `update` before physics, not read off the contact, or it bounces twice (§8.6) - `ballStateBeforeStep` is that sample, and it is the same trap Portal already has to avoid. It is a clock, so it joins `endlessIITimedClockPaths`, which is what makes a Lock freeze it and a Wipe clear it without either being edited. Follow Wipe's round for the array checklist: about a dozen parallel lists, the two counters in the stats file, the probability array and the texture array |
| ~~Sticky Paddle: the ball bounces before it sticks~~ | **Fixed** (round 35), James's call on scope: the intent of the original modes is preserved, not every bug. `catchStickyBallBeforeStep` runs from `update` after `recordBallStatesBeforeStep`: if a catch is armed, the ball is descending, and this step would carry its underside through the paddle top, it is caught *there* - moved to where it was landing, stopped, stuck - and no bounce ever happens. The landing x is interpolated from the pre-step state, judged against the same band `paddleHit` uses, wrap-ghost included; Aimed Sticky is left to its own contact path, as are Multi-Ball's extra balls (their queue has its own ordering). The lookahead is a fixed sixtieth, not `endlessIIPaddleFrameDelta` - that delta is set under a Mayhem-only guard and is zero in Classic, which would have made the fix a no-op in the mode that reported it. An early catch is invisible because the catch pins the ball to `ballStartingPositionY` regardless. Original note: | Play-test round 33, **diagnosed round 34.** The catch is made in `paddleHit`, which is called from `didBegin(_:)`. The ball and the paddle *collide* as well as report contact, so by the time that contact arrives SpriteKit has already resolved the bounce and moved the ball - the catch then zeroes the velocity and snaps `position.y` back to `ballStartingPositionY`, and the snap is what is being seen. It is §8.6's first trap in a new place: a contact reports the state *after* the engine has acted. **The fix is to catch in `update`, before physics**, from `ballStateBeforeStep` - if a sticky catch is armed, the ball is descending, and its pre-step position is above the paddle top while this step would carry it below, catch it there and let no bounce happen at all. **Do not** solve it by taking the paddle out of the ball's `collisionBitMask` while sticky is armed: the sticky band is narrower than the paddle, so a ball landing outside the band must still bounce, and a ball passing through the paddle is far worse than a ball that flickers. Sticky Paddle is one of the original twenty-eight, so this changes Classic and the original Endless too - it needs a few levels of play-testing in both before it ships, per the Scope note in CLAUDE.md |
| ~~Auto-Aim with Sticky Paddle, as one control~~ - **built, round 155**, exactly as the design reads. While Aimed Sticky holds a ball, a drag *above* the paddle is the aim and a drag on or below it carries the paddle - and the held ball with it - so a player who caught a ball at the wrong end of the field can now walk it across before shooting. Releasing no longer fires: only a tap does, judged on distance *travelled* rather than distance from where the touch began, because a finger that goes out and comes back has still moved and firing on that is how a shot goes off mid-adjustment. The rule is a pure type (`AimHoldControl`) rather than three conditions inside `touchesMoved`, because "which half of the screen was that?" is a rule, and a rule buried in a hundred lines of paddle arithmetic can only be checked by playing and feeling for it. The freeze is unchanged: it was always the field that stopped, not the player. | Play-test round 33, James's design: with both running the player can aim *and* reposition. Letting go of the screen leaves the ball on the paddle; the ball only launches on a **tap**. A swipe **on or below the paddle** moves the paddle; a swipe **above the paddle** moves the aim arrow. Today the two run side by side with no shared gesture model, so this is a touch-handling job in `GameScene`'s pan handling plus the aim marker `refreshEndlessIIAutoAimMarker` already draws. Note the catalogue deliberately records no conflict between them - this is why |
| ~~Shaped bricks face up or down~~ - **built, round 154**, on James's instruction to flip the asymmetrical shapes both ways. A 50/50 roll per brick exactly as the note asked, applied as a reflection of the *node* so one texture serves all four orientations; the row centre is untouched because only the sprite's hiding rectangle moves, which is the trick the Wedge already used. It matters more than the note guessed: the field descends to meet the ball, so nearly every hit lands on an underside, and until now every underside was flat. | Play-test round 33: the new brick shapes (Convex, Concave, and the others whose silhouette has a top and a bottom) should exist both ways up. In Endless Mayhem the choice is a 50/50 roll per brick. Generation-side: the style already varies per brick, so this is an orientation flag beside it, drawn mirrored - and it must not disturb the row centre a brick's `position.y` carries (§8.6) |
| ~~App icon and theme pickers as grids~~ | **Both done, and this row was the duplicate round 159 suspected it was.** Looked at on the simulator in round 160: Settings > App Icon is a grid of three columns of tiles, the chosen one ticked and the locked ones greyed under their unlock sentence - which is exactly what "the grid layout - done, all five, rounds 77-79" says it built. The theme picker was confirmed the same way in round 159. Nothing was left to build here; what was left was to look. Original note:  Play-test round 33: the app icon picker and the ball & paddle theme picker are list views; they should be grids with the images bigger and more prominent - the artwork is the whole point of both screens and a 40pt thumbnail in a row wastes it. `ItemsDetailViewController` serves both (senderIDs 0 and 1). `PackGridCell` and the pack screen's flow-layout sizing are the pattern to follow, **including the floor** on the cell width |
| ~~The Glow background, reworked~~ | **Done - confirmed by looking, round 160.** The preview shows what round 33 asked for: dark purple throughout, with the Giga-Ball yellow-green reading as a soft cloudy haze over it rather than a clean gradient band, and nothing bright enough to compete with the bricks. It sits high in the field, just under the brick rows, so round 145's anchor fix holds too - this is the background that was "below half way down the game view". Struck on a screenshot rather than on the inference round 159 declined to strike it on. Original note:  Play-test round 33: the version built in round 19 is not liked. What is wanted instead: a gradient from the Giga-Ball yellow-green into the dark purple, the whole thing staying dark so it never competes with the game's own graphics, and the yellow-green reading as *cloudy and blurry* over the purple rather than as a clean gradient band. `GameBackground.glowImage` is the one to replace; it already seeds its own randomness so the picture never reshuffles between launches, which must stay true |
| ~~Thousands separators outside the game scene~~ | **Built (round 108)**: sixteen sites, all through the one door `StatsPage.grouped`, so the separator stays the reader's own - the level high score and the pack screen's list, the endless run lists, the game-over and pause score and best lines *and the height tally's animating frames*, the resume card on the splash, the run-stats summary, and the daily's `scoreText` (which the briefing and the results copy both read). Nothing in `GameScene` was touched, which is the rule rather than an oversight. The daily's helper is pure, so it carries the test; the label assignments are mechanical substitutions of the same string. Play-test round 33: James wants grouped numbers everywhere except in the game itself. The statistics page has them (`StatsPage.grouped`); still to do are the pack and level high scores, the endless run lists, the game-over and pack-complete summaries, and the daily's score lines. **Nothing drawn by `GameScene` may group** - the score changes several times a second and a separator appearing as it crosses a thousand is movement where the eye is already watching |
| iPad resize audit - **screen-by-screen pass, round 186** | Play-test round 35: iPadOS 26 resizes every app and ignores `UIRequiresFullScreen`, so multitasking arrived without being adopted. A window-scene minimum of 420x640 is set in `SceneDelegate` so the window can never go below a phone's width - but there is no API to cap the maximum or the ratio, so the audit is real work: every menu screen at split view, slide-over, and the tall-and-thin and short-and-wide extremes, checking `limitMenuContentSize` and the storyboards' constraints hold. The play zone is safe by construction (fixed 1.8236, `GameSceneLayout` asserts it); the menus are the exposure. **Round 180 started it headlessly** (a 13-inch iPad Pro simulator, full screen, portrait): the splash and the main menu both hold - title, credits, mode pills and the two round buttons all placed and readable. **The "finding" from that pass was mine, not the app's**, and is recorded here so nobody chases it: the mode pills looked opaque rather than glass because that simulator was on **iOS 18.0**, where `addGlass` correctly returns nil and the flat card is the designed fallback. Checking the runtime before reading a material is the lesson. **Round 186 did the pass properly**, on a 13-inch iPad Pro running iOS 27 with round 182's aspect cap in: the splash, the main menu, the mode carousel, Settings, Information and the reference grids were all looked at beside the same build on an iPhone 17 Pro. Everything holds and the glass is glass. One real finding, fixed in the same round - the reference grids were three across whatever the width, which on an iPad meant the phone's layout enlarged rather than an iPad's layout; see the row above. **Round 188 played a run on the iPad and looked at the rest**: the game view holds its 1.8236 zone centred with the HUD tracking the zone rather than the screen, the pack grid and achievements read well, `GigaBallAlert` caps itself sensibly, and the pause-presented Information screen lays out at the full capped width. The pause and game-over screens do not - see the row above, which is measured but not yet diagnosed. Still to look at: the stats and achievements pages with real run data, and the daily briefing.

**Round 181 did the pass properly** - a 13-inch iPad Pro on iOS 27, portrait, full screen, with working input: splash, main menu, Settings, the Endless Mayhem menu, the Classic pack grid and **a live Mayhem run** were all walked. Glass renders correctly throughout. The play zone letterboxes to its column exactly as `GameSceneLayout` promises and the game plays. Nothing is clipped, overlapped or unreachable, and each screen's close button sits at the content column's edge rather than the screen's - emergent from `layoutMenuButtonRow`'s `max(0, target - fromScreen)`, and the better answer on a 13-inch screen, where 24pt from the glass is a long reach from anything you are reading.

**The resize behaviour is now tested rather than eyeballed** (`MenuResizeTests`): `limitMenuContentSize`'s arithmetic is `UIViewController.menuContentInsets(available:inherited:)`, and the tests pin the sizes nobody can check by hand - full-screen iPad, the 420x640 floor `SceneDelegate` sets, slide-over's tall-thin, a landscape half-split's short-wide, the nesting rule that stopped three-deep menus halving their content, and two sweeps over several hundred sizes asserting no inset is ever negative and the column is always `min(width, 500)`.

**Round 182 answered the finding below** (James: "for the iPad, it's not the overall size that should be capped, it's the ratio of width to height. It's ok to make the app slightly more square than the phone is, but not much more square"). `menuMaximumSize` is gone; `menuMaximumAspectRatio` is 0.62 - just past the squarest phone, well short of a 13-inch iPad's own 0.75 - and only **width** is ever trimmed, because a window *taller* than a phone's shape is a narrow phone, which is what the menus were built for. The empty 40% is gone with it, and a tall-thin slide-over is left entirely alone where the size cap used to take 278pt off its height. Worth James's eye now it uses the room: rows on a 13-inch iPad are considerably wider than they were.

**The original finding, kept for the record.** The cap was 500x820 centred, so on a 13-inch iPad **40% of the screen height was empty** - 278pt above the content and 278 below - while the pack grid *scrolls*, hiding two of the eleven packs behind an edge fade with all that room going spare. The width cap is clearly right (the rows are what the cap was written for, and a full-width row on an iPad is a lot of nothing between an icon and its label). The **height** cap is the question: `limitMenuContentSize`'s own phone branch says capping height "only pushes a row below the fold", which is exactly what it is doing to the iPad's grids. Suggested, for James: keep the 500 width, let the height use what it is given (or cap it far higher), which would show every pack without scrolling and put the close button back near the bottom of the screen. One number, one line, and a re-run of the tests above - but it changes how every menu sits on iPad, so it wants his eye first. |
| ~~Run summaries said every run was endless~~ | **Fixed** (round 36), found under "remove bricks per metre in classic": `RunSummary`'s classic fields - `score`, `levelsCleared`, `isEndless` - were added in round 13 and **never passed at the one construction site**, so their defaults held and every run claimed to be endless. Three symptoms from one cause: a classic run's detail page led with "Height 0m", carried "Bricks per metre", and the pause summary never showed its levels-cleared line. The fields are passed now. The lesson is §12.0-worthy on its own: a struct field with a default is a field the compiler never makes anyone set |
| ~~Aimed Sticky arrow reach~~ | **Lengthened** (round 36), third time of asking: the arrow now runs from the held ball to almost the lowest brick row (`finalBrickRowHeight`, less a ball's grace), with the old round-10 length kept as the floor for a catch high up the field. Each previous lengthening was a fixed multiple of ballSize; going to the thing itself ends the series |
| ~~Return-to-game button dropping taps~~ | **Fixed** (round 36), most probable cause: the button is installed in `viewDidLoad` and starts frontmost, but the settings and info screens keep adding views after that, and a transparent view laid over it eats taps without covering it visually - "doesn't always work" is exactly what that failure looks like. `keepReturnToGameButtonFrontmost` re-fronts it from `limitMenuContentSize`, which every menu screen already runs on every layout pass. If the play test still catches a dead tap after this, the diagnosis is wrong and the next suspect is the gesture recognisers |
| ~~Resume put bricks off their rows~~ | **Fixed** (round 37): the save derived each brick's row from its on-screen `position.y`, which is only its row *once it has arrived*. Quit during the opening build-in and the bricks are still in flight, so whatever height each had reached was saved as its row - a resumed run came back with bricks below the bottom row (screenshotted at the very start of a Mayhem run). The save now reads `endlessIIBuildInFinalY`, the destination the animation is carrying each brick to, falling back to the brick's own position once the build-in has finished and emptied it. §8.6's "a brick's `position.y` is its row" trap, reaching the save format |
| ~~Wrecking Ball had no haptic~~ | **Fixed** (round 37): its branch in `hitBrick` returns before the type switch, so it reached no haptic at all. It gets the *heavy* one now rather than the light tap every other brick gets - of every hit in the game it is the one that should land hardest |
| ~~Power-up HUD on the pause screen~~ | **Built** (round 42): `PausedPowerUpHUD`, a UIKit row on the pause screen, with each icon opening a `GigaBallAlert` carrying that power-up's name and description. It **looks** identical without **being** the same code: every number is read from `PowerUpRingHUD` rather than copied - the colour, the glow radius, the stroke widths, the icon size and spacing - and the arc is literally the same `ringPath` function, mirrored into UIKit's coordinates so a second set of trigonometry cannot drift from the first. The reading comes from `InGameRecents.activePowerUpRings`, captured at the same moment the pause snapshot already takes. It does not animate, by James's scoping, which is what made a static row the right answer rather than snapshotting a live scene |
| ~~Average hits per ball, and the best single ball~~ | **Built** (round 38). The average is arithmetic on two totals and needs no storage; the **best** cannot be recovered from totals, so `TotalStats.bestBallHits` is new - optional, for the same decode-safety reason the Endless 2.0 and daily fields are, and with `longestBallRun` handling absent-means-none. `hitsOnThisBall` counts, `ballLost` closes the tally, and `runBestBallHits` carries the run's own best to the end-of-game stats including the ball still in play when it ended. The iCloud copy went in **with the field rather than after it** (CLAUDE.md's standing warning), and merges highest-wins in both directions, unlike the running totals beside it which only ever climb |
| ~~Trajectory Line: two bounces, not one~~ - **already built** (round 42), found stale in round 148: `endlessIITrajectoryBrickBounces` is 2 and the line fades with distance. What is *not* modelled is the random escape kick a flat ball gets (`breakHorizontalRuns`), and that one cannot be predicted - it is random by design, which is what the fade is for | Play-test round 38, James's answer to the round-37 question: one or two brick bounces is acceptable, beyond that is not. `BallPath` stops at the first brick today and its header explains why - the scene's corrections are applied *at* a bounce, so error compounds. Two is the agreed budget. Build notes: the predictor must replicate the angle nudges away from horizontal and vertical, and the seam resolution, or the second leg is confidently wrong; and the line should fade with each bounce so it shows its own declining confidence |
| ~~Power-up HUD on the pause screen~~ - **duplicate**. Built in round 42 and struck in the row above; `PausedPowerUpHUD` exists and `PauseMenuViewController` builds one. Found by the round 159 sweep, three copies of one row deep. | Play-test round 37, scoped in round 38: **it may be built differently from the in-game HUD so long as it looks the same, and it does not need to animate.** That removes the hard part - a static UIKit row of icons with their ring fractions drawn once, rather than snapshotting SpriteKit or driving a live scene behind a menu. Tapping an icon opens a `GigaBallAlert` with that power-up's name and `powerUpDescriptionArray` entry |
| ~~Trajectory Line past the first brick~~ - **already built** (round 42), same finding | Play-test round 37 asked why it stops. Answered in `BallPath`'s own header: the predictor is arithmetic, and the scene applies corrections *at* each bounce (angles nudged off horizontal and vertical, a two-brick seam resolved as one face), so error compounds per bounce. A line drawn through a busy field would confidently show a path the ball will not take, and "a line that says you will hit that brick and does not is a lie the game told". If it is wanted anyway, the predictor must replicate those corrections exactly, and the honest presentation fades the line with each bounce |
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
| ~~Aimed Sticky arrow, fuzzy like the trajectory~~ | **Built (round 107)**, to round 39's ask: the same treatment, so the two aiming aids speak one visual language. The arrow's parent node is now pathless and the shaft hangs off it as segments on the trajectory's exact curve - stroke swelling 2pt to 4pt, glow growing on a square, alpha falling with certainty. One deliberate difference: the alpha keeps a 0.3 floor and the head keeps 0.55 with its own glow, because the arrow is the control the player is actively steering - a blurred tip is honest, a vanished one is an aiming aid that stopped aiming. Length rule, colour, z-order and the per-frame position-and-rotate are all unchanged. Visual tuning, judged at the next play-test alongside the trajectory's round-106 fade |
| ~~Power-up HUD on the pause screen~~ - **duplicate**, the third copy of a row built in round 42. | Play-test rounds 37-39. **It must look identical to the in-game HUD**, though it need not share its code and need not animate. So: a static UIKit row matching `PowerUpRingHUD`'s geometry and colours exactly. Tapping an icon opens a `GigaBallAlert` with that power-up's name and description |
| ~~Play button still wrong between pause views, and on the backgrounds view~~ | **Fixed** (round 45), and my round-39 hypothesis was wrong - re-fronting could not resurrect a removed button, so that was never it. The real cause: **eight screens each install their own**, and a screen opened from a screen is a *subview* of it, so three deep left three buttons alive at once in the same place, each running its own screen's entry and exit animations. Round 38 fixed the *other* button row - the small round icons - which is why this survived it. The backgrounds view is the same fact from the other side: it called `hideReturnToGameButton`, which removed the button from *its own* view, and the one still visible belonged to the settings screen underneath. The rule is now enforced on every layout pass, self-correcting: a screen with something open on top of it has no button, a frontmost screen installs one if it is missing, and a screen that has asked not to have one (`wantsReturnToGameButton`) never gets it back |
| ~~Info button on a swipe-up settings cell still toggles~~ | **Fixed** (round 49), second report. Round 21 added a time-based guard - a row toggle arriving within 0.4s of the info button's own press is the same press and is ignored - and it worked only when the button's `touchUpInside` was delivered *before* the row's selection. That ordering is not guaranteed, and when the row won the race the stamp was stale, the guard passed, and the setting flipped before the pop-up appeared. The press is stamped on **touch-down** now, which always precedes both, so the guard holds whichever order the ups arrive in. Stamped on the up as well, so a slow press still shields the toggle behind it |
| ~~Settings will not scroll~~ - **measured, round 92** | The scroll view was never broken. Set programmatically to 60 it clamped to 37 - its legitimate maximum - and *stayed there*, so it moves and holds; a hit test in the middle of the table returns the table itself, so nothing overlays it; its pan and `isScrollEnabled` are both on. What was wrong is that there is very little to scroll and the **edge fade was drawing across a last row that was already fully visible**: `remaining` did not count the bottom content inset, and after round 74 a list resting at the top sits at an offset of minus the *top* inset, so the fade thought a padding's worth of content was still below. A row that looks cut off when it is not is exactly what makes a short list read as one that will not scroll at all. Original notes follow, because the ruling-out is still worth keeping.   Six rounds on this, so here is the state rather than another theory. **Ruled out with evidence:** the scroll affordance (content 624 in bounds 611 with 32/24 of inset, so 69 points of travel and `isScrollEnabled` true, measured from the running app); the back swipe (logged - it is asked whether to begin on a vertical drag and answers no); `delaysContentTouches` (set true from `giveMenuListsBreathingRoom` since round 89, and the storyboard flags on the Settings and Information tables are **identical** anyway, which is the finding that matters - the two scenes differ in their *content*, not their table). **Not yet done, and the next thing to do:** hit-test the middle of the Settings table with `view.hitTest(_:with:)` and log the class that comes back. If it is not the table or one of its cells, whatever is on top is the answer. Three attempts at this failed for reasons that were mine - a build that had not recompiled, and taps landing on empty space because the app resumed into a paused game - not because the diagnostic is wrong |
| ~~Two pop-up types, and only one of them is `GigaBallAlert`~~ | **Merged, round 162.** `WarningViewController` is gone - the class, its storyboard scene and its four `project.pbxproj` entries - and the four confirms are `GigaBallConfirm`, an enum of *what is asked* rather than a second screen: title, message, mark, and what each button does. They present through `GigaBallAlert` like every other pop-up, so they arrived at three rounds of improvements at once - the glass card, the coloured glass on the confirm, and the icon above the title that round 85 asked for and that this sheet had no slot for. **The wiring is untouched**: each answer posts the notification it always posted, to the same observer, and the quit-while-paused still goes through the pause menu's own `moveToMainMenu` so it lands on the played pack's levels. `showWarning(senderID: String)` is gone from the delegate protocol too - `showConfirm(_:)` takes the case, so the four are a closed set the compiler knows about. **Two things worth writing down.** The merge dropped the sheet's parallax, and **round 163 put it back for every pop-up** rather than for the four: `GigaBallAlert`'s card drifts with the tilt when the player has that on, from `UIView.applyMenuParallax` - one recipe now, where sixteen screens each carry their own copy of the same eight lines and are a sweep for another round. The card drifts, not the blurred backing, which is what makes it read as lifted rather than as the screen wobbling; it is applied from `viewDidLayoutSubviews` because the travel is measured from the *window* (a card is narrower than the screen, and asking the card would put an iPad on the phone's 25 points). Settings still stands its own parallax down before asking, which is what stopped two layers drifting against each other - **and the pause menu does not**, so a confirm raised over a paused game now has two drifting layers. Worth a look on a real device: none of this can be seen on the simulator, which has no accelerometer, so the drift itself is unverified by anything but the two tests on its arithmetic. And **RESET DATA cannot be reached** - `settingRows` only adds the reset row from the pause menu, where it is Reset Ball, and the comment there says the main menu's Reset Game Data "was never implemented". The case is built, worded and tested, and will work the day a row opens it. MAIN MENU and RESET BALL were looked at on the simulator, both buttons each. Original note: Found in round 89 and worth knowing before touching either: the confirm pop-ups that matter most - **MAIN MENU, RESET BALL, RESET DATA, SWIPE UP** - are `WarningViewController`, a storyboard screen with its own title, text and three buttons. `GigaBallAlert` is the newer type used by the twists, the closed challenge, free play, the swipe explainer and a power-up's description. So round 82's icons above titles, round 89's coloured glass on the confirm button, and round 85's "main menu pop-up needs a home icon" all land on *different* screens than they look like they do. The home icon James asked for belongs to `WarningViewController`, which has no icon slot at all yet. Worth making them one type before either grows again |
| ~~A loop-breaker to replace the random kick~~ - **built, round 101**, and still queued here until round 155 noticed: both layers exist and are wired. The portal drift turns each paddle-less transit's exit by four degrees up to twenty-four (`endlessIIPortalDriftDegrees`, reset by a paddle contact); `BallLoopDetector` records a quantised (position, heading) signature at every corrected bounce and, on the third repeat, bends the angle by five to eight degrees once, alternating sides. It sits in `ballHorizontalControl` - the one door every corrected bounce passes through - after Randomised Bounce, so a ball thrown into a repeat is still broken out of it, and a paddle contact clears the history because the player can change what is repeating. Fifth queue row found already built; the lesson each time is that a row is only closed when someone strikes it. | Round 100. James confirms the removed random kick was load-bearing: it broke loops, and the Portal bricks make loops badly - a well-aligned portal pair can cycle the ball for ever even with the deactivation period. The replacement must be targeted where the kick was scattershot. Two layers: **(1) portal drift** - each transit through the same pair applies a small cumulative exit-angle drift, so geometry that maps onto itself cannot keep doing so, deterministic and felt only inside the loop; **(2) a loop detector** - at each bounce record a quantised (position, heading) signature in a small ring buffer, and when the same signature recurs about three times in a short window, apply the existing shallow-angle escape jitter once. Nothing touches the bounces that were never looping, which is what the old kick got wrong |
| Splash screen: the ball and paddle form the app icon | Round 100, James's idea, art his fallback if code cannot do it justice: a small ball-and-paddle graphic above the GIGA-BALL logo on the launch splash, animating in with the glow and settling into the app icon's composition. The icon is a paddle and a lofted ball, drawable as two rounded shapes and a circle, so a code attempt is worth one session before falling back to artwork |
| Prominent buttons in the Phone app's solid-glass look | Round 100, from a screenshot of the iOS 26 Phone keypad: fully saturated colour with glass lighting rather than translucent tint. Same API as the lime confirm and play buttons already use; the difference is an opaque colour base under clear glass so the material contributes lighting only. A tuning pass on `prominentTint` and `addColouredGlass`, worth doing beside the existing buttons for comparison |
| ~~Laser Beam appears to do nothing~~ **feedback rebuilt, round 102** | The first question was answered by reading: it is in the pool (weight 3, rare), the collect case fires, and the fire destroys each ball's column exactly as the description promises. What failed was the *read*: it fired the instant the paddle caught the icon, at the ball's column where the player's eyes are not, silently, for a third of a second - a rare power-up whose one showing is that easy to miss reports as doing nothing. Now it is the two-pass construction at field size (wide additive bloom under a bright white core), twice the linger, with the laser's own sound. James then clarified (round 103) that the beam **was working more recently** - the "does nothing" sighting was a single occasion some builds back, possibly a mistake, and has not recurred - so the drop-rarity suspicion stands down unless it comes back, and the rebuilt feedback ships as a straightforward improvement rather than a fix |
| ~~Game-over screen: stats sit too close to the scores~~ | **Built (round 112)**: the whole lower group now hangs *upward* from the button row - buttons, the Game Center note, More Stats, the stats list - with the old 34pt clearance under the score kept as a minimum and the bottom pin at high rather than required priority, so a short screen resolves it by letting the block sit higher instead of breaking a constraint. **Two things the doing taught.** The first attempt anchored the stats block to `signedOutLabel`, which reads better and **crashed the game-over screen**: `setUpRunStatsLabel` runs from `viewDidLoad` before that label is added to the hierarchy, and activating a constraint between two views with no common ancestor throws. Anchor to the storyboard's own `buttonCollectionView`, which is always there. The second: moving the stats down pushed the Game Center note *onto* the buttons, because it was still hanging off the summary above it - which is why the whole group is pinned from the bottom now rather than half from each end. Both were invisible to the test suite and to the build, and visible in one screenshot. Play-test round 97, endless modes: move the stats block down to sit just above the big bottom button, separating it from the score block above |
| ~~Landing Marker misses by a little, worse at shallow angles~~ | **Built (round 105)**, and the round-97 report was the diagnosis: "as if it's expecting the ball to travel a little further before it contacts the paddle". `endlessIIVisionBounds()` handed the predictor `paddle.position.y` - the centre line - where contact is the ball's bottom against the paddle's *top*, as `catchStickyBallBeforeStep` already judged it. The predictor adds the ball's radius itself, so the one missing term was `paddleHeight/2`: the prediction ran half a paddle deeper than the real surface, and at a 2:1 shallow approach that half-paddle of depth cost a full paddle-height of sideways error. One line in the bounds fixes the Landing Marker *and* the Trajectory Line's final segment together, because both read the same `path.landing` - the line's off-paddle bounce continuation now also starts from the true contact point. Tested in the reporter's terms: the bounds must name the same surface the sticky catch judges against, and a shallow approach must land where the ball actually arrives |
| Game Center boards, round 95 status | James: **Endless Mode 2 best height is live**, and both new *sets* are live - Endless Mode 2 Leaderboards and Daily Challenge Leaderboards. The other three boards are still in review, so anything that reads them has to keep tolerating an empty answer until they clear |
| The pause menu's outer buttons sit too close to the edge - **James's call taken, round 157: "everything out to 55pt". Half done.** The shared `layoutMenuButtonRow` had two arrangements (round 135) and the second one - "a row of only small buttons goes to the row's own ends" - turned out to mean whatever each screen's container happened to be: 51pt, 53pt or 55pt. That branch is gone, so every row through the helper now lands on 55. **Done in round 158** by moving the storyboard constraints, which is what those two needed - the code had been assigning `frame.size.width`, which autolayout overwrote, and both functions now read their row's width off the same constant the constraint uses so the two cannot drift. The main menu's row is 55pt each side, verified on the simulator (55.2pt left, 54.8pt right, where it measured 51.7 before). The pause row's leading is 42.5pt, which puts its 50pt icon on 55 once its cell's 12.5pt of padding is added; verified too (55.7pt left, 54.4pt right, where it was 63). All three arrangements now agree to within a point, which is the whole of what the row asked for. Original note: the main menu and the in-game pause row**, which build their own layouts. Both size their collection view by assigning `frame.size.width`, which autolayout overwrites on the next pass - widening them in code was tried and measured and moves nothing - so those two need the storyboard's width constraint changed instead. The pause row also needs per-cell sizing: its three cells are 75pt boxes holding 50pt icons, which is the 12.5pt that makes it 63. | Measured on the simulator at 402pt wide, outer icon left edge to screen edge: **main menu and mode menus 51pt, level list 53pt, daily 55pt, in-game pause 63pt**. The pause row is the one sitting *furthest* in, not nearest - its `collectionViewLayout()` sets `itemSize` 75 for all three cells, so each 50pt outer icon is centred in a 75pt box and gains 12.5pt of padding, while the menus leave the flow layout's default 50pt and their icons sit flush at the row's edge. So the three-value inconsistency is real (51 / 55 / 63) and worth removing, but which way the pause row should move is James's call, and the row was left alone rather than churned mid-play-test on a reading the measurement contradicts. **To do it:** each row needs `UICollectionViewDelegateFlowLayout` conformance and a `sizeForItemAt` returning the true icon size (without the conformance the method is silently ignored - the same trap the grids hit), plus a 5pt section inset to land every outer icon 55pt from the edge, the daily's value. Original report - play-test round 95: on the in-game pause screens, where the middle button is the big 75pt play, the close sits nearer the screen edge than it does elsewhere. The spacing is computed in each screen's `collectionViewLayout()` from the row's width less three cells - which spreads the outer two as far apart as the row allows. The daily challenge screen already solved this by pinning its outer buttons 55 points in from the edge; the collection-view rows want the same treatment |
| ~~Descent should not hold the field back over a gap~~ **built, round 99** | Play-test round 94: with Descent running, clearing the bottom bricks leaves a gap and the field still steps one row at a time, because Descent owns the cadence while it runs (`endlessIIDescentSuspendsCadence`, §5.4, added so the two would not double-step). What is wanted is the ordinary rule underneath it: **while the bottom row is empty the normal descent applies**, closing the gap as it always would, and Descent resumes its own step once there is a brick on the bottom row again. So the suspension needs to be conditional on the field having something in its bottom row rather than absolute - `countBricks` already computes exactly that, which is what makes this small |
| Classic packs: two scores drawn over each other | Play-test round 122, with a screenshot: the HUD score renders as though two numbers are on top of one another. **Not reproduced yet** - a fresh level, a second game in the same session and a level restart all draw it cleanly, so it needs a state a short session does not reach (a long pack run, a resume, or a milestone pulse mid-write). What round 122 *did* find by reading is the one path that could produce it: `Level999` set `scoreLabel.text` directly, which leaves the label drawing its own string **as well as** any `FixedWidthNumberNode` strip already hung off it - that now goes through `showHeightLabel()` like every other write. A DEBUG tripwire sits in `write(_:into:)` and prints `HUD DOUBLE-DRAW` with the label and the text whenever a label carries more than one digit strip, so the next sighting names its own cause. |
| ~~Mayhem: the field sat lower after every quit and resume~~ | **Fixed (round 126)**, and it compounded, which is what made it urgent: "each time I quit the app and restarted, the bricks were lower", eventually below the line the run is lost at. A brick is saved as a *row index* measured from the mode's own top row - `yBrickOffsetEndless` in the endless modes, whose field starts at the top of the play area, and `yBrickOffset` in Classic, which leaves a two-row gap under the bar. `ResumeBrickCreation` restored **both** against Classic's, so every resume put the whole endless field two rows lower, and the shifted field is what got saved next time. `resumedBrickTopRow` now names the rule in one place so the save and the restore ask the same question, and a test walks five save-and-resume cycles to prove the row comes back where it started. |
| **Play-test round 126: the rest of the list, still open** | Taken in the order given, with what is *done* struck out elsewhere in this table. **Still to build:** ~~the daily's twist info beside the level info on the pause and game-over screens, with the stats block nearer the bottom above the big button; position in front of a listed daily score with the field size after it ("1st / 200"); the daily menu's score container moved down to sit just above the date~~ - **all three built, round 137.** The pause and game-over screens now carry *two* daily blocks rather than one: the day's rules sit with the level they are the rules of, and the result - posted, or free play - sits with the run's numbers, which is what it is one of. The block also stopped naming the day, because the header two lines above it already does. `updateDailySummary` had to move to the *end* of `updateLabels`: every branch above it decides which of the storyboard's two "title under the level" constraints is running, and the rules replace both, so called first it left two constraints of equal priority fighting and the block laid out where nothing could be read. On the briefing screen the result card is pinned to the bottom of its page instead of stacked under the details, so it lands just above the date on every day rather than wherever that day's twists left it. The placing needed a new Game Center call: `loadDailyStanding` asks for the global entries rather than the local player's, because that is the only load that reports the field size, and `DailyStanding` turns the pair into "1st / 200" in one place for both screens (ordinals through a formatter, so 11th is not 11st and other languages get their own rule). ~~the power-up reference's pinned headings still disappearing behind the scroll blur~~ - **built, round 138**: the band that keeps a pinned heading out of the fade was switched on for the *in-game* headings only, and the reference page grew its own pair (CLASSIC GAME MODES, ENDLESS MAYHEM) when it was split by mode, so out of game the heading sat in the fade and dimmed as the squares travelled under it. It now follows whether there are headings at all, and takes its height from the same constant the layout is given. ~~the about screen's website and email building in with the rest of the animation and sitting a little higher~~ - **built, round 138**, and the report was the visible end of a bug in the whole screen: every step of the cascade did its `delayFactor += 1` *inside* its own animation block, which UIKit runs when the animation begins rather than when it is scheduled, so all eight calls read a delay of 1 and every line arrived at once. The step now happens where it is written, the two links arrive one after the other rather than as a block (they share a stack view, which is a fact about layout and not about reading), and the pair sits higher, with the credits rather than at the head of the small print; ~~a tab bar on the achievements page in the statistics page's style and with the same sections, and wider padding in its cells~~ - **built, round 139**. The sections are the statistics page's five, and which achievements sit under each is not a matter of taste: an achievement belongs to the modes it can be *earned* in, which the checks that award it already say. `AchievementCatalogue` is that reading made once, with three rules covering all sixty-six - a check guarded by `endlessMode` belongs to **both** endless modes (nothing in those checks asks which), one guarded by `endlessMode == false` or living in the between-levels pass belongs to Classic, and one with no mode guard at all belongs to all three. **The Daily tab is deliberately empty and says why**: `achievementsCheck()` returns early for a daily, because a day played on a level you have not earned must not unlock what earning it would have (daily spec §9), and its own set arrives with that spec's phase 5. A tab that is simply missing reads as an oversight; one that explains itself is the rule, visible. The squares' names got room too - `PackGridCell.namePadding`, per screen like `iconScale`, because an achievement's name is a sentence where a pack's is a word; **one button arrangement across every screen** - **built round 128, corrected round 135 to two**: `layoutMenuButtonRow` is the single arrangement, outer buttons 55pt from the *screen's* edge (not the row's - some of these rows are inset by their own container and insetting each by the same amount put their close buttons in different places), the rest of the width shared evenly, and the row growing to hold its tallest button. Six screens' bespoke spacing maths deleted in favour of it. **Round 135: there are two arrangements, not one, and which a row wears is decided by what is in it** (James's call). A row with a large centre button pulls its small buttons in to 55pt, so the three read as one group around the thing that matters. A row that is only small buttons pushes them out to the row's own ends, which is where they have always been and where a close button is easiest to reach - round 128 put every row in the narrow arrangement, which was half the answer. The two screens that build a close button by hand rather than taking the shared row use `menuButtonWideInset` for the same reason. **The main menu is deliberately exempt** and not routed through the helper at all: its information and settings buttons sit where James wants them. Still to route through it: the pause screen, whose row carries its own iPad branch; and the sizes themselves are still two constants in two files (`smallButtonSize`, `playButtonSize`) that want to live together; ~~Fog of War's bricks vanishing even if the build-in has not finished, faster and foggier, ideally fading row by row as the rows below build in~~ - **built, round 140**. The fog used to start when the build-in *ended*: a look of 1.1 seconds and a fade of 0.55 measured from there, which is why the first ball was in a field that was still visible. It now travels down with the build-in - each brick is scheduled to fade a beat after its own landing, so the top rows are going while the bottom ones are still arriving and the field is gone by the time it is whole. The look is 0.45 and the fade 0.3. `closeDailyFog` stays as the sweeper for what the build-in never owned (a field built with no animation, or the bricks left when a tap skips it halfway down). The wait is held by the scene and only the fade itself runs on the brick, because `countBricks()` gates row generation on a brick having no actions (§8.6) - a second-long wait on a brick would have held a Mayhem day's descent; ~~the classic pack screen's icon matching the endless menus' size and shrinking as the packs scroll~~ - **built, round 141**: the shrink was already there from round 36, but the logo was 80 where the endless menus wear 190, so it read as a different screen's furniture. Both now take the number from `menuModeLogoSize`, and the shrink travels over 140 points rather than 100 because the same scroll now has three times the height to give back; ~~a dynamic cloud background and a better Glow~~ - **both built, round 144, and both want James's eye.** **Clouds** is the eighth background and the only one that moves: two strips of soft, wide, very faint cloud drifting across the gradient at different speeds, because parallax is what makes a flat picture read as depth. Each strip is drawn so its two edges match - every blob near an edge is drawn again on the other side - and two copies of it travel together, so there is always cloud on screen and the restart cannot be seen. The first pass drew the cloud in the border's own purple at a tenth alpha and it was invisible: added light on a very dark ground is nearly nothing, so the colours are lifted well off the background's. **Glow** gained a second pool - violet, smaller, low and to the right of the green one - because one pool lit a corner and left the rest flat, where two put a diagonal across the field the way the Classic artwork does. Its haze also moved on to a node of its own so it can breathe: a fifth of its strength, in and out over eight seconds, slow enough to be felt rather than watched. Both use repeating `SKAction`s, which is fine on scenery and forbidden on a brick (§8.6). The strengths are guesses to be judged in play; ~~Clear And Retreat becoming *timed* and raising the lowest brick level by two rows rather than clearing one~~ - **built, round 136**, see §5.4: the clear is two rows deep and a clock holds the field where it left them, because the cadence closing that gap is what made the instant version invisible. The round also closed a gap it found on the way: Randomised Bounce and Ghost Ball were timed, freezable and wipeable, but were in neither the ring HUD's list nor the save's, so both ran unshown and were lost by a resume. Those two lists are now one table (`endlessIIFieldClocks`), which is why the miss could happen twice and cannot happen a third time; ~~and a new brick type that breathes between small, normal and big~~ - **Breathing, built round 142.** It shrinks to half a cell and swells back to fill it, over and over, keeping its node exactly where it is: `position.y` is how the rest of the game knows a brick's row (§8.6), and a brick that breathed by moving would be in a different row twice a second. **It never swells past the cell it owns** - growing further would need the cells around it kept clear the way a Spinning brick's are, and a brick that grew into an occupied cell would be sitting inside its neighbour. If James wants it to reach Big, that is the reservation machinery to borrow and a round of its own. A cosine rather than a triangle, so it pauses at each end and reads as breathing rather than pumping; the sprite changes every frame and the body is rebuilt in steps of 0.08, because a body is replaced rather than resized. It never grows into a ball - the same rule the flashing brick has, for the same reason: a body arriving around a ball leaves the ball inside a brick and the physics answers that by flinging it. Shrinking is always allowed. It refuses Rounded (a face drawn once at one size), Spinning (both redraw the geometry every frame), Moving (its room is measured in whole cells) and Portal (a mouth has to be a fixed target), and it is in the appearance pool beside Rounded and Flashing, which is the line that makes a style exist at all. |
| ~~Mode icons and two new backgrounds~~ | **In (rounds 130-131).** All four mode icons are now James's artwork read straight off an asset. **The Classic and Daily ones were being *drawn in code*** - Classic was the app icon clipped to a circle with a pale rim stroked round it, so that it could never fall out of step with the app icon, and the Daily was a calendar on an olive disc standing in for artwork that did not exist. Both were reasonable while there was nothing to ship; both put a border on a supplied icon, which is what James saw. A supplied icon goes in as supplied. Two backgrounds joined the picker as well - **Deep Blue** and **Starry Sky**, both play-area artwork at the 1.8236 ratio - which needed a `picture(String)` paint case beside `artwork`: Classic *is* the background node's own texture and is painted by leaving the node alone, so anything else has to say which picture it is. The settings row's list derives itself from `allCases`, so it needed nothing; the picker's test now checks every named asset is actually in the bundle, because a name in that list with no picture behind it is a black screen with a title. |
| ~~Mayhem's mode icon, and the updated Classic one~~ (superseded by the row above) | **In (round 130)**: `Endless2Icon.imageset` is Mayhem's own, `ClassicIcon` is replaced, both with alpha, and `GameMode.menuIcon(for:)` stops handing Mayhem the original Endless icon. The daily card asks that function now rather than naming `EndlessIcon.png`, so a Mayhem day wore Mayhem's icon the moment one existed. **One thing for James:** the Mayhem art is **705x594** where every other mode icon is a square 450x450 at @3x, so it aspect-fits into a square image view and its disc reads noticeably smaller than Endless's beside it in the menu. A square re-export at 150/300/450, with the disc filling the canvas the way the others do, is the fix - the code deliberately does not compensate, because scaling one icon to hide a canvas mismatch is the kind of correction that gets forgotten and then fights the next export. |
| **Play-test round 129: the phantom-brick hole is closed, and the rest is instrumented** | The investigation found the one place in this game where a brick is *deliberately* invisible and solid at the same time: `removeBrick` hides a destroyed brick, leaves its body up for two frames so the bounce the ball is in the middle of resolves against something, and takes it away with an `SKAction`. An action is a fragile thing to hang that on - a node paused and never woken, or an action cleared by something sweeping the field, leaves a solid body under an invisible brick for the rest of the run. **That is a phantom brick, and it explains both halves of round 128**: one of them deflects a ball with nothing to blame, a cluster of them is a ball rattling in empty space. Rather than hunt every path that could strand one, `sweepDyingBricks` makes the removal unconditional - anything still wearing the dying name half a second later goes, action or no action - and it prints `PHANTOM BRICK swept` with a position in DEBUG when it has to. Alongside it, `phantomBrickWatch` audits the whole field once a second for *any* brick-category body on a node that is hidden, transparent or scaled away, whatever put it there; Flashing bricks need no exemption because `setBrickSolid` takes their category away when they turn passable, so a solid flasher is always a visible one. **Not yet proven to be the cause** - the sweep is a guarantee rather than a diagnosis, and the next sighting with a console attached will say whether it was this. If the crooked ball survives it, the tripwire's position is still the thing to read. |
| **Play-test round 150: the resume bug, and what it explains** | "On quitting the app and resuming Endless Mayhem, the bricks are different. Some overlapping, some different types, some in different positions." Two causes, both fixed, and together they are the best explanation the phantom brick has had. **One**: the save stores each brick as a texture, a colour and a *cell index* - all Classic and the original Endless have ever needed. A Tiny set is four quarter-cell bricks sharing one cell, so four cell indices round to the same cell and the restore built **four full-size bricks stacked on one spot**: one brick you can see and four bodies to hit, which is exactly "the ball bounced around between bricks that didn't exist". Mayhem now saves the brick itself - exact position, size, anchor, role, face, styles, portal colour, anchored flag, power-up index - in `SavedGame.SavedBrick`, and puts it back through the same `applyEndlessIIStyle` the generator uses, so a restored spinner is *in the spinners list* rather than merely tinted like one. The legacy arrays stay and every other mode still reads them, so this is a widening rather than a migration: a save written before this round still loads exactly as it did. **Two**: `brickCreation` ran `applyEndlessIISizes`, `applyEndlessIIBehaviours` and `applyEndlessIIRoles` on **every** resume, so a restored field was re-rolled - a plain brick could come back spinning, and any brick could be split into a Tiny set on top of whatever it already was. Those three lines are now skipped when there is a save to restore. |
| **Sticky Paddle and Portal Paddle, in sequence** | Round 150, and the same bug round 134 fixed for Aimed Sticky: the classic sticky catch returned from `paddleHit` before the Portal Paddle was ever asked, so a portal spent a turn on the contact and did nothing with it. The catch still wins the contact - a held ball is held - and the *launch* now goes through the paddle, leaving at the angle that spot would have given and arriving at the top of the field travelling down. |
| **The paddle-speed field, fifth pass** | Round 161, James: "these things should be the same as in the actual game view - haptics if on, sounds if on, brick hit disappear animation, ball lost animation". The field played in silence and animated its own way, which is the one thing a practice field must not do: what is being practised is the game. **Sounds and haptics** are the player's own two switches, read from defaults and passed into the scene, playing the game's own files - `ballPaddleHit` and a light tap on a paddle landing, `brickHit` and a light tap on a brick, `ballLostSound` and a heavy one when the ball goes. The paddle bounce is the event this screen exists for and it was the one that answered with nothing at all. **The brick** now goes the way `removeBrick` sends one: solid and drawn for two frames (`0.0167*2`) and then simply gone, where it used to fade over 0.15s with its body taken away on the contact - wrong twice, because a brick in the game does not fade, and a brick whose body goes on the contact is one the ball can pass *through* instead of bouncing off, so the very bounce it was in the middle of never happened. Coming back stays a gentle fade: that half is this screen's own idea and not the game's. **The lost ball** shrinks to nothing as it fades over a tenth of a second - `ballLostAnimation`'s own pair of actions - where the field used to fade it flat over twice as long. The whole cycle runs under one action key, because the ball touches a brick for every one of the frames it stays solid for and each reports a contact; `canKnockOut` is that guard, and is what the two new tests ask. |
| **The paddle-speed field, fourth pass** | Round 150. Square corners, because the field sits in the middle of the screen rather than in a card. A ball that gets under the paddle fades out and a fresh one drops in from the top, rather than rattling about below it - which is a thing the game never does, since down there a ball is lost, so it told the player nothing about the speed they were choosing. And the field has **bricks** now: seven standard ones, low density, with the lowest at the game's own paddle-to-lowest-row distance so a rally feels like the game's rallies. A struck brick fades out and fades back four seconds later - nothing here can be finished, so a field that emptied would answer fewer questions the longer it was open. The rows are spread across *this* field's height rather than by the game's row spacing: the first cut used the game's rows and put three of the four above the top of a field half a screen tall. |
| **The shaped paddle faces, as built** | All four are harmful, rare and turn-based - five paddle turns each, the paddle batch's own count - and one runs at a time, because a paddle cannot be domed and dished at once. **They cost four functions rather than four physics bodies**: a shape decides *where the ball behaves as though it landed*, and the bounce turns that into an angle exactly as it always has. Which is also why the design question the note worried about - how they conflict with the paddle group - answered itself: Inert Paddle sets the influence to zero, so nothing a shape says is heard; Flipped Angle mirrors it; Auto-Aim replaces the angle afterwards and beats it. No conflict rules were needed at all. Every shape is *odd* - f(-x) = -f(x) - so none of them favours a side, and every one stays inside -1...1 so a shaped face can never return a ball flatter than a flat one; both are tested across the whole face for all four. Convex is `sin`, concave is a cube, wavy is a sine blended with the straight line, and jagged is a triangle wave - the first attempt at jagged was built from flat facets and was neither odd nor continuous, which is a paddle that is *wrong* rather than tricky. The face is drawn on the paddle from the same `shaped` call the bounce uses, so the picture cannot promise a shape the bounce does not give. **Not saved across a resume**: which shape is running is not in the save format, so a resumed run comes back domed. A fifth field for a five-turn power-up is not worth migrating a shipped save. |
| **Double Paddle, as built** | Harmful, uncommon, twelve seconds, the sixtieth power-up. The paddle splits, and there is a hole in the middle of it. **The price the queue put on it turned out to be wrong, which is the part worth keeping**: "a second paddle is per-ball contact handling all over again" assumed a second node, and there is not one. The split is a *composite physics body* - `SKPhysicsBody(bodies:)`, two rectangles with a gap between them - and two child sprites drawn over them, so there is still exactly one paddle. Everything that knows about the paddle carries on unedited: the touch handler moves one node, `paddleHit` reads one position and one width, the Halo hangs off it, Aimed Sticky catches on it, the Portal swallows through it, and a shaped face still bends the bounce by where the ball landed. A test asserts the scene contains one paddle, because the day that stops being true is the day the cheap version stops being cheap. Three decisions: the halves are cut **within the existing width** rather than each being half the original with the pair spanning wider (the width is written by Expand and Shrink and read by the bounce, and a power-up that quietly widened the span would fight both) - a small departure from the note, and James's to overturn; the gap is **14% of the paddle**, a little over a ball, so a ball straight down the middle goes through and a ball anywhere else does not; and the body is **re-cut whenever the width changes**, so a split paddle that is then expanded gets its hole in the right place. The replacement body copies its masks off the body it replaces rather than from remembered constants, because Wrap-Around takes the border bit away and every level state puts it back, and a rebuild that asserted its own answer would undo whichever was in force. It is timed, so a Lock freezes it and a Wipe clears it; it saves and comes back split. **One thing found by looking, which is why visual work gets looked at**: the new icon came out as a bare red square with a dot on it, and so had Drift's since round 148 and Safety Paddle's paddle since round 143. `PowerUpIcon.badge` paints the badge with `colour.setFill()` and hands the context to the glyph with that fill still set, so any glyph that fills without naming a colour paints red on red - the stroked ones were fine, which is why it took three icons to show. White is now set once in `badge` before the glyph runs, so the fix covers the ones that exist and the ones that do not yet. **Round 166: it was invisible in the Retro theme, which is what "it didn't seem to do anything" was.** The paddle a Retro player sees is not the paddle sprite at all - it is `paddleRetroTexture`, a separate node drawn over the top at zPosition 4 with its own art and its own proportions. So the body split, the halves were drawn underneath it, and a whole paddle was painted over them: the only sign of the power-up was a ball falling through the middle of a paddle that looked solid, which reads as a bug rather than a feature. The overlay is now hidden for as long as the split runs - every frame, outside the rebuild guard, because the level states show it again on their own schedule - and put back by the same rule the rest of the game shows it by. The halves wear that art at its own height, so a split paddle still looks like the paddle the player chose, while the *body* stays the paddle's own height: the Retro dress is two and a half times as tall, and a body built to the picture would catch balls above and below the paddle everybody else is playing with. Four tests, and looked at in both themes. **Still worth an eye:** the Retro laser flash and sticky band are separate overlays too, and a long enough Sticky Paddle over a split would paint over it the same way. |
| **Drift, as built** | Harmful, uncommon, ten seconds. The whole field slides sideways at 0.45 cells a second, and the falling power-ups slide with it - which is most of what makes it read as weather rather than as the bricks misbehaving. Three decisions the one-line idea left open, all worth arguing with in play: **at the wall it turns round** rather than carrying on, because a field that carried on would have to destroy the bricks that reached the edge and that is a different power-up - but under Wrap-Around it *does* carry on and come back in the far side, which is what the note asked for; **anchored bricks stay put**, the same ones the descent leaves alone, since a Fixed brick's whole meaning is that it stopped where it was struck; and **everything snaps back to a column centre when the clock stops**, because the generator, the crush and the neighbour rules all speak in cells and a field half a column out would keep working by rounding until the day it did not. The drift runs before the movers in `tickEndlessIIBricks`, so a wandering brick wanders from where the drift left it - they both write the same x, and the order is the whole of their agreement. |
| **Play-test round 147: the paddle-speed screen, third pass** | Three complaints, three different causes. **Thumb room**: round 122 put the paddle a kill-line's clearance above the field's floor - 36 points - reasoning that the field is a window onto the bottom of the play area. It is, but the window was cut too low: the game leaves nearly 200 points of screen under the paddle and all of it is thumb. `GameSceneLayout.paddleCentreAboveScreenBottom` is that figure, derived the way the scene derives the paddle's own y, and the field now uses it (capped at 0.45 of the field, since the field is shorter than a screen). **Stutter**: the field's container had a corner radius and `masksToBounds`, which makes Core Animation render a live Metal surface into an offscreen buffer and mask it *every frame*. The corners are drawn over the top by one static layer instead, and the view now takes the game's own `ignoresSiblingOrder` and 120fps ceiling. **The bounce**: the practice paddle was a plain elastic body, so it mirrored the ball back - a wall, not a paddle. The bend-by-where-it-landed formula was written out three times in the app and nowhere shareable; it is `PaddleBounce` now, and `paddleHit`, the Portal Paddle's re-entry and the practice field all ask it. The arriving heading is sampled in `update` for the reason §8.6 gives: a contact reports the velocity after the engine's bounce. |
| **The design workbook** - `Giga-Ball 2026.xlsx`, James's, first fill round 146 | Nine sheets: a detail table and an interaction matrix each for power-ups, bricks and twists, plus a read-me, a not-built list and a one-page statement of what each mode is. **It is generated rather than typed** - `tools/build_design_workbook.py` reads a JSON dump written by `CatalogueDumpTests`, so every derived cell comes from the game's own tables and cannot drift from the code. The matrices' rules are derived too where the game has one: brick pairs from `EndlessIIStyle.stacksWith` and `.suits`, twist pairs from the one-per-category rule, and a power-up against itself from its stacking rule. What is *not* derived is a power-up pair with no rule in the code - those cells are the specs' own words where there are any and my reading where there are not, and the ones marked ASSUMED are the ones to read first. Re-run the two commands in the test's header comment after adding anything. |
| **Play-test round 145: three from the morning's list** | ~~The Glow and the Clouds sitting too low, "below half way down the game view"~~ - **fixed**: the scene's background node is anchored at its *top* and the overlay copies that, but the new moving layers were left on the default centre anchor, which put each one half its own height down the screen. The picker was right all along, because it draws an image into a rectangle and never has to agree with anything about anchors. ~~The achievements page's tab bar fighting the grid~~ - **fixed**: the picker was laid over the grid's top with a content inset making room, which is how a navigation bar works, but there is no bar behind this one, so squares travelled *through* it. The grid starts under the picker now and nothing overlaps. ~~The two reference pages' sticky headings using different type~~ - **fixed**: the bricks page's was 15pt black at a 24pt inset in a 34pt band, the power-ups page's 13pt bold indented with two spaces in the string, in a 30pt band. There is one recipe now, `ReferenceHeading`, and both pages call it. |
| **Play-test round 128: phantom bricks, and two power-up pairings** | **The crooked ball has a place now**: "still randomly changing angle in the middle of its flight *near the low brick line*". And with it, the report that most likely explains it: "the ball started bouncing around between bricks that didn't exist - bouncing rapidly as if in the middle of a group of bricks even though there were none nearby". Those are one bug, not two: a **physics body left behind by a brick that is gone**. A single stranded body deflects a ball once with nothing visible to blame, which is the crooked ball; a cluster of them is a ball rattling around in empty space. Where to look, in order: any path that hides a brick rather than removing it (`isHidden` is legitimate for invisible bricks, which keep their bodies on purpose - so the question is whether a *destroyed* brick ever takes that path), the descent's row recycling, and the Cull, Clear And Retreat, Wipe and explosion paths, all of which remove bricks in bulk. The round-104 tripwire prints `CROOKED BALL, unexplained` with a position - if the position is near `finalBrickRowHeight`, this is confirmed. **Also**: with Portal Paddle and Aimed Sticky together the aim arrow should point *down from the top*, because the ball is going through the paddle and re-entering above (round 88 built the aim on to the re-entry; the arrow was never turned round to match). And the Trajectory Line should respect Portals as it now respects Wrap-Around and Giga-Ball (round 122) - **built, round 133**. A Portal is neither a wall nor a hole, which is why this needed a third answer rather than a flag: the line used to *bounce* off one, because the predictor treats every brick as reflective, and simply removing portals from the brick list would have drawn the line straight through, promising a flight the ball never takes. Where it comes out cannot be predicted honestly either - a pair chooses its exit at the moment of entry. So `BallPath.predict` gained `absorbers`, rectangles the path *ends at* whatever the bounce budget says, and the line now stops at the portal's mouth: the only one of the three that is true. A Giga-Ball passes through portals as it does everything else, so it is given no absorbers either. **And the aim arrow** - **built, round 134**. It was not only the arrow: Aimed Sticky catches a ball *before* Portal Paddle can swallow it, so with both running the aim won the contact and the portal did nothing with the turn it had just spent. They speak in sequence now, the way they do with Auto-Aim - the aim chooses the heading and the paddle still swallows the ball, so an aimed shot leaves through the paddle and arrives at the top of the field travelling down, which is the whole gift of holding a portal paddle. The arrow is drawn where the ball will *appear* rather than where it is, at the heading it will appear with, mirrored from the same number the launch mirrors. |
| Play-test round 88: Auto-Aim, magnetism and a crooked ball | **Auto-Aim never hits the brick it is aiming at** - **fixed in round 103**, and the play-test's wording was exact. Neither of the suspects this row named was the cause: `endlessIIApplyAutoAim` was built in round 22, documented, and covered by tests that called it directly - and **no bounce in the scene ever called it**. The marker drew, the turns were spent, and the ball left at the ordinary bounce angle; only the Portal Paddle re-entry (aimed inline, round 88's other fix) ever actually aimed. `paddleHit` now asks the aim last, after the bounce has chosen its angle, and a test drives the real paddle bounce so the wire cannot silently drop out again - a lesson in what a passing suite is evidence of, alongside round 62's unlinked dylib. Two accuracy refinements went in with it: the target choice now refuses a brick the launchable arc cannot reach (`endlessIIAimCanReach` - `autoAimAngle` clamps to the arc, so a shallower target would be marked and then missed as the clamp bends the shot up underneath it), judged from the launch point by marker and redirect alike so the promise and the delivery stay the same thing; and **the target ring is now prominent** (0.9 alpha, thicker stroke, glow), which was this row's third item. The skip-no-benefit gap was closed in round 22's follow-up (`endlessIIWorthAimingAt`, row above). **Paddle Magnetism reaches too high**: built - the pull now wakes only below `finalBrickRowHeight + brickHeight*2`, the field's bottom couple of rows. **And a ball that changes direction slightly with no brick and no power-up involved** - investigated in round 98. Every angle writer is contact-driven and every `didSimulatePhysics` effect is gated by its clock, but `ballHorizontalControl` carried a **random kick**: one correction in ten got up to five degrees of random deflection, on every correcting path including the seam bounce, which resolves a frame after the visible contact - a kick that lands mid-flight to the eye. **Removed in round 98 - and round 99 says that was not it**: James reports the ball changing position mid-scene with nothing around, and that the issue **appeared only a few builds ago**, which makes it a regression to trace, not a 2020 behaviour. The markers and the kill line carry no physics bodies (checked, round 99), so they cannot deflect anything. **The tripwire is built (round 104)**, and building it produced a new prime suspect. `CrookedBallTripwire` (pure comparison in `BallPath.swift`, tested; scene half DEBUG-only) runs last in `didSimulatePhysics` and compares the main ball frame to frame: a heading bend past half a degree *or* a position jump no frame of flight could cover, on a frame where no contact fired and no writer left a note, prints a loud `CROOKED BALL, unexplained` line with position, heading and the Perspective Zoom flag (zoom bends the *apparent* path of a straight ball - a sighting by eye with zoom on and no line is the camera, not the physics). Every deliberate writer now announces itself via `crookedBallNote` - contact, seam-bounce, wrap, portal-exit, paddle-portal, handover, horizontal-escape - and a trip explained by anything rarer than an ordinary contact prints quietly with the writer's name, so a sighting can be matched to what moved the ball. **The new suspect: `breakHorizontalRuns`**, found by enumerating writers for the instrument. It went in with the ceiling-run fix (`06a5d4b`, 2026-08-06 - a couple of days before the sightings were first reported), runs every frame from `update` in **all modes**, and kicks any ball within `minAngleDeg` (10°) of horizontal out to 10-16° - a several-degree bend, mid-flight, no contact, at an arbitrary moment, which is the report word for word. The timeline fits and the previous three suspects (seam resolver, portal/wrap leak, aim freeze) do not fit "recent" nearly as well. Next play-test with the debug build on the console: a sighting alongside a `horizontal-escape` line is the confirmation. The fix is then a design call, because the escape is load-bearing (a horizontal ball can never be lost or played): likely soften it - narrower trigger band, gentler bend, or defer the correction to the ball's next wall bounce where a bend belongs |
| Play-test round 85: the long list | Queued verbatim so nothing is lost, roughly in the order they were given. **Sizes and spacing:** daily challenge level previews slightly larger (**built, round 120**: 72 to 92 - the picture is the day's identity on a card with room to spare, and it doubles as the detail-view row height matching the statistics page at 42); app icon images larger in their squares (**built, round 114**: `PackGridCell.iconScale` is a replaceable multiplier - a multiplier cannot be edited once made - and the two *choosing* grids, app icons and themes, pass 0.58 against the reference grids' 0.42, because their picture is the thing being chosen while a reference square's name has to read as easily as its picture); stats table cells taller and more padding between title, tab bar and table (**built, round 116**: rows 35 to 42, the title-to-tabs gap 5 to 18 and tabs-to-table 12 to 22 - the page is a list of facts to read down rather than controls to hit. The same round found the round-111 duration rows reading "1 minute" for every run, because `playTime` floors everything under two minutes and most endless runs end inside two: `runTime` now says seconds below a minute and mm:ss above, so the longest run stops equalling the average); achievement titles over two lines with taller squares if needed; detail-view cells slightly taller (**built, round 120**: the item-stats rows take the statistics page's 42 - the two pages print the same kind of fact and should not print it at two sizes); the endless menus' header row sits far above the previous-runs table and should come down (**built, round 109**, and it was round 96's own doing: `giveMenuListsBreathingRoom` adds a 32pt spacer inside every menu table, and this list carries its header row *outside* the table, so the spacer landed between the header and the first run. The table opts out with `wantsBreathingRoom = false`; its clearances were already in its own constraints, 4pt under the header and 20pt over the buttons. Worth remembering for any list that draws its own header: the breathing room is for lists whose first row is their top); game-over replay glyph bigger to suit the bigger button. **Behaviour:** choosing an app icon or a theme should return to the settings list; the theme row should show the chosen theme as its icon, the way the app icon row does; the power-up reference wants sticky headings reading CLASSIC GAME MODES and ENDLESS MAYHEM, in the bricks page's style (**built, round 113**: the split is derived from `LevelPackSetup.isEndlessIIPowerUp`, the same question the drop tables ask, rather than a second list that would be wrong the first time a power-up moved. From the *pause menu* the page keeps THIS RUN / OTHER instead - there the split that matters is what this run has already seen - so `showsModeSections` is the menus-only case); the game-over More Stats view should use the stats page's table style (**built, round 117**: the run's facts were one centred attributed label and are now a `StatsTableViewCell` table in the same glass panel with hairlines, sized to its content and never scrolling, because the list is a fixed dozen. The screen's own "Best single ball ... hits" also picked up round 85's rename, which the statistics page had taken and this one had not - the same fact, said two ways, in two places); the main-menu pop-up needs a home icon (**built, round 115**: `WarningViewController` had no icon slot at all, so all four confirms gained one - house, arrow.clockwise, trash, hand.draw. **Superseded by round 162**, which folded that sheet into `GigaBallAlert`: the icon is a view above the title there, laid out by the card's own stack, and the attachment trick below went with the sheet. Kept because the reasoning is still why a *view* wants a stack rather than a hand-placed frame. Drawn *inside the title label* as a text attachment rather than as a view above it: a view has to be placed against a card whose padding lives in the storyboard, and the first attempt sat half in and half out of the card's top edge. An attachment reflows inside the label the storyboard already places, inherits its centring, and wears the title's own glow for free, because a shadow applies to everything a label draws). **Stats:** rename "Best single ball" to "Most hits on a single ball" and drop the "hits" suffix from its value (**built**); total play time per mode and duration stats beside height for both endless modes (**built, round 111**: four optional counters credited from the one line that already knew a level had ended and how long it took, so they always sum to what `playTimeSecs` counts, plus per-run duration arrays beside the heights. A mode never played holds `nil` rather than zero, so its tab prints no row instead of "Play time 0s"; the average run counts only the runs that *have* a duration, because durations went into the save long after heights and dividing recorded seconds by every run ever played would report an average shorter than any real run. Both ride to iCloud through keyed tables like the metres, counters highest-wins and duration arrays whole-array biggest-total-wins - the same rule the heights travel by, which it has to be, or a device could end up with one device's heights and another's durations). **Mayhem bugs, and the most urgent of the lot:** with Aimed Sticky running, new rows kept descending while the standing field stayed paused, and after a pause-and-resume bricks descended *below the paddle* - the descent must be frozen for the whole time the aim is in progress (**built, round 87** - the field waits for the aim); and Aimed Sticky cancelling the angle-benders and vice versa is **built, round 99** - most recent wins across the whole group, Portal Paddle untouched, and a cancellation landing mid-aim still owes the held ball its launch. **Trajectory:** the line is not fuzzy enough, and the fuzziness should *increase* with distance from the ball (**built, round 106**: the round-42 fade kept the stroke at a fixed width, so the far end read as a thin crisp core with a faint halo, not a blur. The stroke now swells as the certainty falls - 1.5pt at the ball to 3.5pt at the far end - the glow grows on a square so it arrives mostly over the far half, where the guessing is, and the near end is a touch brighter so the contrast makes the fade legible. Glow per segment stays modest deliberately: `SKShapeNode` pays for glow, and four balls can put four lines of ~45 segments each on screen. Visual tuning, so the judge is the next play-test) |
| ~~Settings icons that answer to their setting~~ - **built**: James took option (a) and drew the art. All six rows answer to their setting - sound, music, haptics, parallax, swipe-up-to-pause and the paddle-speed row, which has an icon per quarter-step - and round 147 replaced the lot with his updated versions. Haptics still wears the older off icon, which was not in that batch | Play-test round 85, and it **forks on a decision only James can make.** Wanted: a diagonal slash through music, perspective zoom and swipe-up-to-pause when off; the sound waves dimmed when sound is off; the vibration waves dimmed when haptics are off; and the paddle-speed icon gaining or losing speed lines with the speed chosen. The current icons are flat PNGs, one image each, so **dimming or removing part of one is artwork, not code** - the parts are not separable. Two ways: (a) new art per state, James's side, §8.5, which keeps the drawn look; or (b) move these six to SF Symbols, which has exactly these variants for free - `speaker.wave.2.fill` and `speaker.slash.fill`, the `.slash` forms, and variable-value symbols whose fill follows a number, which is the paddle-speed request precisely. (b) is a day's work and changes how those six rows look; (a) is no code at all. A slash *overlay* drawn in code is a third option and the worst of both - it would sit over art that was not drawn to carry one |
| Game scene: smoothness pass | James, round 84: "occasionally the game can feel stuttery, or the ball's path can feel a bit weird just before or after a bounce - I also notice it when a power-up starts falling." Three separate smells, and worth treating as three: **(a) the stutter on a power-up appearing is fixed (round 85)** - `SKTexture(imageNamed:)` holds a name and decodes the file the first time it is *drawn*, so all fifty-one power-up textures were decoding on the frame their power-up first appeared, on the main thread, mid-bounce; `SKTexture.preload` at scene setup moves that off the render path. Two more spawn-time costs are left and both are smaller: `addPowerUpGlow` builds an `SKShapeNode` with a `glowWidth` per drop, which forces an offscreen pass and would be cheaper as a preloaded radial sprite; and the selection loop reduces two array *slices* per iteration, which is O(n²) allocation for a fifty-one entry table and wants prefix sums - left alone deliberately, because it is the weighting logic and has no test around it; **(b) "weird just before or after a bounce"** is §8.6's territory and should be read against it first - anything sampling a *reported* contact velocity rather than `ballStateBeforeStep`, or adjusting an angle in `didBegin` rather than `didSimulatePhysics`, will read as the ball behaving oddly around the moment of contact; **(c) general stutter** wants measuring before changing anything - a Time Profiler and the SpriteKit debug counters on James's own device, not the simulator, which is not evidence about frame rate. Do not optimise without a measurement; the app is far more likely to be hitching on a spawn than to be short of frame budget |
| Quick Start Guide: a What's New page | Round 84. The guide is five image assets (`IntroView1`-`5`) rendered by `IntroContainerView`, so a sixth page is **artwork, not code** - James's side, §8.5. The pop-up that greets an updating player is built (round 84, `WhatsNew`) and its words are the copy the page would carry |
| ~~Pop-ups gain an icon above the title~~ | **Built, round 82.** `GigaBallAlert.show` takes an optional `symbol`, drawn above the title in the app's green with the title's own glow, and all six call sites name one: a calendar for a closed challenge, dice for the twists, a controller for free play, a hand for the swipe gesture, and the power-up mark for a power-up's explanation. Optional, and absent means no icon rather than a placeholder - a pop-up with nothing to illustrate should not invent something. Two things the doing taught: `symbol` has to sit *after* `message` in the signature, because Swift requires arguments in declaration order and every existing call names `message` first; and the icon draws `.center` with masking off, for the reasons the round buttons learned - aspect-fit would blow a 30pt symbol up to fill the stack, and a masked layer cannot draw the glow outside its own bounds. Original note follows.   Play-test round 39: an appropriate icon above each pop-up title, in the Giga-Ball green/yellow with the same glow the title wears. `GigaBallAlert` is the type |
| ~~Remove the play button from the in-game backgrounds view~~ - **built** (round 21): `hideReturnToGameButton()`, because a button floating over a full-bleed picture of the playfield reads as part of it | Play-test round 39 - see the third-report row above; likely the same cause |
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
destroys the lowest two occupied rows and then holds the field there for eight seconds
(round 136 - it used to lift the field a row instead, and the cadence took that back inside
a second); Laser Beam burns one column per ball in play, each from
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
