# Daily Challenge — design specification

**Status: design, revision 1.** Nothing here is built. This is a design document, in the
tradition of [ENDLESS-2-SPECIFICATION.md](ENDLESS-2-SPECIFICATION.md) before it was built:
it exists to be argued with before it is implemented, and §12's build phases are written so
each one ends in something playable. [SPECIFICATION.md](SPECIFICATION.md) describes the app
as it stands.

**What this is:** a fourth mode on the main menu. One short game a day, the same game for
every player in the world, open for scoring on a daily leaderboard from 00:00 to 23:59 UTC.
Yesterday's challenge remains playable for ever; only today's posts a score.

**What it is for:** the habit. Classic is a campaign, the endless modes are practice against
yourself; nothing in the app gives two players the *same* game to compare. A daily does —
same mode, same level, same twists, same 24 hours — and it gives a lapsed player a reason to
come back that is not "beat your own number".

---

## 1. The day

A challenge is identified by its **UTC date** — `2026-08-08` names one challenge, for
everyone, regardless of time zone. The scoring window is that UTC day. In the UI the window
is always shown as a countdown ("posts close in 9h 14m") rather than as a time, because a
countdown is true in every time zone and "23:59 UTC" is homework.

- **A score must be finished and posted inside the window** — James's rule, and the right
  one: "finished and submitted before the deadline, not just started". A run that crosses
  midnight mid-play posts nothing and becomes practice (the attempt is spent — the briefing
  screen said so going in). The briefing warns when little time remains, and the Time Trial
  twist (§4) is naturally immune, being 90 seconds long.
- The app checks the day boundary at launch, at foreground, and when the challenge screen is
  open (a timer). Nothing mid-run reacts to the boundary: a run in progress is never
  interrupted by midnight.

## 2. The generator: random but pre-determined

Each day's challenge is drawn from weighted pools — but drawn **deterministically from the
date**, so every device computes the same challenge with no server.

- **Seed:** the UTC date as `yyyymmdd`, mixed through a fixed 64-bit hash (SplitMix64). The
  challenge is `generate(seed:)` — a pure function returning a frozen `ChallengeDefinition`.
- **A private PRNG, never Swift's.** `SystemRandomNumberGenerator` is not stable across
  devices or OS versions, and `shuffled()`/`randomElement()` without an explicit generator
  use it. The generator is our own seeded implementation with its own tests pinning exact
  outputs for known seeds — those tests are the contract that every device agrees.
- **The definition is drawn once, then frozen.** Gameplay randomness (power-up rolls, brick
  mixes) stays ordinary live randomness *unless a twist says otherwise*. The seed decides
  what the challenge *is*, not how every ball bounces — two players get the same rules, not
  the same run. (Exception: a Classic level is fully authored anyway; an Endless daily's
  *field* remains live-random. See §13 open questions for the alternative.)

### 2.1 The version problem — the one hard constraint

Two players on different app versions must compute the same challenge, or the daily
leaderboard is comparing different games. But pools change: new twists, new levels, new
modes. The rule:

- The generator is **versioned**, and every pool entry carries an **activation date**. A
  twist added in the June update has an activation date in July; the generator only offers
  it for dates on or after activation. Old versions compute old-pool challenges for dates
  before their pools changed — and for dates *after* a newer version activated content they
  do not have, they diverge.
- Divergence is handled socially, not cryptographically: when the app knows a newer version
  exists (a lightweight flag — see §13), the challenge screen says "update to play today's
  challenge" once the local generator is stale. Scores still post (we cannot verify
  server-side anyway; Game Center never could), but the window between a release and its
  uptake is kept harmless by **activating new pool content at least 14 days after release**.
- Corollary: pool weights and contents are **append-only with activation dates**. Nothing is
  ever removed or reweighted retroactively, so any past date replays identically for ever —
  which is what makes §8's replay honest.

## 3. Choosing the game

Drawn in this order, each from the day's PRNG stream:

1. **Mode** — Classic 50%, Endless 50/50 split between original and Mayhem (25% / 25%).
2. **If Classic: the level** — one level from the full catalogue, played in single-level
   mode. The daily **ignores pack unlocks**: it is a tasting menu, and a new player landing
   on a Food Pack level they have not unlocked is the point, not a bug. (Their campaign
   progress is untouched.)
3. **Twist count** — none 30%, one 50%, two 20%. Two is the ceiling: three rule changes at
   once stops being a twist and becomes a different game nobody practised for. "No twist"
   days are deliberate — the baseline day is what makes twist days feel like twists.
4. **The twists** — drawn from the pool (§4) with weights, filtered by the compatibility
   matrix (§4.2) and by mode applicability.
5. **Theme** — usually the player's own settings; some days force a dress (§5).

## 4. Twists

A twist is a **named, self-describing rule change**. Each carries: display name, one-line
description (shown on the briefing screen §6), mode applicability, weight, activation date,
and its hooks into the scene. The launch pool, from the brief plus fills:

| Twist | What it does | Modes | Notes |
|---|---|---|---|
| **One Life** | Lives = 1 | Classic | Endless modes already have one life |
| **Loaded** | Lives = 5 | Classic | The generous day |
| **Sudden Death** | Any ball lost ends the run | All | In Mayhem this overrides Multi-Ball's carry-on rule — harsh and legible |
| **No Power-Ups** | Nothing drops, no power-up bricks | All | The purist's day |
| **No Good News** | Only harmful power-ups drop | All | Uses the harmful set Auto-Aim already derives |
| **No Bad News** | Only beneficial power-ups drop | All | |
| **Power Shower** | Drop rate greatly up | All | |
| **Drought** | Drop rate greatly down | All | |
| **Always On** | One power-up permanently active | All | Drawn from a curated subset (§4.1) |
| **Upside Down** | The level's brick layout is mirrored vertically | Classic | Bricks build "the wrong way around" — layout-only; gravity and paddle unchanged |
| **Mirrored** | The level's layout is mirrored horizontally | Classic | The "wrong way around" for muscle memory |
| **Brick Swap** | The level's brick types are remapped for the day (e.g. all normals become multi-hit) | Classic | A small table of remappings, drawn deterministically |
| **Mayhem Bricks** | Endless daily uses Mayhem's style pool at elevated rates | Endless modes | The variety dial turned up |
| **Fog of War** | All bricks are invisible until first struck | All | Reuses the invisible machinery |
| **Time Trial** | 90 seconds on the clock; the score at the whistle is the score | All | The quickest daily there is, and the one that fits the concept best |
| **Blackout** | The whole game monochrome | All | A *twist*, not a dress: Classic bricks are told apart by colour, so grayscale is genuine difficulty there. Mayhem's glyphs keep it fair rather than impossible |
| **Mayhem Rules** | Mayhem's power-ups drop in a Classic level | Classic | Suitable ones only — a curated list excluding anything that needs the descending field (Descent, Clear And Retreat) |
| **Landslide** | The level's bricks descend continuously; whatever reaches the bottom row vanishes, unscored | Classic | Endless's movement in Classic's clothes: the level is escaping, and the score is what you catch |
| **No Pausing** | The pause button is disabled for the run | All | The nerve twist. Backgrounding the app forfeits posting |

### 4.1 Always On — the curated subset

Permanently-on only makes sense for power-ups that are states: Giga-Ball, Undestructi-Ball,
Sticky Paddle (infinite catches), Lasers, Magnetism, Aura, Trajectory Line, Landing Marker,
Auto-Aim, Wrap-Around — and from the bad ones, Inert Paddle, Flipped Angle, Reversed
Controls, Randomised-style saboteurs. Instants (Cull, Multi-Ball, Clear And Retreat) and
economy power-ups (points, multipliers) are excluded: "permanently on" has no meaning for a
thing that happens once. Each eligible entry pins how "on" is implemented (clock pinned
full vs. flag), because Mayhem's turn-based clocks must not tick down.

### 4.2 The compatibility matrix

Same principle as the power-up conflict groups (§5.3 of the Mayhem spec): twists that
contradict cannot be drawn together. `powerUpEconomy` (No Power-Ups / No Good News / No Bad
News / Power Shower / Drought / Always On — at most one), `lives` (One Life / Loaded /
Sudden Death — at most one), `layout` (Upside Down / Mirrored / Brick Swap — at most one).
The generator redraws within the day's stream until the set is legal, which stays
deterministic because the stream is.

## 5. Themes

A daily can force a dress: **Retro** (the existing theme) or the player's own settings
(most days). Monochrome graduated from dress to twist (§4, Blackout) on James's point that
it is *harder* — in Classic the bricks are told apart by colour, so grayscale changes the
game, and a rule change belongs in the twist pool where the briefing explains it.
Mechanically it is still a dress: Monochrome is implemented as a
grayscale `CIFilter` on an `SKEffectNode` wrapping the scene — with a performance gate: if
it cannot hold frame rate on the oldest supported devices with four balls in flight, it
ships as a desaturated palette swap instead (§13). Because every Mayhem style carries a
glyph as well as a colour (§7.3 of the Mayhem spec), monochrome is *legible by
construction* — the glyph rule pays off here.

Forced themes never touch the player's saved settings — the day dresses the game, the
player's own clothes are back tomorrow.

## 6. The briefing screen

Between the menu and the game — every element earns its place:

- Mode, and the level name if Classic
- Each twist by name with its one-line description; "No twists — a pure run" on baseline days
- Theme, if forced
- The countdown to the end of the scoring window
- Whether this attempt **posts** (first attempt today, window open) or is **practice** —
  stated *before* the run starts, never discovered after
- One button: play

Replaying a past day shows the same screen with "practice — this challenge closed <date>".
The pause menu shows a compact twist summary, because mid-run is when someone forgets what
Flipped Angle means.

## 7. Scoring, attempts and leaderboards

- **The score is the mode's own score.** Classic: level score. Endless modes: height. No
  cross-mode normalisation is needed for the daily board, because everyone plays the same
  mode on the same day.
- **Only the first attempt posts, and only if it finishes in the window** (§1). The first
  time the play button is pressed on a given UTC day's challenge, that run is the scoring
  run — abandoning it spends it (quitting to menu posts the score of where you were;
  force-quit posts nothing and the attempt is still spent, or the twist becomes
  "force-quit until you like your start"). Everything after is practice, labelled as such.
- **Daily board:** one Game Center **recurring leaderboard** with a daily recurrence
  aligned to 00:00 UTC — Game Center resets these natively, which is exactly the 24-hour
  window, with no server of ours.
- **Overall board:** one classic (non-recurring) leaderboard holding each player's running
  **total of posted daily scores**, submitted by the app after each posting run. Because
  Classic scores (thousands) and Endless heights (tens) differ by orders of magnitude, the
  total uses a **normalised challenge score** so no one mode dominates: Classic posts
  `levelScore`, Endless modes post `height × 100`. The exact factor is a §13 question, but
  the daily board is immune either way. A local tally backs the submitted total; Game
  Center keeps the best (highest) submission, so the total only ever grows.
- **Streaks** are tracked locally (§10) and surfaced on the challenge screen. A streak
  achievement set ships in phase 5.

## 8. Playing the past

The challenge screen offers a scrollable list of previous days (newest first — the same
furniture as the endless history list): date, mode, twist names, the player's result or "not
played". Any past day is playable for ever as practice — determinism plus append-only pools
(§2.1) is what makes this promise keepable. No leaderboard posting, ever, for past days.

## 9. What the daily must never touch

The second hard constraint, inherited from the project's oldest rule:

- **Campaign progress**: a Classic daily on a locked level unlocks nothing and records
  nothing to pack stats or level high scores. Daily stats are their own.
- **Endless bests**: a daily Endless run does not join `endlessModeHeight` /
  `endlessIIModeHeight`, does not post to the endless leaderboards, does not touch best
  height. It is a different game that happens to use the same field.
- **Existing leaderboards and saves**: untouched, as ever. The daily's save slot (a paused
  daily run) is its own, separate from the campaign save.
- `GameMode` gains a `.daily` case (raw value 3), carrying the underlying mode in play; the
  scene continues to ask "is this endless-shaped" through the existing accessors so shared
  mechanics stay shared.

## 10. Persistence

Per-day record, keyed by UTC date string, stored in `TotalStats` (new optional fields, and
the iCloud KVS arrays grown in **both** places — the trap that crashed sync once already):

`date`, `definitionVersion`, `firstAttemptScore`, `posted`, `bestPracticeScore`,
`attemptCount`. Plus `dailyStreak`, `longestStreak`, `totalPostedScore` (the overall
board's source of truth). First-attempt state must survive reinstall well enough to keep
the honest honest — iCloud KVS carries the current day's attempt flag.

## 11. Main menu

Fourth row, below Endless Mayhem: its own icon (a calendar-ish mark in the house style —
§8.5's asset list gains a row), plus a state chip: "NEW" when today is unplayed, the score
when played, and the countdown when the window is nearly over. The detail screen is the
briefing screen (§6).

## 11.5 Notifications and sharing

- **Local notifications, opt-in, three kinds** (from the ideas list): "a new challenge is
  up" (scheduled at the UTC rollover, delivered at a civilised local hour by default),
  "one hour left" only if today is unplayed, and a user-chosen time of day. All local
  scheduling — no server, in keeping with the whole design. Asked for once, politely, after
  the player's third daily, never on first launch.
- **The share sheet**: after a posting run, one tap builds a share card — day, mode, twist
  names, score, streak — as an image for Messages and social media. Promoted from stretch
  to phase 5, because a daily's scores are only social if they can leave the phone.
- **App Store in-app events** (ideas list): a fit for special weeks once the mode is live —
  App Store Connect work, James's side, noted in §13.

## 12. Build phases

| Phase | What lands | What you can test |
|---|---|---|
| **1. The generator** | Seeded PRNG, `ChallengeDefinition`, pools with activation dates, exact-output tests | That two devices agree, for any date, for ever — entirely in unit tests |
| **2. The mode exists** | Menu row, briefing screen (no twists yet), Classic/Endless/Mayhem dailies playable, day boundary handling | A full daily loop with no twists — the skeleton habit |
| **3. Attempts and boards** | First-attempt tracking, recurring daily board, overall board, practice labelling | Post once, practice after, watch the board reset at midnight UTC |
| **4. Twists, in batches** | Economy twists first (they reuse the weight tables), then lives, then layout, then Always On | Each batch on its own, same as phase 8 was tuned |
| **5. History, streaks, achievements** | The past-days list, replay-as-practice, streak tracking | The retention loop end to end |
| **6. Themes** | Forced Retro; Monochrome behind the performance gate | The dress, last, like all presentation |

Each phase ships behind the previous one's tests. Phase 1 has no UI at all and is the most
important one: everything else stands on "every device computes the same day".

## 13. Open questions

- **Endless dailies and run length**: an endless run can be 40 minutes. Cap the daily at a
  height (first to X? score = time-to-X?) or a duration, or leave uncapped? Uncapped is
  simplest and matches "height is the score" — but a daily that can eat an hour cuts
  against "quick daily game". *Recommendation: uncapped in phase 2; revisit with data.*
- **Deterministic endless fields**: should an Endless daily's field itself be seeded, so
  everyone faces the same rows? Fairer, and doable (the generator already fits the
  pattern), but it makes replays memorisable and needs the row generator to take an
  injected RNG everywhere. *Recommendation: live-random field in v1; the twist set is the
  shared experience. Revisit if the leaderboard feels luck-dominated.*
- **The overall board's normalisation factor** (§7): height × 100 is a first guess.
- **The "newer version exists" flag** (§2.1): App Store lookup API, or piggyback on iCloud
  KVS from newer clients, or accept silent divergence for the 14-day window?
- **Abandoned first attempts** (§7): does quitting post the partial score or burn the
  attempt with nothing? Posting-partial is the anti-cheese answer and the recommendation.
- **Monochrome performance** (§5, §4 Blackout).
- **Is ball reset allowed?** (ideas list) — the stuck-ball rescue and the return-tap are
  game mechanics, not cheats; *recommendation: allowed, they are part of the game being
  scored*. The kill-ball affordance in the pause menu is moot on No Pausing days.
- **Score-based power-ups and the multiplier** (ideas list): ±points and multiplier
  power-ups swing Classic scores harder than skill does, which muddies a shared board.
  *Recommendation: exclude the four points power-ups and both multiplier power-ups from
  daily Classic drops by default — quietly, not as a named twist - and keep the ordinary
  multiplier mechanics otherwise, because removing the multiplier entirely makes dailies
  score-incomparable with the player's own campaign instincts.* Needs James's call.
- **App Store in-app events** (§11.5): App Store Connect setup, James's side.

---

## 14. Feedback on the brief, and ideas

**What is strongest in the concept:** the deterministic-but-random generator needs no
server, which fits this project exactly; first-attempt-only posting makes the daily board
mean something; and the mode split leaning Classic (50%) is right, because Classic dailies
are the ones where two players' scores are most comparable.

**Pushback, gently applied above:** three-plus twists a day was in the brief's spirit
("one or more") but two is the proposed ceiling (§3) — twist *combinations* multiply
confusion faster than fun, and the pool itself provides the variety. "No lives" as a twist
(from the brief) is folded into Sudden Death rather than literal zero lives, which the
scene cannot represent. The 24-hour window plus time zones is handled by pinning everything
to UTC date identity and showing only countdowns — never wall-clock times.

**From the ideas list, one rule changed and two ideas graduated:** finishing-not-starting
now defines the window (§1) — stricter and fairer than my draft's rule; Monochrome moved
from theme to twist because it is difficulty wearing a costume (§4 Blackout); and Time
Trial is the single best fit in the whole pool for "a quick daily game" — it may deserve a
higher weight than its siblings.

**Ideas the spec adds, flagged as additions:** streaks (§7, §10) — the single strongest
retention mechanic a daily can have; practice-after-posting (§7) so the challenge stays
playable all day without corrupting the board; the past-days list as a browsable calendar
of what you missed (§8); the state chip on the menu row (§11); generated challenge names as
a possible dress ("get a name from the seed" is free once the generator exists); and a
share card — score + twist list as an image — as a phase-6 stretch.

**The two hard problems, named early:** cross-version determinism (§2.1 — solved by
append-only pools with activation dates, and honestly only *managed*, not solved, at the
edges) and clock trust (a player can set their device clock; Game Center's recurring reset
is server-side, which contains the damage to practice-labelling, not the board itself).
Neither blocks phase 1.
