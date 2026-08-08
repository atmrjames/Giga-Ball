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

**Sizes** combine with every behaviour and every style, with one exception: a Big brick
cannot be Spinning, because the clearance a full-size brick needs to turn is already two
cells in each direction and a Big one would need four.

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
| **Wipe** | — | Uncommon | No | n/a | Ends every active power-up immediately. Bad. **Does not remove a Lock** — otherwise Wipe is strictly better than Key and Key never drops |
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

**Open, in rough priority order**

| Item | Notes |
|---|---|
| Ring HUD in Classic and original Endless | **Unblocked** - the play test answered the design question that kept this backlogged. The old modes keep their permanent all-power-ups tray in its existing order and geometry (`layoutUnit` untouched, so brick sizes on scored levels cannot move); what changes is the *indicator*: the tray icons gain the ring progress dial in the Giga-Ball yellow-green in place of the old bar. No only-active filtering, no reordering - those are Mayhem's rules for Mayhem's tray |
| In-game recents on the pause info pages | Play-test request: the Bricks and Power-Ups pages, reached mid-run, list what was recently hit and recently seen first - so a player can identify the thing that just happened. Unseen power-ups below, alphabetical |
| Endless game-over stats | Summary on the game-over screen (balls hit, bricks destroyed, power-ups collected), a stats button to a detail screen, and the power-ups seen this run in order |
| Portal Paddle × Auto-Aim | Play-test finding: together, the portal is effectively not applied - Auto-Aim owns the outgoing angle, so the paddle-portal's jump never matters. Proposed resolution: let both speak in sequence - the hit still exits through the portal network, and Auto-Aim aims the *re-entry* (the drop from the top, or from the exit portal) at the lowest brick instead of the launch. James's alternatives if that reads badly: move the aim arrow to the top, or let the player choose where the ball drops in |
| Sticky Paddle × Inert Paddle | Play-test decision: both stay active - the catch still works, but the launch angle comes from what the *inert bounce* would have been, not from the ball's position on the paddle. While both run, the sticky paddle graphic goes monochrome so the pairing is readable |
| Big bricks overlap the lower-limit line | Play-test screenshot: a Big brick's body extends past its row centre, so on the bottom row its lower half crosses the limit line. Options: clip the line behind oversized bricks, or accept the overlap and make sure destruction still triggers at the right moment (it does - the row centre is what is read). Cosmetic, but the line is the kill line and should stay legible |
| New brick geometries | Concave/convex faces, triangles (one pointed side), and a 2×1 square size available to all compatible behaviours - each is a physics-body shape plus §8.6's row discipline, so each is its own careful visit |
| Lock and Key | §5.4's originals, still unbuilt. Lock freezes the timed clocks (the turn-based ones are immune by nature); Key ends it. Their conditional drop rules are most of the work |
| Ball Spin / Curve | New power-up (play-test idea, second round): the paddle's own velocity at contact grips the ball - as if there were friction between the two - and the ball leaves on a curved path, curving harder the faster the paddle was moving. Wears a grippy paddle texture while active. Conflicts with the paddle group (Aimed Sticky, Auto-Aim, Inert at least). Build note: the curve is a per-frame perpendicular nudge from `didSimulatePhysics` (§8.6 - never inside a contact), decaying over the flight, and the paddle velocity must be sampled from the touch handler, not the contact |
| Double Paddle, and an opposite-moving paddle | Play-test ideas for the next power-up batch, refined in the second round: the paddle *splits in two*, each half the width of the original - a second paddle is per-ball contact handling all over again, priced accordingly |
| Classic mode menu redesign | Title and logo like the endless screens, packs as a grid of square cells rather than rows |
| Grid background scaled to the marker grid | Needs the actual artwork's pitch measured against brickHeight - a visual-iteration task, not a blind one |
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
