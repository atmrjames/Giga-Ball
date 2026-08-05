# Endless Mode II — design specification

**Status: draft for review.** Nothing here is built. This is a design document, unlike
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

These are fixed and everything below respects them.

- **The existing Endless Mode does not change.** Same rules, same generation, same
  leaderboards, same achievements. It keeps its place on the main menu. General
  improvements already made in 1.3 (safe-area layout, lives row, save format) apply to it
  as they do everywhere.
- **New leaderboards and achievements.** Endless II scores are not comparable to Endless
  scores, so they do not share a board. Existing player progress is untouched.
- **The play zone keeps its fixed 1.8236 aspect ratio**, as everywhere else in the app.
- **Additive only.** Every brick type and power-up the existing modes use behaves
  identically in Endless II. Nothing existing is rebalanced to suit the new mode.
- **No monetisation, no ads, no data collection.** Unchanged.

---

## 2. Design pillars

**Variety over escalation.** The existing mode's only axis is *harder*. This one's main
axis is *different*. A run should show a player things they have not seen, early, and in
a different order next time.

**Reachable novelty.** New elements must not be gated so deep that most players never see
them. Depth still governs difficulty; it does not govern *exposure* (§6.2).

**The drop rate does not go up.** Power-ups fall no more often than they do today. The
variety comes from *which* ones fall, not how many.

**Legibility.** A player must be able to tell what just happened. This is the binding
constraint on the rules-changing power-ups (§5.3) — if the paddle stops working and the
player cannot see why, that is a bug report, not a mechanic.

**Fun is a play-test question.** Nothing in this document settles whether the mode is
enjoyable. It settles what gets built so it can be played and judged.

---

## 3. What carries over

All existing brick types (Normal, Multi-hit, Indestructible ×2, Invisible) and all 28
existing power-ups are available in Endless II, with unchanged behaviour. The paddle,
ball, physics, multiplier, scoring and lives rules are those in
[SPECIFICATION.md §4](SPECIFICATION.md).

**Lives.** One, as in Endless. Open question in §10.

**Score.** Height in metres, as in Endless. Open question in §10.

---

## 4. New brick types

Nine. Each entry gives the rule, then what has to be true for it to work.

### 4.1 Spinning
Rotates continuously, one direction or the other, at a fixed rate. Purely visual — the
physics body does not rotate, so bounces are unchanged.

*Needs:* nothing structural. Cheapest of the nine and a good first one to build.

### 4.2 Flashing
Fades in and out on a cycle, glowing at full opacity. **Only solid while visible** — the
ball passes through it while faded. The cycle is slow enough to read and to time a shot
against; it is a timing element, not a coin flip.

*Needs:* physics body enabled and disabled in step with the fade. Must not be able to
strand the ball inside a brick that becomes solid around it — if the ball overlaps at the
moment it would turn solid, the brick stays passable until the ball has left.

### 4.3 Big
Occupies 2×2 grid cells. One hit destroys it, as a Normal brick.

### 4.4 Tiny
Occupies a quarter cell. Four fit where one Normal brick would.

*4.3 and 4.4 need:* a grid that can express occupancy other than one-brick-one-cell. This
is the main reason for the playfield abstraction (§8).

### 4.5 Rounded
A brick with a circular or heavily rounded physics body, so glancing hits deflect at
angles a rectangle never produces.

*Needs:* a per-type physics body rather than the shared rectangle. Watch for the ball
resting on top of a circle and losing horizontal speed.

### 4.6 Gravity
When the field descends, a gravity brick falls into any empty cell below it, and keeps
falling until it rests on a brick or reaches the lowest row. If the brick supporting it is
destroyed, it resumes falling.

*Needs:* the grid to answer "what is below this cell", and a settle pass after every
destruction. Falls should be animated, not teleports. Two gravity bricks falling into the
same column must resolve in order, not overlap.

### 4.7 Directional
Destroyed only when struck from one particular side — top, bottom, left or right. Hits
from any other side bounce with no damage. The permitted side is marked on the brick.

*Needs:* the contact normal at the moment of impact, which the physics contact already
carries. The marking must be readable at brick size — an arrow or a heavier edge, not a
colour.

### 4.8 Moving
Occupies one cell but wanders within a 2×2 region, moving continuously. The region is
reserved: no other brick may occupy the other three cells.

*Needs:* the generator to reserve regions, and the grid to model a brick whose position is
not its cell.

### 4.9 Exploding
When destroyed, destroys all eight adjacent bricks regardless of type — including
Indestructible.

*Needs:* an explicit rule for chains. **Proposed: explosions do chain**, so an exploding
brick caught in another's blast also detonates, but each brick detonates at most once per
event, and the chain resolves in one pass rather than recursively over several frames.
This is deliberately powerful — it is the answer to a field that has become too dense.

---

## 5. New power-ups

Eighteen, on top of the existing 28. That total is the reason for §5.1 and §5.2 — at
forty-six power-ups, "what happens when I collect this while that is active" cannot be
answered pair by pair.

### 5.1 Channels

Every power-up declares one **channel**. **Only one power-up may be active per channel at
a time; collecting a second displaces the first**, which ends immediately.

| Channel | Governs | Examples |
|---|---|---|
| `ballMotion` | How the ball travels | Slow/Fast Ball, Gravity Field, Wrap-Around, Randomised Bounce, Portal Paddle |
| `ballBody` | What the ball is | Giga-Ball, Expand/Shrink Ball, Aura, Wrecking Ball |
| `paddleBehaviour` | How the paddle acts on the ball | Sticky, Aimed Sticky, Magnetism, Inert Paddle, Flipped Angle |
| `paddleForm` | The paddle's shape and reach | Expand/Shrink Paddle, Halo |
| `armament` | What the paddle fires | Lasers, Laser Beam |
| `field` | The brick field itself | Descent, Hide/Show Bricks, Quicksand |
| `vision` | Information shown to the player | Trajectory Line, Landing Marker |
| `instant` | Resolve immediately, hold no state | Points, Multiplier, Extra Ball, Complete Level, Zap, Multi-Ball |
| `meta` | Act on other power-ups | Lock, Key, Wipe, Mystery |

`instant` power-ups do not displace anything and cannot be displaced. Everything else is
mutually exclusive within its channel.

This one rule replaces the pairwise decisions: Inert Paddle displaces Magnetism because
both are `paddleBehaviour`; Trajectory Line displaces Landing Marker because both are
`vision`; Wrecking Ball displaces Giga-Ball because both are `ballBody`. Nothing needs to
know about anything else.

**Exception, declared explicitly:** Multi-Ball is `instant` and adds a ball rather than
changing one, so it composes with everything.

### 5.2 Rarity

Three tiers, governing how often a power-up is *eligible* to drop — not how often
power-ups drop at all, which is unchanged.

| Tier | Character | Roughly |
|---|---|---|
| Common | Numeric. Changes a value | 60% |
| Uncommon | Behavioural. Changes how something behaves, within the existing rules | 30% |
| Rare | Rules-changing. Suspends or inverts a rule the player relies on | 10% |

Rare being 10% of drops, not 10% of runs, is the point: a typical run should show two or
three rules-changing power-ups. They must be memorable, not mythical.

### 5.3 The new power-ups

Channel, tier, and the interactions that are not covered by §5.1.

| Power-up | Channel | Tier | Behaviour and notes |
|---|---|---|---|
| **Descent** | `field` | Uncommon | The field moves down continuously for a period. Bricks passing the lower limit are destroyed, not scored. Ends early if the field empties. Suspends the normal descent cadence while active |
| **Trajectory Line** | `vision` | Uncommon | Draws the ball's path ahead for a fixed distance, reflecting off walls. Does not predict brick collisions — it stops at the first brick it would meet |
| **Aimed Sticky** | `paddleBehaviour` | Uncommon | The ball is held; the player drags to choose the launch angle, shown by an arrow. Replaces the automatic launch for the duration |
| **Magnetism** | `paddleBehaviour` | Uncommon | Curves the ball towards the paddle's horizontal position. Strength must fall off with distance, or the ball can never be lost and the run cannot end |
| **Lock** | `meta` | Rare | Freezes every active timed power-up: their timers stop draining. **Only drops while at least one timed power-up is active with enough time left to still be active when the Lock reaches the paddle.** Ends by itself after a period, or by Key |
| **Key** | `meta` | Rare | **Only drops while a Lock is active.** Ends the Lock; timers resume |
| **Laser Beam** | `armament` | Rare | One sustained vertical beam that destroys an entire column, including Indestructible. Single use, then the power-up ends |
| **Portal Paddle** | `ballMotion` | Rare | The ball entering the paddle re-enters at the top of the field, keeping its horizontal velocity. For a period |
| **Wrap-Around** | `ballMotion` | Rare | The ball leaving one side re-enters the other. For a period |
| **Landing Marker** | `vision` | Common | Marks where the ball will cross the paddle's line. For a period |
| **Wrecking Ball** | `ballBody` | Rare | Destroys any brick in one hit regardless of type, and does not bounce off bricks. Distinct from Giga-Ball, which bounces |
| **Aura** | `ballBody` | Uncommon | A glow of twice the ball's radius. Bricks touched by the aura are destroyed; the ball only bounces off bricks it touches itself |
| **Randomised Bounce** | `ballMotion` | Uncommon | Bounce angles gain a random offset. Bad power-up: deducts points |
| **Inert Paddle** | `paddleBehaviour` | Uncommon | The paddle no longer influences the bounce angle; the ball reflects straight. Bad |
| **Flipped Angle** | `paddleBehaviour` | Uncommon | The paddle's angular influence is inverted. Bad |
| **Multi-Ball** | `instant` | Uncommon | Adds a ball. See §5.4 |
| **Wipe** | `meta` | Uncommon | Ends every active power-up immediately. Bad |
| **Paddle Halo** | `paddleForm` | Rare | A semicircular glow extending from the paddle into the lower rows, destroying bricks it touches. For a period |

Colour convention is unchanged: green power-ups are beneficial and award points, red ones
are harmful and deduct them.

### 5.4 Multi-Ball

The one addition that touches everything, and the largest single piece of work here.

The game currently assumes exactly one ball — `ball` is a stored property read in dozens of
places, and the save format stores one ball's position and velocity. Multi-Ball requires a
*collection* of balls, with:

- losing a life only when the **last** ball is lost
- the ball-lost animation, sticky paddle, aura and trajectory line each acting per ball
- the save format storing an array

**Proposed: Multi-Ball is deferred out of the first version** and the collection-of-balls
refactor is scheduled with it. Everything else here works with one ball. Recorded as a
decision in §10 rather than assumed.

### 5.5 Interaction rules not covered by channels

- **Lock and Key are the only conditional drops.** Their eligibility depends on game
  state, which the allocation table cannot currently express — see §8.
- **Wipe does not remove a Lock.** Otherwise Wipe is strictly better than Key and Key
  never drops.
- **Bad power-ups do not drop while the field is nearly clear.** Losing a run to a
  Randomised Bounce collected on the last brick reads as unfair.

---

## 6. Game dynamics

### 6.1 Descent and difficulty

Rows descend as they do today, and density and speed rise with depth. Endless II adds
**phases**: stretches of a few hundred metres with a character of their own, drawn at
random and never twice in a row.

| Phase | Character |
|---|---|
| Standard | The baseline mix |
| Swarm | Many Tiny bricks, sparse |
| Fortress | Big and Indestructible, few gaps, one clear route |
| Flicker | Flashing bricks dominant |
| Cascade | Gravity bricks, so the field reshapes as it is cleared |
| Minefield | Exploding bricks scattered through ordinary ones |
| Drift | Moving bricks, wide spacing |
| Quiet | Low density, higher power-up drop chance — a breather |

Phases are the main lever for making a run feel varied, and the main thing to tune during
play-testing.

### 6.2 Exposure

The requirement is that a player who never gets deep still sees the new elements. Depth
alone cannot do that.

**Proposed: an introduction schedule.** Every new brick type and every Uncommon and Rare
power-up is placed in a shuffled order at the start of each run, and introduced at
intervals through the first stretch of the run — the first appearance of each is
guaranteed, the order is different every time. After the schedule is exhausted,
generation is fully random and depth-weighted as usual.

This gives a player who reaches only a modest height a different subset each run, and a
player who goes deep everything. It is also the mechanism for the mode teaching itself
without a tutorial.

### 6.3 Randomness

Random selection is seeded per run and drawn without replacement within a phase, so a
phase does not repeat the same brick type three times while omitting another. The existing
`PowerUpAllocation` weighting is kept and extended with tier and channel filters.

---

## 7. Presentation

### 7.1 The power-up HUD

The current tray shows a fixed row of eight icons with a depleting bar beneath each,
including power-ups that are not active and ones not yet unlocked. At forty-six power-ups
that does not scale.

**Proposed:**
- Show **only active** power-ups.
- The timer becomes a **ring around the icon** rather than a bar beneath it.
- Icons appear when collected and fade out when they expire.
- The row is centred and grows from the middle, so its width tracks what is active.
- A Locked power-up (§5.3) shows its ring frozen, visibly distinct from a draining one.

This replaces the existing tray in Endless II. Whether it replaces it in Classic and
Endless too is an open question — it is better, but it changes a screen players know.

### 7.2 Dynamic backgrounds

The background scrolls with the field, so descent is visible in the backdrop rather than
only in the bricks. Built on the four backgrounds added in 1.3 — but note that the
background node in `GameScene.sks` will not accept a new texture at runtime (see the
1.3 commit history), so the scrolling background must be a code-owned node from the start.

### 7.3 Legibility of rules-changing power-ups

Each Rare power-up needs a visual that is unmistakable while it is active, beyond its HUD
icon: Wrap-Around marks the side walls, Portal Paddle marks the paddle and the top of the
field, Inert Paddle and Flipped Angle change the paddle's appearance, Halo is its own
visual. A player should be able to tell what is happening without looking at the HUD.

---

## 8. What has to be built underneath

Three pieces of groundwork, in order. None are Endless II features; all are prerequisites.

**1. The playfield and brick grid.** Brick size and position are computed inline today
against a fixed 22-column layout, and there is no way to ask what occupies a cell.
Required by Big, Tiny, Moving, Gravity and Exploding bricks. Needs: cell occupancy,
adjacency, sub-cell sizes, region reservation, and a settle pass.

**2. The power-up system as data.** Eleven near-identical switch cases today, each
declaring icon, bar, timer and expiry inline. Required by channels, tiers, conditional
drops and the ring HUD. Adding eighteen power-ups to the current structure means eighteen
more copies of the same sixty lines.

**3. Level data out of code.** 110 `loadLevelN()` methods differing only in data. Not
required by Endless II, which generates its field — but it is what makes `GameScene`
tractable, and the brick-layout tests added in 1.3 make it safe to do.

---

## 9. Out of scope for the first version

Recorded so they are decisions rather than omissions.

- **Multi-Ball** and the collection-of-balls refactor (§5.4).
- **A separate descent-pressure mode.** The idea of making the field reaching the paddle
  the core threat is a different game, not a variant of this one. Parked deliberately.
- **Saving a run in progress.** Endless II runs are single-life and self-contained;
  resume can come later if runs turn out to be long.
- **iPad-specific layout** beyond what the fixed ratio already gives.

---

## 10. Open questions

For review. Each changes what gets built.

1. **Lives.** One, like Endless? Or three, given the mode is more chaotic and a Rare
   power-up can end a run through no fault of the player?
2. **Score.** Height alone, like Endless? Or height plus points, so clearing bricks and
   surviving are both rewarded? This decides the leaderboards.
3. **Name.** "Endless Mode II" is a working title. It sits on the main menu next to
   "Classic Mode" and "Endless Mode", so it needs to read as a third mode, not a sequel to
   one of them.
4. **Does the ring HUD replace the tray everywhere,** or only in Endless II?
5. **Multi-Ball in or out of the first version** (§5.4).
6. **Explosion chaining** — confirmed as proposed in §4.9?
7. **How long is the introduction schedule** (§6.2)? Long enough to show everything, short
   enough that a deep run stops feeling scripted.
