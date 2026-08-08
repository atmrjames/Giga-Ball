# Daily Challenge — design specification

**Status: phases 1-2 built and play-tested once; the first feedback round is folded in.**
The generator exists exactly as §2 specifies - SplitMix64, pinned against reference
outputs, exact-output tests as the cross-device contract - and the mode is playable end to
end: the menu row, the briefing screen, and Classic/Endless/Mayhem dailies launching with
the day's twists applied. The first twist batch is live (the economy five, Fog of War, and
the lives twists as revised below). From the play test: the briefing screen now **browses
days** - swipe or arrows, back through every daily to the pool's first day or thirty days
(whichever is nearer), never forward past today, past days labelled practice - which is
§8 arriving early because the browsing UI made it nearly free; every twist wears a drawn
placeholder badge (`DailyTwist.icon`); the pause menu carries the §6 compact summary; a
daily's game over has no play-again and no campaign high-score lines; and the §7 drop
exclusions are standing. **Lives twists count total balls, not the rack**: One Life is
the ball on the paddle and nothing in reserve (the rack is hidden), Loaded is five balls
total, and the endless modes gained **Spare Balls** (three balls total) while **Sudden
Death is parked** - see §4's table.

**Phase 3 is built.** The play press spends the attempt (the record exists from that
moment, so a force-quit finds the day already spent); the scoring run posts to the two
Game Center boards at its end - the recurring daily board and the running-total overall
board (`DailyChallengeBoards`; the boards themselves are App Store Connect work, James's
side, and submissions fail silently until they exist, the same standing state as the
Mayhem boards); the briefing screen's posting line states first-attempt / practice /
spent-but-unposted before every run; per-day records live in `TotalStats` and ride iCloud
as one date-merged blob, which is what carries the attempt flag across a reinstall (§10);
and the game-over screen says posted-or-practice and adds the player's placing on today's
board when Game Center can answer. Not yet built: the remaining twists (phase 4), history
results-on-the-card, streaks, achievements (phase 5), themes (phase 6).

**The test clock** - the play-test rig this feature needs, since days are the unit of
content: the briefing screen carries ◀ DAY / LIVE / DAY ▶ controls that wind a simulated
UTC date backward and forward, persisted across launches and loudly labelled. It must be
removed or debug-gated before release; this line is the tracking for that.

Originally: This is a design document, in the
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
3. **Twist count** — none 30%, one 50%, two 20% at launch, and the structure is built to
   raise the ceiling: because twists live in categories (§4.2) and a day draws at most one
   per category, any count up to the category count is automatically a legal combination.
   Raising the ceiling later is a weights change, not a design change. "No twist" days are
   deliberate — the baseline day is what makes twist days feel like twists.
4. **The twists** — one category at a time, then one twist from within it, both weighted
   and both filtered by mode applicability (§4.2).
5. **Theme** — usually the player's own settings; some days force a dress (§5).

## 4. Twists

A twist is a **named, self-describing rule change**. Each carries: display name, one-line
description (shown on the briefing screen §6), mode applicability, weight, activation date,
and its hooks into the scene. The launch pool, from the brief plus fills:

| Twist | What it does | Modes | Notes |
|---|---|---|---|
| **One Life** | One ball total — the one on the paddle, none in reserve, rack hidden | Classic | The first build racked a spare on top of the paddle ball; the play test counted two lives. A lives twist's number is now the total |
| **Loaded** | Five balls total — four racked | Classic | The generous day |
| **Spare Balls** | Three balls total — two racked behind the ball in play, and the rack shows in an endless run for the one day it means something | Endless modes | The generous day for the modes whose baseline is a single ball (play-test suggestion) |
| **Sudden Death** | Any ball lost ends the run | **Parked — no mode draws it** | Play-test verdict: in the endless modes it is One Life said twice, and in Classic (no Multi-Ball there) it is One Life by another name. It returns with Mayhem Rules, which can put several balls in a Classic level and give "any ball lost" its own meaning. The scene's gate (`dailySuddenDeath`) stays built and tested |
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

Between the menu and the game — every element earns its place. The layout, as revised by
the second play-test round: the **date rides centred above the card** with the browse
arrows fixed either side of it (the date animates with a day swipe, the arrows are the
rail and hold still); a **swipe anywhere on the screen** turns the day, not just on the
card, standing down inside MenuNavigation's edge strips which belong to back and forward;
the card carries a **small picture of the day's level** (the level screens' own artwork —
an endless day wears the mode icon); and the bottom row is the app's standard furniture —
close left, **big play centred**, the Game Center leaderboard button right.

- Mode, and the level name, pack and picture if Classic
- Each twist by name with its icon and one-line description; a baseline day is **Vanilla**,
  named and badged like any twist
- The countdown rides under the date ("Closes in 9h 14m"; past days just say practice),
  and the day's own result shows with its posted/waiting/not-posted badge
- Whether an attempt posts is said **as a pop-up on the play press** when it will not -
  practice, spent attempts, past days - rather than as a standing banner; the scoring
  attempt plays with nothing in its way (play-test round 5)
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
- **Decided, and built:** every daily quietly excludes the four ±points power-ups, both
  multiplier power-ups and Complete Level from drops - the board compares play, not
  multiplier luck, and an instant level-complete is the purest luck there is. Ordinary
  multiplier mechanics stay untouched (play-test confirmation: "the multiplier should
  still build up and down - just no power-up multipliers"), so daily scores still feel
  like Classic scores. When a lives twist runs, Get a Life and Lose a Life stand down
  too - the day owns the lives economy, and the scene's low-lives kindness (it bumps Get
  a Life's weight) would quietly hand One Life a second life. The endless modes' own
  tables already excluded all of these; the daily rule is what makes it true of Classic.
  Ball resets stay available - they are part of the game being scored - with the briefing
  noting they cost time, which on a Time Trial day is its own deterrent. Endless dailies
  are uncapped.
- **No Game Center, no internet** (play-test question): the mode is playable regardless -
  the generator needs no server, so the challenge, the practice loop and the local per-day
  records (§10) all work offline. What suffers is posting: a daily-board submission that
  cannot be made inside the window is gone (the board resets at UTC midnight; there is
  nothing to backfill into), and that is honest - the board is a same-day race. The
  **overall total board self-heals**: it is a running total submitted fresh after every
  posting run, so the first submission after connectivity returns carries everything the
  offline days banked locally. The briefing screen says which situation the player is in
  before the run: signed out ("sign in to Game Center to post today's score") or offline
  ("today's score can't reach the leaderboard right now"). First-attempt tracking is
  local-first either way - the attempt is spent whether or not the post got out, which is
  what keeps the board honest from the phone's side.
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
- **The game-over screen shows the day's result in its own terms** (play-test request):
  the score, the daily summary with the twists, no campaign high-score lines, no
  play-again. Where the player *placed* on today's board goes on this screen too - built
  with phase 3, since it needs the boards to exist and a rank query after the post
  (offline or signed out, the line simply stays away).

## 8. Playing the past

Nice to have, not must have (James's call) — and the first half **arrived early**: the
briefing screen browses days (swipe anywhere on the screen, or the arrows beside the
date), back
through every daily to the pool's first day or 30 days, whichever is nearer, never forward
past today. Today and yesterday say so in words; older days give their date; a past day's
card says "practice — this challenge closed <date>" and plays without posting, ever. The
play test asked for the swiping and the browsing UI made the rest nearly free. 30 days is
a product choice, not a technical one — determinism plus append-only pools (§2.1) mean the
window could be widened to for-ever later at zero cost. What remains for phase 5: the
player's own **result per day** on the card ("not played" / the score), which needs §10's
per-day records to exist first.

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
| **1. The generator** ✅ | Seeded PRNG, `ChallengeDefinition`, pools with activation dates, exact-output tests | That two devices agree, for any date, for ever — entirely in unit tests |
| **2. The mode exists** ✅ | Menu row, briefing screen (no twists yet), Classic/Endless/Mayhem dailies playable, day boundary handling | A full daily loop with no twists — the skeleton habit |
| **3. Attempts and boards** ✅ | First-attempt tracking, recurring daily board, overall board, practice labelling | Post once, practice after, watch the board reset at midnight UTC |
| **4. Twists, in batches** | Economy twists first (they reuse the weight tables), then lives, then layout, then Always On | Each batch on its own, same as phase 8 was tuned |
| **5. History, streaks, achievements** | The past-days list, replay-as-practice, streak tracking | The retention loop end to end |
| **6. Themes** | Forced Retro; Monochrome behind the performance gate | The dress, last, like all presentation |

Each phase ships behind the previous one's tests. Phase 1 has no UI at all and is the most
important one: everything else stands on "every device computes the same day".

## 12.5 Interruption and connection — the fourth round's two design questions

Both came out of playing the phase-3 build, and both are about the gap between "the run
happened" and "the score is on the board". Written up here because each changes §1's
window rule at the edges.

**A daily run must survive being interrupted — built.** The first cut refused to save a
daily at all, so force-quitting mid-run spent the attempt and left nothing to come back
to. It now saves into the same slot, stamped with the challenge's date key, and the
design below is what shipped:

- The save carries the challenge's **date key**, and nothing else about the challenge:
  the generator is a pure function of the key (§2), so the whole thing is recomputed on
  resume and the save can never disagree with what the briefing showed. A save with no
  key is a campaign save and clears any daily left in the session, which is what stops a
  campaign run resuming into a twisted one.
- **A run resumed after its window has closed still plays, and posts nothing.** The
  briefing said the attempt was the scoring one; the deadline says it no longer is.
  The player is told *before* the resume, not after: a warning on the resume prompt -
  "this challenge closed while you were away; the run continues, the score will not be
  posted" - and the run is relabelled practice for its remainder.
- The attempt stays spent either way. Nothing about interruption should be worth doing
  deliberately.

**A score earned offline is posted when the app next reaches Game Center - if the window
is still open. Built.** The rule that makes this honest is the one already in §1: a score
must be *posted* inside the window, not merely earned in it. As shipped:

- A scoring run's record is written as **pending** the moment the run ends, and `posted`
  waits for Game Center to confirm the submission landed. Signed out, offline, and
  board-not-in-App-Store-Connect all leave it pending.
- Launch, foregrounding and opening the briefing screen retry the pending post - today's
  only, because any older pending post is by definition out of its window and becomes a
  **miss**: never posted, score kept locally, the badge reads "not posted".
- The briefing's badge has the third state: a green check once landed ("on the board"),
  an hourglass while pending ("waiting to post"), and the grey "not posted" for
  everything that never will. The game-over line says "submitted", which is the honest
  word before a confirmation.
- The overall total (§7) is submitted from the confirmation, not the attempt - a day
  joins the total when its post lands, never before, and the whole total is resubmitted
  each time so a late-landing day self-heals into it.

## 13. Open questions

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
  *As built in phase 3: quitting to the menu burns it* - the quit path leaves the scene
  without reaching the end-of-run recording, so the attempt reads "spent, nothing
  posted", exactly like a force-quit. Honest, but not yet the recommendation; making
  quit post the partial means routing the pause menu's home-confirm through the same
  recording the run's natural end uses.
- **Monochrome performance** (§5, §4 Blackout).

- **App Store in-app events** (§11.5): App Store Connect setup, James's side.

- **Answered, fourth round — how the daily board works in Game Center.** One board, not
  one a day: a **recurring** leaderboard with a daily recurrence starting at 00:00 UTC.
  Game Center resets and archives it itself, which is exactly the 24-hour window with no
  server of ours. The overall total is a second, ordinary (non-recurring) board. A
  monthly race, if it is ever wanted, is a third board with a monthly recurrence and one
  extra submission - not a change to either of these.

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
