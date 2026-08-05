# Endless Mode II — design specification

**Status: draft, revision 4.** Nothing here is built. This is a design document, unlike
[SPECIFICATION.md](SPECIFICATION.md), which describes the app as it stands.

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

### 4.0 The full set

Existing types are unchanged; the classification is for the registry (§8.4). **Size is a
separate axis from type** — a Big brick can be Multi-hit, a Tiny brick can be Exploding.

| Type | Status | Behaviour |
|---|---|---|
| Normal | Existing | One hit. Carries a colour, which affects its score |
| Multi-hit | Existing | Four stages; each hit steps it down |
| Indestructible ×2 | Existing | Not destroyed by a normal ball. Cleared by Zap, Giga-Ball, Wrecking Ball or an explosion |
| Invisible | Existing | Solid but not drawn until struck |
| Spinning | New | Rotates; visual only (§4.1) |
| Flashing | New | Alternates solid and passable (§4.2) |
| Rounded | New | Circular body, unpredictable deflection (§4.5) |
| Gravity | New | Falls into gaps below it (§4.6) |
| Directional | New | Destroyed from one side only (§4.7) |
| Moving | New | Wanders within a reserved region (§4.8) |
| Exploding | New | Destroys its eight neighbours (§4.9) |
| Spawner | New | Creates new bricks when destroyed (§4.10) |
| Portal | New | Sends the ball elsewhere (§4.11) |

| Size | Status | Occupies |
|---|---|---|
| Tiny | New | A quarter cell — half width, half height |
| Normal | Existing | One cell |
| Big | New | 2×2 cells |

### 4.1 Spinning
Rotates continuously, one direction or the other, at a fixed rate. Visual only — the
physics body does not rotate, so bounces are unchanged.

**Clearance:** a spinning brick's corners sweep outside its cell, so the generator reserves
the cells it would overlap. Simplest rule: no brick directly adjacent on the four sides.

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
A circular or heavily rounded physics body, so glancing hits deflect at angles a rectangle
never produces. Watch for the ball resting on top and losing horizontal speed.

### 4.6 Gravity
Falls into any empty cell below it and keeps falling until it rests on a brick or reaches
the lowest row. If its support is destroyed, it resumes falling. Falls are animated. Two
falling into the same column resolve in order.

### 4.7 Directional
Destroyed only when struck from one side; other sides bounce without damage. **Drawn as the
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

### 4.11 Portal
Struck rather than destroyed. The ball entering one leaves from another Portal brick
elsewhere in the field, keeping its speed.

**Needs a pairing rule** and an exit direction. Proposed: Portals are placed in pairs, the
ball leaves the far one travelling in the direction it entered, and a brief cooldown stops
it re-entering the exit immediately and ping-ponging.

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
| **Laser Beam** | — | Rare | No | Fires again | A sustained vertical beam destroying a whole column including Indestructible. **One beam per ball in play**, each fired from its own x-position — so with four balls it clears four columns at once |
| **Portal Paddle** | — | Rare | Yes | Extends duration | Ball entering the paddle re-enters at the top, keeping horizontal velocity |
| **Wrap-Around** | — | Rare | Yes | Extends duration | Ball leaving one side re-enters the other |
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
- per-ball state: sticky, aura, trajectory line, landing marker each act on their own ball
- the save format, which stores one ball's position and velocity (§9.3)
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

**Breathers are weighted, not scheduled.** Quiet simply carries a higher weight than the
rest, so breaks arrive often without being predictable. A Quiet phase is **not empty** — a
sparse field would just fly past. It is lower density and easier brick types, so it still
has to be played, just with room to breathe.

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

The background scrolls with the field. This needs **new backgrounds built to loop** — the
existing four do not tile, and only Classic's grid would even come close.

- A repeating grid in the Classic style, seamlessly tiling vertically
- A slow colour cycle that shifts hue as depth increases

The existing four remain available and simply do not scroll. Note the background node in
`GameScene.sks` will not accept a new texture at runtime, so the scrolling background must
be a code-owned node from the start.

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
| **1. The mode exists** | Endless 2.0 on the main menu, playing exactly as Endless does today, with its own stats and leaderboard | That it launches, plays and scores - and that Endless and Classic are untouched |
| **2. The ring HUD** | Only-active power-ups, ring timers, in Endless 2.0 only | Whether the ring reads better than the tray, side by side with the old one |
| **3. Simple bricks** | Spinning, Flashing, Rounded - no grid changes needed | Whether they read clearly and whether Flashing is fair |
| **4. Sizes** | Big and Tiny, on the brick grid | Whether Tiny is worth its cost, which is the open question in §11 |
| **5. Behavioural bricks** | Gravity, Moving, Directional, Exploding, Spawner, Portal | Whether explosions and cascades feel good or chaotic |
| **6. Generation** | Phases, the introduction schedule, gentle opening | The heart of it: whether a run feels varied and whether the pacing works |
| **7. Multi-Ball** | The collection of balls, and the run continuing while one survives | Performance with four balls, and whether it is as fun as it sounds |
| **8. New power-ups** | In batches, simplest first: vision, then paddle, then rules-changing | Each batch on its own, which is the only way to tune rarity |
| **9. Presentation** | Scrolling backgrounds, icons, the information page | The finish |

Phases 3 to 5 can be reordered freely - they are independent. Phase 6 is where the mode
stops being Endless with extra bricks and starts being its own thing, so it is worth
reaching before judging whether the whole idea works.
