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

So: **1.3 should be a foundations release.** Little of it is user-visible, but it makes
1.4 onwards tractable.

---

## 1.3 — Foundations

**Status:** the safe-area rewrite, the monetisation removal, the test target, the audio
session and the Icon Composer migration have all landed. What remains below is marked.

### ✅ Replace the device-class heuristic with safe-area layout
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

### ✅ Finish removing the monetisation architecture
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

Still open: `premiumTableView` outlets, `IAPTableViewCell.xib` and the `ButtonPremium` /
`iconPremium` assets are unreferenced from Swift but still in Interface Builder.

### ✅ Add a test target and cover what is testable
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

### ✅ Audio session off the main thread
`MusicHandler.playMusic()` calls `AVAudioSession.setActive(true)` synchronously from
`MenuViewController.viewDidLoad`. iOS logs it explicitly:

```
SessionCore.mm:631  This method can lead to UI unresponsiveness if called on the
                    main thread while the audio session is active.
```

Move it off the main thread or use the async activation API. While in there:
`AppDelegate` sets the category to `.ambient`, then `MusicHandler` immediately overrides
it to `.soloAmbient` — one is redundant.

### Harden the force-unwrapping
Optionals are force-unwrapped throughout the view controllers (`premiumSetting!`,
`gameToResume!`, `saveGameSaveArray!`). Any unexpected state is a crash rather than a
degradation. Prioritise the save/resume path, where a corrupt or partial save currently
means a crash loop on launch.

### ✅ Fix the iCloud data-reset propagation bug
*"Data reset on one device updates on another."* Done in 1.3 via a generation
number (`StatsSync`), incremented on reset and only on reset. The sync merged by
highest-value in both directions, which cannot express a reset — whether the
zeros stuck or the other device's old stats came back depended purely on which
device synced first. A higher generation now means "supersedes", so the sync
adopts or pushes wholesale instead of merging. Devices that have never reset are
all at generation zero and merge exactly as before.

### ✅ App icon via Icon Composer (blocked on toolchain)
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

### Enable crash reporting — nothing to change in the project
`DEBUG_INFORMATION_FORMAT` is already `dwarf-with-dsym` for Release, so dSYMs ship. This is
an Organizer / App Store Connect check rather than work in the repo.
Xcode Organizer, no SDK, no third-party code, no impact on the "Data Not Collected"
privacy label. Given how much force-unwrapping the codebase contains, this is the
difference between fixing the crashes that actually happen and guessing. Should land
before, or alongside, the hardening work so the data starts accumulating.

### Replace the save-game format
The most likely crash in the app:

```swift
saveGameSaveArray = defaults.object(forKey: "saveGameSaveArray") as! [Int]?
```

A parallel `[Int]` array in UserDefaults, force-cast, read at launch while restoring a
saved game. Corruption or a schema change is an unescapable crash, because it happens
during resume. `TotalStats` already uses `Codable` with `PropertyListEncoder` — the save
game simply never adopted it. Move to a versioned `Codable` struct with migration.

Also a prerequisite for "save ongoing game to iCloud" later; syncing parallel int arrays
across devices would be painful.

### Housekeeping — still open
- 117 `print()` calls — sweep them
- Add a `.gitignore`; ~4 GB of marketing media sits untracked in the repo root, and
  `xcuserdata` is tracked and generates churn

---

## 1.4 — Player-visible improvements

Cheap to build once 1.3 lands, and the things players will actually notice.

### Accessibility
There is currently not a single accessibility API in the project. The first three are
nearly free:

- **Reduce Motion.** Parallax is applied on essentially every view, plus blur and
  animated transitions, and `isReduceMotionEnabled` is never consulted.
- **Dynamic Type** on stats, settings and items — all fixed fonts today.
- **VoiceOver on the menus.** Gameplay cannot reasonably be made VoiceOver-playable;
  everything around it can.
- **Colour-blindness.** Brick *type* is encoded purely in colour — multi-hit,
  indestructible, inert. Players who can't distinguish them face an unfair game rather
  than a harder one. An optional pattern or symbol overlay fixes it.
- **Assist mode** — slower ball, wider paddle, optional no-life-loss. Doubles as
  accessibility, widens the audience, and shares its difficulty-options plumbing with
  speed-run mode.

### Texture atlases
There are no atlases in the project at all, so every sprite is its own draw call.
Batching via `.spriteatlas` is the standard SpriteKit optimisation and is a plausible
shared cause of two known issues listed separately: iPad stuttering and iPad graphics
looking pixelated.

### Live bugs worth fixing
- Table view selection animation appears on the wrong cell. Noted back in 2020 and
  confirmed still present in August 2026
- Table views in the menus stop short of the screen edge rather than filling it. Assess
  during the 1.3 safe-area work rather than fixing separately — it is probably the same
  fixed-layout cause
- Sticky paddle icon bar not filling correctly when resuming
- Paddle grows after resuming from pause; sticky texture behaves, paddle does not
- Ball and paddle textures move independently when the paddle is slammed into the frame
  (iPhone X-style devices) — likely the same root cause as being able to nudge the ball
  while it rests on the paddle
- Ball stuttering on iPad, and iPad graphics looking pixelated — probably the same
  underlying scale/texture issue, worth investigating together
- Lasers in play are removed when returning from a saved game
- Ball can hit the paddle after hitting the backstop
- Floating-point precision on physics bodies; ball speed below ~150 px/s causes bounce
  gliding

### Liquid Glass across the rest of the UI
The app icons adopted Icon Composer and Liquid Glass in 1.3. The interface has not.

- In-app icons updated to Liquid Glass versions
- UI elements adopt standard system controls and Liquid Glass rather than the current
  custom-drawn styling
- Menu items and table view cell backgrounds adopt Liquid Glass materials

Sits naturally alongside menu modernisation, and after the safe-area work for the same
reason: restyling components on top of a layout that is about to be rewritten means
doing it twice.

### Menu modernisation
Best done *after* the 1.3 safe-area work, not before — several of these are symptoms of
the current fixed layout, and redesigning around a broken foundation wastes the effort.

- Bring the menus up to current design language
- **The Giga-Ball logo on the main menu is clipped by incoming notifications.** It sits
  too close to the top with no safe-area awareness, so banners overlap it. Moving it down
  is the immediate fix; respecting the safe area is the real one
- Reposition content to make use of larger screens rather than centring a phone-sized
  column
- Game modes become squares or boxes rather than full-width rows
- Streamline the level and pack selection menus

### UI
- Power-up timing bars become circles around the power-up icons
- Only show timed power-up icons while actually in use; fade in and out
- Show active power-ups in the pause menu
- Table views only scroll when content exceeds the view
- Animate the multiplier label at 2.0×
- Show the points calculation for level and life bonuses
- Dark and light mode
- Shadows on paddle, ball, bricks, power-ups and lasers
- Add an image to the share sheet

### Gameplay
- Single level completion unlocks the next level even without a pack score (plus the
  intro and warning text changes that go with it)
- Add a play button to the pack selection view
- Reduce the likelihood of the "next level" power-up
- Drop the "m" suffix in endless mode (also needs changing in Game Center achievements)
- Button to reach Game Center achievements from the achievement detail view
- Restart option in the return-home menu

---

## 1.5 and beyond

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
Not for the next release. "Option to tip the creator" means reintroducing StoreKit, which
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
