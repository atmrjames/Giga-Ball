# Giga-Ball — release planning

Triaged backlog, consolidating notes from 2020–2021 with items identified during the
1.2 (81) compatibility work in August 2026.

Organised by **when**, not by category, because the sequencing matters more than the
grouping. Rationale is recorded so decisions can be revisited rather than re-argued.

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

### Replace the device-class heuristic with safe-area layout
The highest-leverage change on this list. One rewrite resolves:

- "Work UI around the notch"
- "Power-ups and balls can show through the top bar on non-iPhone X style devices" *(a
  live bug)*
- iPad resizability and `UIRequiresFullScreen` (deprecated; iPadOS 26+ expects resizable)
- "New iPhone size compatibility"
- Prerequisite for any Mac or Vision Pro work

Drive layout from `safeAreaInsets` and the actual scene size, and let the playfield adapt
rather than picking from three hardcoded shapes.

### Finish removing the monetisation architecture
`premiumSetting` across 12 files, plus the leftover `adsSetting`. Everything is free and
`checkPremium()` forces the flag true on every menu refresh, so the gates are decorative —
but removing them is a behavioural refactor. Test the unlock paths: one gate backwards
silently locks content for real users.

### Add a test target and cover what is testable
There is no test target at all. Start where the value is highest and the coupling lowest:
`LevelPackSetup`, `TotalStats`, `TotalScore`, scoring and multiplier maths, power-up
allocation probabilities, and `CloudKitHandler` serialisation. Physics and rendering can
wait; the data model cannot.

### Audio session off the main thread
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

### Fix the iCloud data-reset propagation bug
*"Data reset on one device updates on another."* This is the closest thing to a
data-loss bug on the list and should not wait. Needs a sync tracker so a local reset
isn't replayed onto other devices as authoritative.

### App icon via Icon Composer
Also resolves the Transporter warnings about alternate icons missing at 120×120,
152×152 and 167×167 — the current alternates are uniform 256/512/768 PNGs outside the
asset catalog. Moving them into proper asset-catalog alternate icon sets fixes the
warnings and the sizing in one pass.

### Housekeeping
- 117 `print()` calls — sweep them
- Add a `.gitignore`; ~4 GB of marketing media sits untracked in the repo root, and
  `xcuserdata` is tracked and generates churn

---

## 1.4 — Player-visible improvements

Cheap to build once 1.3 lands, and the things players will actually notice.

### Live bugs worth fixing
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

- **Endless mode rework.** Difficulty curve (sparser start, brick types introduced
  earlier, density ramping later), more breather sections, invisible bricks earlier,
  height zones, a height scale graphic, gravity bricks.
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

### Monetisation
The IAP and ads are gone and the app is entirely free. "Option to tip the creator" means
reintroducing StoreKit — a reasonable choice, but decide the model before building
anything that depends on it. Several older notes assume a premium tier that no longer
exists and are dead as written.

### Mac and Vision Pro
"Add compatibility" hides a large fork:

- **Designed for iPad** — near-zero work, ships the iPad build as-is, controls unchanged
- **Mac Catalyst** — real work; a touch-driven paddle needs a mouse/keyboard control
  scheme, plus window resizing, menus, and a separate App Store presence
- **visionOS native** — a different interaction model entirely

The cheap option is genuinely viable for a game like this and worth trying first. All of
them depend on the safe-area work in 1.3.

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
- Remove IAP, ads, non-premium code *(all but the `premiumSetting` gating, in 1.3)*
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
