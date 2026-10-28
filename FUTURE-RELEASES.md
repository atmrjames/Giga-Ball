# Giga-Ball — release planning

Triaged backlog, consolidating notes from 2020–2021 with items identified during the
1.2 (81) compatibility work in August 2026.

Organised by **when**, not by category, because the sequencing matters more than the
grouping. Rationale is recorded so decisions can be revisited rather than re-argued.

---

## Design constraint: the gameplay zone ratio is fixed

**The play zone keeps a fixed aspect ratio on every device.** This is deliberate, not a
limitation — the side borders on iPad exist for this reason. A player moving between
iPhone and iPad must get the same game, so the playfield must not reflow.

The safe-area rewrite below respects this. Safe-area insets move the *chrome* only —
HUD, power-up tray, and the width of the side borders. The play zone stays
proportionally identical. This is strictly better than the current behaviour, where the
ratio is inferred from a three-way device guess and the top-bar bleed bug is a symptom
of guessing wrong.

## Design constraint: existing progress and leaderboards are preserved

Players have years of scores and progress. Nothing may invalidate them.

This shapes how new content is added. New brick types and power-ups must be **purely
additive**: every existing level and pack has to behave exactly as it does today, or old
high scores stop being comparable. New mechanics belong in new packs and new modes, not
retrofitted into old ones.

Concretely:

- Endless mode stays as it is, under its existing leaderboards. A reworked version is a
  *separate mode* with *separate leaderboards*.
- The eleven existing packs stay frozen. New mechanics ship as new packs.
- This is a strong argument for moving level data out of code with a format version:
  old packs pin to the current version and are guaranteed unchanged.
- It also argues for regression tests that assert old levels still produce identical
  brick layouts, power-up probabilities and scoring — the kind of guarantee that is
  cheap to automate and painful to verify by hand across 110 levels.

---

## The case for a foundations release

Three structural problems make everything else more expensive than it should be:

1. **`GameScene.swift` is 5,613 lines with no tests.** Every gameplay feature on this
   list touches it.
2. **Layout is a device-class guess, not safe areas.** `screenRatio` sorts devices into
   `"X"` / `"Pad"` / `"8"` and branches in six places. No `safeAreaInsets` anywhere.
3. **`premiumSetting` gates content across 12 files** for a purchase that no longer
   exists, and is unconditionally forced true at launch.

The ambitious features later in this document — multiplayer, a level editor, new brick
types — all land in that 5,600-line file. Building them first recreates exactly the
situation that made the app unmaintainable enough to break in the first place.

So: **the foundations come first.** Little of that part is user-visible, but it makes
everything after it tractable — which is why, when 1.4's contents were folded into 1.3,
they were folded in *after* the foundations rather than interleaved with them.

---

## 1.3 — Foundations, and the player-visible work that was 1.4

**Scope note (August 2026).** 1.3 cannot ship until iOS 26 [sic — iOS 27] is released,
which is several weeks out, so what was planned as 1.4 is folded in here rather than
held back for a release that would follow immediately after. The foundations still come
first within it, for the reason argued above: the player-visible work lands on top of
them.

### Released (21 October 2026)

**1.3 is on the App Store.** What comes next is decided by players' feedback and James's own
play-testing: fixes go to **1.3.1** (a quick patch or a gathering of small fixes, depending on
severity) and are merged forward into **1.4**, where new features go. CLAUDE.md, "Branches", has
the rules.

### Where it stood (20 October 2026)

**Submitted for App Review.** Built by Xcode Cloud from `release-1.3` as it stood at round 399b
(the pre-release soak written down), uploaded to App Store Connect and submitted on 20 October,
set to release manually so James can announce it the same day. Two faults the soak found were
left out on purpose (James: "let's get 1.3 ready for launch without those fixes for now - we can
start a 1.3.1 release branch"); they are the start of **1.3.1** below.

### Where it stood (25 September 2026, evening)

**iOS 27 has shipped, so 1.3 is no longer timed to it** (James: "that is now released, so the
app update will come later"), and the website says only that it is in testing. What is left:
James's play-testing and notes; the iPad and Mac window resize seen on a device; Aimed Sticky's
sounds; and App Store preparation - a fresh Xcode Cloud build from `release-1.3` (the external
TestFlight build predates rounds 346 to 348), the listing's text and screenshots, and the 32
achievements added since 1.2 set up in App Store Connect and attached to the version with the
new leaderboards.

### Where it stood (25 September 2026)

Phases 1 to 4 below are done, and phase 5 is under way: 1.3 has been on TestFlight for internal
testers since 19 September, and the first build for **external testers** went to Beta App Review
on 25 September. What remains before submission is James's play-testing of that build and the
three items still open in ENDLESS-2 §12.0 (the iPad window resize and the paddle-speed field seen
on a device, and Aimed Sticky's sounds). Everything not built for 1.3 is listed in **1.4** below.
The plan that follows is kept as it was written.

### The road to release (planned 13 August 2026, ~5-6 weeks out)

Target: submit alongside iOS 27, late September. Phases in order, each with an exit
condition, so slippage is visible early rather than discovered at the end.

**Phase 1 - gameplay correct (now to ~22 Aug).** The Mayhem bugs, because a mechanic that
lies is worse than a screen that is cramped: Descent over a cleared gap; Aimed Sticky
cancelling Inert Paddle and Flipped Angle and vice versa, most recent wins, Portal Paddle
compatible with all; Auto-Aim hitting what it marks, skipping useless bricks, with a more
prominent target; Laser Beam doing anything; the Landing Marker's contact geometry;
Magnetism's start height; and the crooked-ball investigation. Exit: several full Mayhem
runs in which every power-up is seen doing what its page says.

**Phase 2 - daily and stats (~week of 25 Aug).** The single-level score tally (Classic's
animation reused) and the daily screen reorder that makes room for it; the similar-days
rule and level naming; per-mode play time and endless duration stats (new storage, the
array drill, the iCloud copies); the power-up reference's pinned CLASSIC GAME MODES /
ENDLESS MAYHEM headings. Exit: a full daily played end to end showing the tally, and the
stats page saying everything §12.0 promised.

**Phase 3 - polish and James's side (~week of 1 Sep).** The spacing list (daily preview
size, app icon cell size, stats and detail row heights, pause-row button insets,
game-over stats position); James's custom settings icons and the Quick Start Guide's
What's New page (art, §8.5); remaining §8.5 assets and sounds; the glass-helpers file
tidy-up. Exit: a screenshot pass of every screen with nothing on the list.

**Phase 4 - hardening (~week of 8 Sep).** Classic and original Endless soak, several
levels each, because those leaderboards carry years of scores; iPad multitasking
restriction; the App Store readiness pass (screenshots, metadata, privacy); confirm the
three in-review boards are live; Xcode Cloud build from `release-1.3` to TestFlight
internal. Exit: the build on James's and his wife's phones with no new reports for a few
days.

**Phase 5 - release (~week of 15 Sep).** Wider TestFlight if wanted, a fix window, then
submit with buffer for App Review, timed to the iOS 27 window.

**Already prepared for 1.4:** the What's New pop-up mechanism is release-agnostic -
`WhatsNew.version` and its copy are the only two things a 1.4 build changes, and the
version key is written on every launch, so 1.4 inherits a correct "seen" state from day
one.

**Scope additions (round 100, James's call).** Pulled forward into 1.3 from the later
lists: the paddle surface shapes family, Double Paddle and the opposite-moving paddle,
Drift, the remaining written twists, and the daily's per-day results, notifications and
share card. Phase 1 also gains the loop-breaker that replaces the removed random kick.
The phases are undated and absorb it; nothing leaves the release to compensate.

**Round 101 widens it again:** Ghost Ball, Safety Paddle, and the daily's streaks and
themes come into 1.3. And three platform features are promoted from "beyond" to "attempt
for 1.3, drop without ceremony if they resist": 120fps ProMotion (**built, round 123** - `preferredFramesPerSecond = 120` plus `CADisableMinimumFrameDurationOnPhone`, and the audit found exactly one place assuming a sixtieth: the sticky catch's lookahead, now the frame the scene measured, floored and capped. Device-only to judge),
iCloud game saves (the conflict story is the work), and a widget (the first second
target in a hand-edited pbxproj, plus an app group and URL routing).

### The 1.3 line, narrowed (3 September 2026)

The August line was widened twice - rounds 100 and 101 pulled the daily's phases 4, 5 and 6
into the release along with three platform features - and by round 299 eight of those pieces
were still written-and-unbuilt. Reviewed against the code rather than the queue, James cut it:

**Out of 1.3, into 1.4:**

- **The widget.** No second target exists; it is the first one in a hand-edited `pbxproj`,
  plus an app group and URL routing. The largest unstarted thing on the list.
- **iCloud game saves.** The conflict story is the work, and getting it wrong costs a player
  their run rather than a nicety.
- **The daily's notifications** (§11.5). No notification code exists in the project at all.
  The share card follows it.
- **Mayhem Rules in the other modes.** The twist reads as a curated weights list and is a
  round of its own (§12.0, round 267).

**Still in 1.3:**

- **Daily Challenge themes** (phase 6).
- **Blackout. Built the same day** (round 300), and it needed neither the measurement nor a
  twist of its own: `monochromatic` had been promising "all the colour is gone" since round
  229 while only forcing the Classic theme, so the twist was half-built and mis-described
  rather than missing. The filter goes on the scene, which is already an `SKEffectNode`. The
  performance gate turns out to be a question about the **minimum supported device** rather
  than about the twist - the deployment target is iOS 15 and reaches A9 hardware, and raising
  it is a one-line change that is James's to make because it drops players.
- Everything else the August line already carried.

**The minimum is iOS 17** (James, round 301: "go with iOS 17"). It was iOS 15, which reaches
A9 hardware - iPhone 6s and SE - and that device sat behind Blackout's performance gate and
behind every future question of the form "will this hold 60fps on the oldest thing we
support". Raising it retires the class of question rather than one instance of it. It drops
players, which is why it was James's call and not a recommendation acted on. Two dead
availability guards went with it, one of them a deprecated `SKStoreReviewController` fallback
that could no longer be reached and had no business sitting in a binary that goes to App
Review.

Two of the three platform features are therefore out, and the one that stayed - 120fps - was
built in round 123. **iPad multitasking is in, and genuinely so**: James, round 300: "I want
genuine multitasking on the iPad, but the app's ratio must remain the same / near the same."
The play zone has never depended on the window - `GameSceneLayout` holds 1.8236 at any size
and asserts it - so the work is the *menus*, and the `UIRequiresFullScreen` flag that
currently says the app does not do this at all.

**Landscape is allowed on iPad** (James, round 320: "iPad landscape is allowed"), which
reverses the decision below rather than contradicting the code: the app has always rotated,
and what has changed is that it now holds up when it does. The menus cap to a phone's width
and centre on the background, the play zone keeps its 1.8236 ratio and letterboxes, and
`WindowSizeTests` walks an 11-inch landscape window, a 13-inch one and a 900x420 one without
anything falling outside. **The height cap is the open half of this** and is on the §12.0
queue: James, same round, "the iPad UI width limit looks good, but it also needs a height
limit, to match similar to the largest iPhone, or maybe slightly larger."

*The decision as it stood, and why it was right when it was made:*

**Portrait only, and that is the decision rather than the default** (James, round 301: "no
landscape"). Slide Over and Split View on current iPadOS need only that the app resize, which
it now does; the four-orientation requirement belongs to older iPadOS, and meeting it would
mean designing landscape *menus* - the play zone itself would simply letterbox. That is a real
piece of design work for the systems least likely to be running 1.3, so the app stays portrait
and resizable, and older iPadOS simply does not offer the split.

### The 1.3 line, decided (8 August 2026)

Reviewed together against the full open-items lists; recorded here so it is written down
rather than remembered. The play-test queues stay where they live
(ENDLESS-2-SPECIFICATION.md §12.0 and DAILY-CHALLENGE-SPECIFICATION.md's status header) —
this is the release boundary only.

**In 1.3**, on top of everything already landed (Endless Mayhem complete, Daily Challenge
phases 1–3, two wide play-test rounds):

- The §12.0 queue: ring HUD port to Classic/Endless (indicator-only — tray, order and
  geometry unchanged), in-game recents, endless game-over stats, Portal Paddle × Auto-Aim,
  Sticky × Inert, the Big-brick line overlap, new brick geometries, Lock & Key, Double
  Paddle (split-in-two), Ball Spin/Curve, Classic mode menu redesign
- Daily Challenge: a phase-4 twist subset (Time Trial, Mayhem Bricks, Upside Down,
  Mirrored, No Pausing — the rest follow post-release), phase-5 streaks and per-day
  results on the browsing card
- A small Game Center achievement set for the new modes
- The anti-cheat pass: a finished game must never be resumable (live bug), plus a sweep
  of every path that posts to a board
- Giant widget app icon (configurable shortcut), iPad multitasking compatibility,
  Liquid Glass/vibrancy pass over the UI, 120 fps
- The release pass: debug-gate the daily's test clock, App Store review readiness,
  biggest/smallest device matrix (fold the iPad stutter/pixelation checks in)
- Endless mode screens: the run table moves up into the room the Best Height headline
  left, with more clearance above the buttons, a fade where it scrolls under them, and a
  small "N runs" label
- Daily interruption and offline posting (DAILY-CHALLENGE-SPECIFICATION §12.5): a daily
  save slot so an interrupted run resumes, warned-and-unposted past its deadline; and
  pending posts retried until the window closes
- TestFlight for friends and family — James's side, worth doing as soon as the daily
  settles
- James's side: §8.5 art and sound, Quick Start Guide update, and the three App Store
  Connect boards — Endless Mayhem, Daily (recurring, 00:00 UTC), Daily overall
  (classic, all-time; a monthly recurring variant is a cheap 1.4 addition if wanted)

**To 1.4+**: playable tutorial, iPad cursor support, localisation, Mac/AVP,
monetisation decision, the remaining daily twists (Blackout, Always On, Brick Swap,
Mayhem Rules, Landslide), share card, and every future game mode (zen, speed-run,
Classic 2.0, falling-brick, multiplayer, level editor).

**Dropped, agreed**: keychain score encryption (Game Center is the score of record; the
resume fix and posting-path sweep carry the real value), the wholesale MVC/OO refactor
line-items (opportunistic only), the tip-the-creator achievement, and everything already
in the Cut section below.

**Status:** the safe-area rewrite, the monetisation removal, the test target, the audio
session, the Icon Composer migration, the save-game format, the iCloud reset fix and the
logging sweep have all landed. What remains below is marked.

### State of play and build order (9 August 2026, after play-test round 12)

Twelve feedback rounds in, this is the release map: what has landed since the line was
drawn, what remains, and the order proposed for the rest. The queues themselves stay in
the specs (ENDLESS-2 §12.0 and the daily spec's §11.5/§13) - each queued row there
carries its build-from-cold context, and this section only points.

**Landed since the line was drawn (rounds 8-12):** the ring HUD port, in-game recents,
the endless game-over stats (grown through superlatives to labelled rows with More
Stats…), Portal × Auto-Aim, Sticky × Inert, the Wrap-Around paddle straddle, Aimed
Sticky's absolute aim and its last-turn fix, the Big-brick bottom-zone rule, the
lower-limit line's real fix (z-order under the backdrop), the anti-cheat resume rule,
the daily save slot and offline posting (§12.5 complete), the endless mode screens, the
daily briefing's several layout rounds, the gravity settle cadence, the press-only
haptics, and - outside the app - the giga-ball.app website rebuilt for the 1.2
rejection.

**Remaining for 1.3, in proposed build order:**

1. **New brick geometries** - the standing headline, asked for in rounds 10-12
   (§12.0's row). Concave/convex, triangles, 2×1; physics bodies plus row discipline.
2. **The gameplay-feel batch** - Aura rework (single-hit to neighbours, ball still
   bounces), Auto-Aim target choice and direction hint, tap-to-skip for the intro and
   build-in, the build-in animations for Classic and original Endless, fog of war's
   opening reveal (all §12.0 / daily spec rows).
3. **The daily's day pager, properly** — decided in round 14, after the browsing was
   asked about three times. Not another tuning pass: a real horizontal paging
   collection view, one cell per day, per the daily spec's §11.5 entry. Everything that
   drives `viewedOffset` today reroutes through it.
4. **Daily phase 4 and 5** - the twist subset (Time Trial first, then Mayhem Bricks,
   Upside Down, Mirrored, No Pausing), streaks, per-day results on the browsing card,
   and round 12's posted-score container. The free-play rename has landed.
   *Live board stats are backlogged until the App Store Connect boards exist.*
5. **The remaining §12.0 features**, each its own round: Lock & Key; Ball Spin/Curve;
   Double Paddle.
6. **The menu round** - Classic mode menu redesign, the icon pass (settings rows, mode
   menu icons, icons-above-titles everywhere), stats page sections, big-play on every
   pause sub-screen, the game-over score tally for all modes.
7. **Boards and telling people** - the daily's live board stats (backlogged until the
   boards exist), global rank on game-overs,
   daily notifications and their management screen, the Mayhem badge on the power-ups
   page. *Boundary question for James:* the **share card** was placed in 1.4 when the
   line was drawn but re-requested in round 10 - it is specced in the daily spec §11.5
   and ready to build whenever it is called into 1.3.
8. **Platform polish** - small achievement set for the new modes, giant widget icon,
   iPad multitasking, Liquid Glass/vibrancy pass, 120 fps.
9. **The release pass, last** - debug-gate the daily test clock (tracked in the daily
   spec's status header), App Store review readiness, the posting-path anti-cheat
   sweep, biggest/smallest device matrix.

**The idea backlog is now committed to 1.3** (James's call, round 23). It was
"built if a round has room, otherwise 1.4": safety paddle, Drift, Ghost Ball, paddle
surface shapes, Ball Spin/Curve, Double Paddle, the round-11 twist candidates (No
Standard Bricks, Disguise) and the rest of §4's unbuilt twists, special-day levels, ring
glow, and the share card that §11.5 already specifies. They are in §12.0 with their build
notes; nothing is being held back for a 1.4 now.

**What that means for the order.** The art and sound in §8.5 are James's side and are
being made later, so every one of these ships wearing a placeholder that reads correctly -
which is the same bargain the rest of 1.3 is already on. The two things that genuinely
gate a release are unchanged and both belong to James: the Game Center boards clearing
review one per day, and the TestFlight public link. Work that depends on the boards -
the daily's live board stats, global rank on game-overs - waits for them rather than
being built against a board that does not exist yet.

**The website lives in its own repository**, github.com/atmrjames/Giga-Ball-Website,
served by GitHub Pages at giga-ball.app from the branch root. It was drafted in this
repo under `website/` and moved out once it was deployed, so there is one copy rather
than two that can drift — edit it by cloning that repo, not here. Two things about it
are worth remembering, because both cost a rebuild to discover: **Pages serves the
branch root**, so the pages must sit at the top level and not in a folder (the first
deploy 404'd for exactly that reason, which is the fault App Review rejected 1.2 for);
and the `CNAME` file at the root is what holds the custom domain.

**Queued for the site (James's idea, round 73): the soundtrack on the front page.**
Embed the game's music with a call-out that this is an epic game with a soundtrack to
match, retro arcade adventure theme, alongside the SoundCloud link
(`soundcloud.com/user-371123791/sets/giga-ball-original-sound-track`). The audio does
not need downloading from SoundCloud: the four loops ship in the app bundle and are in
this repo already - "Giga-Ball - Title Theme - Loop.mp3", "The Rebound", "The Escape"
and "The Strategy". The Title Theme is the one the front page wants, being what a
player hears first. Autoplay is blocked by every modern browser, so it has to be a
control the visitor presses; keep it small and near the call-out rather than a banner.
Work happens in the website repo, not here.

**James's side, running in parallel:** tick Enforce HTTPS once GitHub finishes issuing
the certificate, then set the two App Store Connect URLs, update the App Privacy
questionnaire (AdMob's declarations are stale) and resubmit 1.2; the domain email;
§8.5 art and sound; the three App Store Connect boards; Quick Start Guide; TestFlight
for friends and family.

### Foundations

#### ✅ Replace the device-class heuristic with safe-area layout
Done. `computeLayoutMetrics()` solves the play area in closed form from `safeAreaInsets`,
holding the ratio at 1.8236. `screenSize` is gone; the two remaining iPad values test
`horizontalSizeClass`. The scene is presented from `viewDidLayoutSubviews`, because insets
are not resolved before the view is in a window.

One item below did **not** get fixed by it: the main menu logo clipped by notification
banners is a UIKit screen, and the rewrite covered the SpriteKit scene only.

The original case, for reference — one rewrite resolves:

- "Work UI around the notch"
- "Power-ups and balls can show through the top bar on non-iPhone X style devices" *(a
  live bug)*
- iPad resizability and `UIRequiresFullScreen` (deprecated; iPadOS 26+ expects resizable)
- "New iPhone size compatibility"
- Prerequisite for any Mac or Vision Pro work

Drive layout from `safeAreaInsets` and the actual scene size, and let the playfield adapt
rather than picking from three hardcoded shapes.

#### ✅ Finish removing the monetisation architecture
Done, and the warning was justified. `checkPremium()` turned out to rewrite all five
unlock arrays to true on every menu refresh, with a second force-unlock hidden in
`GameScene.powerUpIconReset()` — so progression was entirely decorative. Both removed;
pack completion now gates content again, and existing players keep everything because
their arrays were already persisted as all-true.

`adsSetting` went with it: 29 lines across 15 files, branched on nowhere.

The gate-backwards failure happened, exactly as predicted. Three conditions of the form
`premiumSetting! == false && x` were reduced by dropping the always-false term and keeping
the survivor, which turns a dead branch live. The result was a crash on the first tap into
Classic Mode from a clean install. Unit tests were green throughout — it was view-
controller wiring, found only by a clean-install walkthrough.

~~Still open: `premiumTableView` outlets, `IAPTableViewCell.xib` and the `ButtonPremium` /
`iconPremium` assets are unreferenced from Swift but still in Interface Builder.~~ **Gone, and
checked in round 328's release pass:** none of those names appears in any Swift file, the
storyboard, any xib, or the asset catalogue. What is left of the shop is the commented-out
StoreKit code in `MenuViewController` and `InbetweenViewController` and three commented rows in
Settings - inert, but worth knowing about before anyone reads them as a feature.

#### ✅ Add a test target and cover what is testable
Done. `GigaBallTests`, 88 tests, about two seconds.

Two things needed extracting before they could be tested, both now pure types with the
behaviour pinned exactly: `Scoring` (the multiplier was mutated inline at six sites) and
`Progression` (the unlock chain was eleven near-identical blocks inside a `GKState`).

It paid for itself immediately by finding a real bug: the power-up unlock filter iterated
the probability *values* and used them as indices, so locking any power-up above index 10
did nothing. Inert only because everything was force-unlocked — the `premiumSetting`
removal would have switched it on.

Still uncovered: `CloudKitHandler`'s save/load, which needs the key-value store behind a
protocol first. Worth doing with the save-format work.

#### ✅ Audio session off the main thread
`MusicHandler.playMusic()` calls `AVAudioSession.setActive(true)` synchronously from
`MenuViewController.viewDidLoad`. iOS logs it explicitly:

```
SessionCore.mm:631  This method can lead to UI unresponsiveness if called on the
                    main thread while the audio session is active.
```

Move it off the main thread or use the async activation API. While in there:
`AppDelegate` sets the category to `.ambient`, then `MusicHandler` immediately overrides
it to `.soloAmbient` — one is redundant.

#### Harden the force-unwrapping — mostly done
The save/resume path is done: `SavedGame.load` returns nil rather than trapping, and the
resume flag is checked alongside the save itself, so a corrupt save is a lost game in
progress rather than a crash loop. A second round found that `isConsistent` had only
covered the *parallel* arrays — a short `ballProperties` still trapped at index 4 during
resume, and did so twice in testing. Worth remembering that the guard is only as good as
the shapes it actually names. The seventeen settings are non-optional. The 49 live
cell casts (`cellForRow(at:) as! Cell`) are conditional, so highlighting a row and
flicking it offscreen no longer traps.

The count is down from 1508 to 1168, and 162 of what remains are `@IBOutlet`
declarations, where nil is a broken storyboard connection rather than unexpected data.
What is left worth a pass: the remaining 141 `as!` casts and `physicsBody!` in the
scene.

#### ✅ Fix the iCloud data-reset propagation bug
*"Data reset on one device updates on another."* Done in 1.3 via a generation
number (`StatsSync`), incremented on reset and only on reset. The sync merged by
highest-value in both directions, which cannot express a reset — whether the
zeros stuck or the other device's old stats came back depended purely on which
device synced first. A higher generation now means "supersedes", so the sync
adopts or pushes wholesale instead of merging. Devices that have never reset are
all at generation zero and merge exactly as before.

#### ✅ App icon via Icon Composer (blocked on toolchain)
**All thirteen icons are migrated, but they cannot be built by Xcode 26.6** — its `actool`
crashes on the schema the macOS 27 Icon Composer emits. Xcode 27 beta compiles them fine.
So an App Store build needs Xcode 27 GA, or the icons re-authored down to the 26.6 subset.
Deferred until macOS 27 ships. Details in SPECIFICATION.md section 13.

The original plan:
An Icon Composer version of the primary icon already exists. The coloured variants stay —
reauthored as Icon Composer documents so they pick up the current icon styles, including
Liquid Glass, and added as asset-catalog alternate icons rather than the loose PNGs used
today.

That also resolves the Transporter warnings about alternate icons missing at 120×120,
152×152 and 167×167: the current alternates are uniform 256/512/768 PNGs sitting outside
the asset catalog, so no correctly-sized variant exists. A catalog-based set generates
every required size automatically.

*To verify: exact mechanics for using Icon Composer documents as alternate app icons in
Xcode 26.*

#### ✅ Enable crash reporting — verified, nothing to change in the project
The claim that there was nothing to do was correct, and is now checked rather than
assumed. A Release archive was built and inspected:

- `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym`, and the archive does contain
  `dSYMs/Giga-Ball.app.dSYM`
- the dSYM's UUID matches the shipped binary's exactly, which is what symbolication
  actually depends on — a mismatched dSYM is the usual reason Organizer shows
  unsymbolicated frames
- the binary is stripped (`STRIP_INSTALLED_PRODUCT`, `STRIP_STYLE = all`) and the
  symbols survive only in the dSYM, which is the correct arrangement
- `dwarfdump` resolves `computeLayoutMetrics` back to `GameScene.swift` from the dSYM
  alone
- `ENABLE_TESTABILITY = NO` for Release

Also confirmed while there: no SPM or third-party dependencies, `PrivacyInfo.xcprivacy`
is present and ships inside the app bundle, and the scheme is shared so Xcode Cloud can
see it. So no SDK, no privacy-label impact, nothing to add.

What remains is outside the repo: tick "Include symbols" when uploading, and read
Organizer → Crashes. Only users who opted into sharing analytics are represented, which
is worth remembering before concluding a crash is rare.

One thing this did surface: `MARKETING_VERSION` was still `1.2`, so the archive would
have gone up carrying the wrong version. Now `1.3`.

#### ✅ Replace the save-game format
Done in 1.3. `SavedGame` is a versioned `Codable` struct with one-way migration from the
fourteen legacy keys, behind a `KeyValueStore` seam so it can be tested without touching
the host app's defaults. The original problem, for the record:

```swift
saveGameSaveArray = defaults.object(forKey: "saveGameSaveArray") as! [Int]?
```

A parallel `[Int]` array in UserDefaults, force-cast, read at launch while restoring a
saved game. Corruption or a schema change is an unescapable crash, because it happens
during resume. `TotalStats` already uses `Codable` with `PropertyListEncoder` — the save
game simply never adopted it. Move to a versioned `Codable` struct with migration.

Also a prerequisite for "save ongoing game to iCloud" later; syncing parallel int arrays
across devices would be painful.

#### ✅ Housekeeping
- ✅ `print()` calls — all 102 were on failure paths, so they moved to `os.Logger`
  (`Log.swift`) rather than being deleted. See the commit for why stdout was the wrong
  destination for them.
- ✅ `.gitignore` added; the ~4 GB of marketing media stays untracked by choice and
  `xcuserdata` no longer generates churn

---

### Player-visible improvements

**Settled on 25 September 2026 (round 344).** This was the August plan for 1.3, drawn from the
2020 notes, and much of it was built under other names in the rounds that followed while the
list here went unedited. James: whatever was "never built and never cut" goes to 1.4. So this
section now says what became of each line, and everything still open is in **1.4** below.

**Built in 1.3:** the ring timers round the power-up icons; in-game recents on the pause
screen; tables that only scroll when their content needs it, with edge fades; Reduce Motion and
VoiceOver on the menus (round 328); the table selection animation, the short tables and the
sticky bar on resume (the live bugs above); lasers in flight surviving a resume (they are in
the save); the menu redesign, the logo clear of the notifications and the column on an iPad;
Next Level made rarer, Get a Life made rarer until the last ball or two, and a single level
unlocking the next (round 344); the restart option on the Home pop-up (round 330).

**Descoped by James on 2 September:** the multiplier animation at 2.0x and the shadows on the
paddle, ball, bricks, power-ups and lasers. **Removed by James on 8 August:** the play button on
the pack selection view.

---

## 1.3.1

**A bug-fix follow-up, on `release-1.3.1`** (version 1.3.1, branched from 1.3 as submitted). Fixes
only: the features James first listed under 1.3.1 are in 1.4, which his own plan already defines
as bug fixes, refinements and quality of life, and some of them - localisation, accessibility -
are a release's work on their own.

**Fixed (round 400, found by the pre-release soak):**

- A brick flashed on by a paddle hit while Hide Bricks ran, hidden for good if Show Bricks arrived
  or Hide Bricks ended during the flash. Classic, Endless and Mayhem.
- An extra Mayhem ball that stopped dead stayed stopped.

**James's list (20 October 2026):**

- ~~Don't make a sound or animation on the level intro for invisible bricks.~~ **Fixed, round 401.**
- A Portal brick that is inactive after recently being used makes no haptic or sound when hit. It
  should. **Not reproduced (round 401)**: every cooling Portal knocked on the simulator, whatever
  its shape or however it got there. Waiting on which Portal and what had just happened.
- ~~Auto-Aim does not aim at an Indestructible 1 brick even when it is the lowest available brick.
  It should. It should not aim at an Indestructible 2 brick.~~ **Fixed, round 401.**
- ~~The Portal wedge brick has a graphics glitch after a ball goes through it - as if the flipped
  wedge portal brick appears and then disappears.~~ **Fixed, round 401**: the ready pulse turned
  a reflected Wedge's picture the wrong way round.

**James's 1.3 play test (28 October 2026), round 402:** fixed - falling power-ups behind
Directional bricks, the daily board hiding the player's own score, the same daily twice running
(from 1 December, so **1.3.1 must ship by 17 November**), the line on the prism background, Ball
Spin's grip on the Safety Paddle and on Retro's shaped paddles, a big 90s opening for the Time
Trial, and no brick shut away by Indestructible walls in Mayhem. Investigated and waiting on James:
the ball near the paddle's ends (where a fix applies), and details for the Giga-Ball through the
Safety Paddle, the results pop-up timing and the 1,998m score. See ENDLESS-2 round 402.

**Open, from the soak:**

- **Halo can be gone after a resume** (Mayhem): lost in 7 of 40 save-and-resume cycles in a test,
  with the run still in play. Not new in 1.3. See ENDLESS-2 round 400.
- **A brick can be struck in the resumed game's first moment** (the resume soak's most common
  failure, about one seed in twenty, on 1.3 and on round 398's code alike). Not yet known whether it is
  the game or the check.

---

## 1.4

Moved here from the 1.3 plan (James, round 344: "never built and never cut - push these out to
1.4"), alongside what his own lists already put in 1.4: the widget, iCloud game saves, the
daily's notifications and share card, Mayhem Rules in the other modes, and the daily's
"a newer version exists" flag (build it before the first pool addition, not after).

- **Accessibility, the rest of it.** Dynamic Type on stats, settings and items; a colour-blind
  overlay, since brick type is still carried by colour alone; an assist mode (slower ball,
  wider paddle, optional no-life-loss), which shares its plumbing with a speed-run mode.
- **Texture atlases.** Still none; every sprite is its own draw call. Also the likeliest shared
  cause of the iPad stutter and pixelation reports.
- **Liquid Glass across the rest of the UI.** The round buttons wear it; the in-app icons,
  standard controls and cell backgrounds do not.
- **Dark and light mode.**
- **A Game Center button on the achievement detail page.**
- **A points breakdown** for the level and life bonuses.
- **An image on the share sheet.**
- **Drop the "m" from endless heights**, in the app and in the Game Center achievements - James's
  2020 note, never decided. Mayhem was built with the "m", so this is a question now as well as
  a change.
- **The live bugs never reproduced:** the paddle growing after a resume from pause (a candidate
  cause was fixed and never confirmed); textures parting from the paddle when it is slammed
  into the frame; iPad stutter and pixelation; a ball hitting the paddle straight after the
  backstop; low-speed bounce gliding.
- **The slow and fast ball power-ups reaching the other timers and the drop rate** - see
  "Power-up interactions" below for why they were deferred.

**James's definition (20 October 2026):** "No major new game modes, functions or changes. Bug
fixes, refinements, optimisations, QoL features." His notes for it, as he wrote them:

*Moved from his 1.3.1 list:*

- Themed backstops.
- Sort achievements on the info view by percentage complete (pairs with round 399's percentage
  in the tick's corner).
- A power-up that takes all the bricks on screen and mixes up their positions randomly.
- A Brick Swap power-up that swaps brick types around.
- Independent volume sliders for music and sounds.
- Localisation.
- iPad and Mac cursor support: hover to move the paddle, and the cursor morphing into buttons on
  hover.
- Keyboard support: arrow keys to move the paddle.
- Check Mac compatibility; check Vision Pro compatibility (see "Mac and Vision Pro" below).
- An accessibility focus: how many items on Apple's accessibility checklist can be covered.
- Custom brick design layouts for Endless Mayhem phases, rows and sections.
- New Classic Mode pack(s), with new power-ups such as one that resets the level to its starting
  condition. New packs, so the existing eleven and their scores are untouched.

*Descoped from 1.3:*

- Game backgrounds: scrolling (`EndlessMayhemBackdrop`), and the Grid background scaled to the
  marker grid, which needs the artwork's pitch measured and pairs with the background art.
- Liquid Glass round the game mode icons instead of the olive circles.
- A new main menu background graphic behind the blur.
- A small ball-and-paddle graphic on the launch splash that animates in with the glow and the
  logo's emboss and settles into the app icon, above the Giga-Ball logo (also in ENDLESS-2
  §12.0's backlog).
- Animations around the app; the glowing light theme carried through graphics, sounds and
  animations; SF Symbols wherever possible.
- A playable tutorial on first start, and from the info menus.
- An animated loading graphic on the resume splash screen.
- An option to play the next pack from Classic's pack complete screen.
- The multiplier label animating as it reaches 2.0.
- The Giga-Ball logo or title somewhere on the game scene.
- Subtle shadows or glows behind the ball, bricks, power-ups, lasers, paddle and power-up icons.
- Updated Game Center achievement and leaderboard images.
- A giant widget app icon whose action the player sets in settings - a shortcut to a menu or a
  game mode.
- A better animation when the ball hits a level's last brick, and a ball animation at the end of
  a level.
- A tidier animation when a ball is lost and the new ball goes to the paddle.
- An icon for each daily challenge including its theme, paddle, ball and background.
- A swoosh between the ball and paddle on the theme icons.
- A score breakdown: tap the score at the end of a level or game to see where the points came
  from and how they were worked out.

#### Power-up interactions — deferred, and why
Two of three requested interactions between the ball-speed power-ups and everything else
are **not built**. The third is: slow ball makes lasers fire faster, fast ball slower
(slow ball is the good one, which is the opposite of what the names suggest).

- **Slow ball should make good power-ups drain slower and bad ones faster; fast ball the
  reverse.** Every timed power-up runs a keyed `SKAction`, and a running action's `speed` can
  be changed - but the save reconstructs remaining time as `duration × iconBar.xScale`, and an
  action whose speed has changed is no longer on wall-clock time, so a resume would restore the
  wrong times. It needs the timers to record real elapsed time first.
- **Slow ball should slow the power-up drop rate, fast ball raise it.** Small in itself, and
  left with the item above.

Green power-ups are the good ones and award points; red ones deduct.

---

## 1.5 and beyond

**James's plan (20 October 2026):** "1.5 - Zen mode, multiplayer mode, speed runner mode." Every
one of them a new mode with its own leaderboards, so nothing existing is touched. His notes:

- **Speed runners.** Pack time leaderboards, separate for time and score with power-ups off; an
  option to turn power-ups on or off, with non-power-up leaderboards; an option to turn level
  intro screens off completely, and other things that help a speed run; best time per pack on
  Game Center.
- **Zen / forever mode.** Power-ups on or off, and each one available, unavailable or always on
  (with the stage chosen for staged ones like paddle size); choose which bricks, styles, shapes
  and movements can appear, at least one; a softer, slower soundtrack and sounds; no Game Center
  or score board, the score logged in the game.
- **Multiplayer, pong style, bricks in the middle.** First to get their ball past the other wins;
  first to 10 goals. Each player has their own ball, in their own colour, which reappears on their
  paddle after a goal. Bricks in the middle to break before scoring, some reappearing after each
  goal, a new row on each side after a goal, and bricks in each player's colour that their own ball
  passes over. A time limit on the sticky paddle. Multiplayer power-ups: move bricks closer to the
  opponent, power-ups collected applied to the opponent, a backstop. Lasers can rebound the
  opponent's ball, in each player's colour. Unlockable paddle and ball designs in home and away
  colours. An own goal takes a goal off, never below nought. Local multiplayer on iPad, and play
  against the computer. Open: can the two balls touch?
- **Classic Mode 2.0**, with the new bricks and power-ups.
- **A continuously falling brick mode** until you crash, like Tetris, starting at the top row.
- **User level creation.** Place bricks, pick their types and colours and paint them in, choose
  the power-ups available and how often; a cloud library of user levels and packs with ranking,
  sorting and shuffle.
- **A simplified widescreen mode** for Apple TV, Mac, Vision Pro, a foldable iPhone and CarPlay,
  shown when the view is wide enough, with widescreen levels in landscape on iPad and iPhone.
  The fixed play-zone ratio is the constraint here: a widescreen mode is a new mode with its own
  zone, not the existing zone reshaped.
- **Foldable iPhone compatibility**, and **a Watch game mode**.

**Since built, in 1.3:** the second endless mode (Endless Mayhem), the new power-ups and brick
types listed below, the daily challenge, and themed game backgrounds. The rest of the list below
is as written in August.

Substantial but coherent — each is a release theme in its own right.

- **A second endless mode, alongside the existing one.** The current mode is renamed —
  "Endless Mode Classic" or similar — and left completely untouched so its global
  leaderboards stay valid. The new mode gets its own leaderboards and carries the rework:
  difficulty curve (sparser start, brick types introduced earlier, density ramping
  later), more breather sections, invisible bricks earlier, height zones, a height scale
  graphic, gravity bricks, new brick types and power-ups.
- **New level packs using the new mechanics.** The eleven existing packs stay frozen so
  their scores remain comparable. Everything new ships as new packs. Much cheaper once
  level data lives outside code.
- **Endless mode session history.** A table of previous sessions, most recent first,
  showing height, play time and date. Sortable by height or play time.

  Cheaper than it looks: `TotalStats` already records `endlessModeHeight: [Int]` and
  `endlessModeHeightDate: [Date]` — every session's height and date, already synced via
  iCloud. Only per-session play time is missing; `playTimeSecs` is a lifetime total.
  So the screen is mostly presentation over data that already exists, plus one new field
  recorded going forward. Existing players would see full history with play time blank
  for past sessions.

  Worth noting these are parallel arrays, so this feature pairs naturally with moving
  the save format to a versioned `Codable` struct.
- **New power-ups.** The timed good/bad lists are strong: magnetism, ball wrap, portal
  paddle, landing marker, wrecking ball, aura, opposite input, erratic bounce. Build
  after the power-up system is decomposed out of `GameScene`.
- **New brick types.** Directional, moving, rotating, flashing, colour-changing,
  falling, tap-to-destroy.
- **Themes and customisation.** Ball trails, ball designs, backgrounds, themed
  backstops, retro power-ups, theme-matched power-up styles.
- **Level packs.** Music, maths symbols, seasonal (Halloween, Christmas, Easter,
  anniversary).
- **Speed-running mode.** Power-ups off, separate time leaderboards, skippable level
  intros. Self-contained and well suited to the existing leaderboard structure.
- **Move level data out of code.** The 110 levels are 110 Swift files totalling 10,566
  lines compiled into the binary, and all of it is data. Moving to JSON or plist cuts
  build time, makes a local level editor dramatically cheaper (the editor writes the
  format the game already reads), makes seasonal packs trivial, and enables level
  validation tests — every level solvable, no orphaned bricks, sane brick counts. Best
  done after the test target exists.
- **Daily challenge.** One level from a date seed, identical for everyone, single
  attempt, daily leaderboard. Endless mode already generates random layouts, so most of
  the machinery exists. A retention hook that needs no notifications.
- **Save in-progress games to iCloud.**
- **120 fps on ProMotion devices.**
- **Localisation.**
- **Widget** (start mode, high score) and **iMessage stickers**.
- **Playable tutorial.**
- **Shuffle and quick-play modes**, 1-life mode, point-and-shoot mode.
- **Game Center**: challenges, new achievements, refreshed artwork, uploading historical
  best scores.
- **iPad cursor support** — hover to move the paddle, click to fire.

---

## Needs a decision before it can be planned

### Monetisation — deferred, low priority
**Still on James's list (20 October 2026) as "option to tip the creator".** A tip is an in-app
purchase, so it would end "no ads and no in-app purchases", which is how 1.3 is described on the
App Store and in James's launch post, and bring back StoreKit code 1.3 removed. Not for the next release. "Option to tip the creator" means reintroducing StoreKit, which
is a reasonable eventual choice, but nothing should be built that depends on it until the
model is decided. Several older notes assume a premium tier that no longer exists and are
dead as written.

### Mac and Vision Pro — later, but high priority within that
Wanted, and a genuinely appealing direction. "Add compatibility" hides a large fork:

- **Designed for iPad** — near-zero work, ships the iPad build as-is, controls unchanged
- **Mac Catalyst** — real work; a touch-driven paddle needs a mouse/keyboard control
  scheme, plus window resizing, menus, and a separate App Store presence
- **visionOS native** — a different interaction model entirely

The cheap option is genuinely viable for a game like this and worth trying first. All of
them depend on the safe-area work in 1.3, and all must preserve the fixed play-zone ratio.

### A Daily Challenge mini pack
James (20 October 2026): a daily format of three random Classic levels, three spare balls, highest
score wins, the twists still applying (perhaps not Time Trial). A new daily format scores
differently from the existing daily, so it needs leaderboards of its own, and a decision on how it
sits beside the one-level daily: instead of it on some days, or as a second challenge each day.

### Understanding player drop-off without collecting data
Do **not** add an analytics SDK — it would cost the "Data Not Collected" privacy label
just earned. Game Center achievement completion rates and App Store Connect's built-in
metrics require no SDK and no privacy declaration. If most players never finish Classic
Pack, that is a design signal already available and currently unread.

### Specification document
Worth doing, but scope it. A full spec for a 5,600-line game that grew organically is an
enormous document. More valuable: specify the **target architecture** and capture the
rules currently implicit in `GameScene` — collision handling, power-up lifecycles,
scoring, endless-mode progression. That doubles as the test plan.

---

## Cut

Removed with reasons, so these don't quietly reappear.

### Obsolete — the premise no longer exists
- "Add Giga-Ball premium full screen ad for when AdMob ad fails" — no ads, no premium
- "Option to tip after upgrading — only show if on Giga-Ball premium" — no premium tier
- "2 new power-ups… unlocked with IAP" — no IAP (the power-ups themselves are still
  worth building; the unlock mechanism is not)
- "URL for App Store Server Notifications to check refund status" — no purchases
- "Remove cocoapods" — the project has never used CocoaPods

### Already done
- Remove IAP, ads, non-premium code *(completed in 1.3, including `premiumSetting`
  and `adsSetting`)*
- Update app and about-view version and build numbers
- Remove social media links
- New iPhone size compatibility *(as far as scene adoption goes; the layout rewrite in
  1.3 completes it)*

### Self-marked won't-fix, and correctly so
- Endless mode move-down breaking when paused mid-move — genuinely unlikely
- Solving the indestructible brick bounce by brick position — would remove the
  randomness that makes bounces feel right

### Cut on cost/benefit
- **Multiplayer pong mode.** The most developed idea in the notes, and effectively a
  second game: netcode or local multiplayer, matchmaking, new power-ups, new art, its
  own balance problem. Months of work. If it's wanted, it deserves its own project, not
  a backlog line.
- **User-created levels with a cloud library and ranking.** Needs a backend, moderation,
  abuse handling and ongoing running costs. A purely local level editor is a fraction of
  the work and most of the fun — worth reconsidering in that reduced form.
- **Apple Watch app.** A reflex game on a 40 mm screen driven by the Digital Crown.
  High effort, low likely engagement.
- **China App Store approval.** Requires a local agent, a gaming licence and a Software
  Copyright Certificate. A business project, not an engineering task.
- **"Remove coloured icon variants."** Contradicts the customisation plans elsewhere in
  the notes and the 12 alternate icons already shipping. Stale.

---

## Verified, no action needed

- Power-up probabilities are at production values, byte-identical to the last shipped
  commit.
- No debug, cheat or unlock overrides anywhere in the project.
- The `com.apple.accounts Code=7` message on launch is benign; Game Center authenticates.
- Transporter's missing-icon warnings are pre-existing since July 2020 and non-blocking.
