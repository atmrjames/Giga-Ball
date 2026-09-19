# Giga-Ball — application specification

**What this is:** a description of how the app works *as it currently stands*, written to
be self-contained. It exists so a reader with no prior context — a new conversation, or
you in six months — can understand the app without reading 5,600 lines of `GameScene`.

**What this is not:** a design document or a wish list. Planned work lives in
[FUTURE-RELEASES.md](FUTURE-RELEASES.md). Where current behaviour is awkward, that is
recorded here as fact, not as a proposal.

Current version 1.2 (August 2026), with 1.3 in progress on `release-1.3`. Bundle ID
`com.atmrjames.Megaball`, product name `Giga-Ball`, Apple ID `1494628204`.

---

## 1. What the app is

Giga-Ball is a single-player Breakout / Arkanoid game for iPhone and iPad. The player
moves a paddle horizontally to keep a ball in play, destroying a grid of bricks above.
Destroyed bricks may drop power-ups. There are two modes: a **Classic Mode** of 110
hand-designed levels across 11 themed packs, and an **Endless Mode** where rows descend
indefinitely and the goal is height.

It is free, with no advertising, no in-app purchases and no data collection. Progress
syncs across the player's devices via iCloud, and scores post to Game Center.

---

## 2. Technical shape

| | |
|---|---|
| Language | Swift, no third-party dependencies |
| Gameplay | SpriteKit, with the built-in Box2D physics via `SKPhysicsBody` |
| UI shell | UIKit, one storyboard (`Main.storyboard`), programmatic container hierarchy |
| State machine | GameplayKit `GKStateMachine` |
| Minimum iOS | 15.0 |
| Devices | iPhone and iPad, **portrait only** |
| Lifecycle | UIScene (`SceneDelegate` builds the window from the storyboard) |
| Persistence | `UserDefaults`, a `Codable` plist in Documents, `NSUbiquitousKeyValueStore` |
| Services | Game Center (leaderboards, achievements), CloudKit (availability check only) |

There is no dependency manager and no analytics or crash-reporting SDK.

`GigaBallTests` is a host-app unit test bundle covering the data model — `LevelPackSetup`
array alignment, `TotalStats` coding, `Scoring`, `Progression`, power-up allocation and
the starting unlock state. It runs in about two seconds. Physics, rendering and the view
controllers are not covered; neither is `CloudKitHandler`'s save/load, which reads and
writes the `UserDefaults` and key-value-store singletons with no seam to inject a double.

### Project layout

```
Megaball/
  AppDelegate.swift            App lifecycle, iCloud KVS observer
  SceneDelegate.swift          Window construction, scene lifecycle
  GameScene.swift              ~5,600 lines. The entire game.
  GameScene Extensions/
    Levels/                    110 levels as Swift functions, one file each
    BrickCreation/             Grid building, endless rows, resume restore
    PowerUpAllocation.swift    Per-level power-up probability tables
  Game States/                 GKState subclasses (see below)
  Data Model/
    LevelPackSetup.swift       Static content: pack names, level names, power-up
                               names, achievement names, themes, icons, leaderboard IDs
    TotalStats.swift           The persisted stats model
    TotalScore.swift
    Scoring.swift              Score and multiplier rules, pure
    Progression.swift          What completing a pack unlocks, pure
  View Controllers/            All UIKit screens
  Custom Cells/                Table and collection view cells with .xib files
  CloudKitHandler.swift        iCloud sync via key-value store
  GameCenterHandler.swift      Leaderboard submission
  MusicHandler.swift           Background music
GigaBallTests/                 Unit tests for the data model
```

### Game state machine

`GameScene` owns a `GKStateMachine` with five states:

| State | Responsibility |
|---|---|
| `PreGame` | Sets up a level: resets score, lives, multiplier; builds the brick grid |
| `Playing` | Active gameplay. Also restores a saved game if one exists |
| `Paused` | Pause menu shown; scene paused |
| `InbetweenLevels` | End of a life-set or level: tears down the scene, saves, reports to Game Center, then shows the appropriate end-of-level screen |
| `GameOver` | Returns to the main menu |

**`InbetweenLevels` is the funnel for every game and level ending.** It saves, then calls
`showEndOfLevelView()`, which routes to one of three screens:

- endless mode, or lives exhausted → pause menu in "Game Over" mode
- last level of a pack → pause menu in "Complete" mode
- otherwise → the between-levels screen, which advances to the next level

It then waits for a `.continueToNextLevel` or `.restart` notification from that screen.
*(This routing previously lived inside the ad-display function; when ads were removed in
1.2 it was deleted with them, which made every game hang. Worth knowing, because the
coupling is not obvious.)*

### Communication

The scene talks to the view controller layer through `GameViewControllerDelegate`
(`moveToMainMenu`, `showPauseMenu`, `showInbetweenView`, `showWarning`). Nearly
everything else — returning from menus, resuming, pausing, syncing — flows through
`NotificationCenter` with named notifications. There is no formal architecture beyond
this; view controllers read and write `UserDefaults` directly.

---

## 3. Game modes

### Classic Mode

11 packs of 10 levels each. Level numbers are global and contiguous:

| Pack | Levels | Pack | Levels |
|---|---|---|---|
| Classic | 1–10 | Body | 61–70 |
| Space | 11–20 | World | 71–80 |
| Nature | 21–30 | Emoji | 81–90 |
| City | 31–40 | Numbers | 91–100 |
| Food | 41–50 | Challenge | 101–110 |
| Computer | 51–60 | | |

Level 0 is the tutorial, level 999 is endless mode's generated field.

A player can play a **whole pack** from the start, or a **single level** in isolation.
Single-level play does not unlock content — the app warns about this before starting.

The player starts with **3 lives** per pack run. Score and multiplier carry across levels
within a run.

### Endless Mode

One life. Rows of bricks descend from the top; the score is **height in metres**, shown
in place of the score. The brick field is generated rather than hand-designed, growing in
density and introducing brick types as height increases. Ending the run is final — there
is no continue.

Endless has its own leaderboards (best height, total height) and its own achievements.

### Endless Mayhem (Endless 2.0 in the code)

The same shape as Endless — one life, height in metres, a generated field — with variety as
the point rather than escalation. It is a separate mode with its own leaderboards and
achievements, because its scores are not comparable with the original's.

What it adds, in full in [ENDLESS-2-SPECIFICATION.md](ENDLESS-2-SPECIFICATION.md):

- **A brick is a behaviour, a style and a size**, independently. The five behaviours are the
  ones the game has always had; the ten styles (rounded, spinning, flashing, fixed, gravity,
  moving, directional, exploding, spawner, portal) and the sizes Tiny and Big are new, and a
  brick may carry two styles where they do not contradict.
- **Power-up bricks.** A power-up built into the field rather than falling out of it, set off
  by breaking it, never cleared by reaching the bottom.
- **Multi-Ball**, up to four balls; the run continues while any is in play.
- **Clusters and set rows** — designed shapes dropped into an otherwise generated field.
- **Phases**, stretches of 5–25m with their own character.
- **The ring HUD**, showing only active power-ups with their timers around the icon.
- **Height markers** every 100m with the row left empty for them, and unlabelled ticks every
  10m.

Everything is additive: no existing brick, power-up or level behaves differently because
Endless 2.0 exists.

---

## 4. Gameplay mechanics

**Playfield.** A 22 × 11 brick grid. The play zone holds a **fixed aspect ratio on every
device** - deliberately, so the game plays identically across a player's devices. On iPad
and wider screens this produces vertical borders either side rather than a stretched
field. `GameSceneLayout` solves for the height first and spends whatever width is left on
the borders, so the field is always as tall as the window allows and is never cropped; the
scene is presented `aspectFit` for the same reason.

**And the menus are a phone's menus, centred** (round 314). Their content is capped both by
shape - `menuMaximumAspectRatio` - and by an absolute `menuMaximumWidth`, whichever is
narrower, so a 13-inch iPad shows a phone-width column on a large background rather than a
phone-width layout stretched across one. **Since round 322 the height is capped too**, at an
absolute `menuMaximumHeight` of 1000 points (James, round 320: "it also needs a height limit.
to match similar to the largest iPhone, or maybe slightly larger"). Round 180 had capped the
height by shape and round 181 removed it for leaving 40% of the screen empty with two level
packs scrolled out of sight; an absolute cap a little over a Pro Max's 956 gives an iPad
exactly the scrolling a Pro Max has, which is the look asked for, and touches no phone.

**Paddle.** Dragged horizontally by touch. Sensitivity is a user setting (three levels)
controlling the ratio of finger movement to paddle movement. The paddle cannot pass the
side walls.

**Ball.** Launched from the paddle by tapping. Bounce angle off the paddle depends on
where it strikes, giving the player directional control. A minimum speed is enforced to
prevent the ball settling into a flat, unwinnable path.

**Lives.** Three in Classic, one in Endless. Losing the ball resets the multiplier to
1.0, clears active power-ups, and returns the ball to the paddle. Losing the last life
ends the run.

**Scoring.** The rules live in `Scoring` and are covered by tests.

| Event | Base value | Multiplied? |
|---|---|---|
| Brick destroyed | 10 | yes |
| Level completed | 100 | **no** |
| Timer bonus | starts at 500, less one point per second taken, floored at 0 | yes |
| Point power-ups | ±100, ±1000 | yes |

Brick score is flat regardless of colour or type — colour is decorative and used for
save/restore indexing, not scoring. Awards truncate toward zero rather than rounding, so
a half point is always lost.

The **multiplier** starts at 1.0, caps at **2.0**, and resets to 1.0 whenever a ball is
lost. It is displayed as `x1.0` … `x2.0`. Because the timer bonus is multiplied,
finishing a level quickly while holding a high multiplier is worth considerably more than
the brick score alone.

Three details are easy to get wrong and are pinned by tests:

- It rises **once per twenty bricks destroyed**, not once per brick.
- Level completion is the one award that is *not* multiplied.
- There are three paths that move it — bricks, bonuses and power-ups — and they do not
  agree. The brick path steps only while below the cap and does not snap to it, so ten
  steps from 1.0 land on 1.9999999999999998 rather than 2.0. The other two snap exactly.
  The drift is invisible (the label formats to one decimal place, and the cap test is
  `>=`) but a brick-driven 2.0 and a bonus-driven 2.0 are different numbers. Unifying
  them would change scores, so it is a deliberate decision rather than a tidy-up.

---

## 5. Brick types

Bricks are `SKSpriteNode`s whose type is determined by texture. Levels are authored by
assigning textures across the grid.

| Type | Behaviour |
|---|---|
| Null | Empty cell. No brick present |
| Normal | Destroyed in one hit. Carries a colour, which affects its score |
| Multi-hit | Four stages; each hit steps it down until destroyed |
| Indestructible | Two variants. Cannot be destroyed by a normal ball; cleared only by the Zap power-up or Giga-Ball |
| Invisible | Present and solid but not drawn until struck |

Brick *type* is conveyed entirely by colour and texture — there is no shape or symbol
distinction, which matters for colour-blind players. Endless 2.0's styles are the exception:
each carries a glyph as well as a colour, deliberately, so it can be read without relying on
either.

A **Bricks** page in the information menu documents all of it — behaviours with every state
they pass through, styles, and sizes — with its compatibility lines derived from the code
rather than written out.

---

## 6. Power-ups

Bricks may drop a falling power-up, caught with the paddle. Classic and Endless have
**28**, a mix of beneficial and harmful, some instant and some timed:

```
Extra Ball          Lose A Ball         Slow Ball           Fast Ball
Expand Paddle       Shrink Paddle       Sticky Paddle       Gravity Field
+100 Points         -100 Points         +1000 Points        -1000 Points
Max Multiplier      Reset Multiplier    Complete Level      Show Bricks
Hide Bricks         Clear Multi-Hit     Reset Multi-Hit     Zap Indestructible
Giga-Ball           Inert Ball          Lasers              Quicksand
Mystery             Backstop            Expand Ball         Shrink Ball
```

Timed power-ups show an icon with a depleting bar in the tray beneath the HUD.

**Endless Mayhem adds 23 more**, listed in ENDLESS-2-SPECIFICATION.md §5.4, bringing the
game to 51. They are additive and mode-locked: `powerUpNameArray` is the original 28
followed by Mayhem's, `LevelPackSetup.firstEndlessIIPowerUp` is where the line falls, and
the drop probabilities are only ever set for the first 28 in Classic and Endless. That
ordering is not a convention anyone is free to change - the save file, the iCloud key-value
store and the drop table all count in it.

**Allocation.** `PowerUpAllocation.swift` holds a probability weight per power-up, with a
default table overridden per level. A `powerUpProbFactor` (default 10) scales the overall
drop rate. Weights adapt during play — for example, the chance of an extra life rises as
the player's lives fall.

---

## 7. Progression and unlocks

Completing a pack unlocks the next **theme** and **app icon**. There are 12 of each,
gated in a fixed order:

| Themes | Classic, 3D, Ice, Outline, Square, Glass, Pixel, Split, Candy Cane, Glow, Rainbow, Retro |
|---|---|
| **App icons** | Purple, White, Yellow, Outline, Orange, Green, Blue, Black, Pink, Glow, Rainbow, Retro |

Themes change the appearance of the ball, paddle and bricks; each is selectable
independently. App icons use the iOS alternate-icon mechanism.

**What a new player starts with.** Classic, Space and Nature, plus endless mode and the
tutorial. The first level of each starting pack. The Classic theme, the Purple icon, and
14 of the 28 power-ups.

**What completing a pack grants.** The reward table lives in `Progression` and is applied
by `InbetweenLevels`: the next theme, the next app icon, two power-ups for the first seven
packs, the pack-completion achievement, and the next pack. Finishing a level unlocks the
next level in the same pack.

**City is gated differently.** The first three packs can be played in any order, so no
single completion knows it was the last. City opens once all three have a recorded best
time. Between the starting state and the reward table, every theme, icon, power-up and
pack is accounted for exactly once — asserted by `ProgressionTests`.

*(Until 1.3, `premiumSetting` made all of this decorative: `checkPremium()` rewrote all
five unlock arrays to true on every menu refresh, and a second force-unlock in
`GameScene.powerUpIconReset()` opened eight power-ups. Both are gone. Players who ran an
earlier build keep everything, because their arrays were already persisted as all-true.)*

---

## 8. Screens

```
Splash (animated logo, tap to skip)
  └─ Main Menu ─────── Classic Mode ── Pack Select ── Level Select ── Level Detail
     │                                                                   └─ Game
     ├─────────────── Endless Mode ── Endless Detail ── Game
     ├─────────────── Endless Mayhem ─ Endless Detail ── Game
     ├─ Info (i) ──── Items / Stats / Items Detail / Item Stats / Bricks / About
     └─ Settings ──── (also reachable from the pause menu)

Game ─┬─ Pause Menu (pause, game over, pack complete — one screen, three modes)
      ├─ Between Levels (level intro and level results)
      └─ Warning (confirmations: reset data, single-level play, first pause)

Intro / onboarding: 5 pages, shown on first launch only
```

Screens are presented by adding child view controllers and their views as subviews, not
by navigation controller pushes or modal presentation. The pause menu, between-levels
screen and warnings are all overlays added onto the game view controller.

Because there is no navigation controller, the swipes that come with one had to be written:
a swipe from the left edge goes back, doing exactly what that screen's back button does, and
a swipe from the right edge returns to the screen just come back from. Opening anything new
discards the way forward, the way a push discards what a pop left behind. It is one screen
deep — the menus are shallow, and a screen swiped away several steps ago is not one anybody
remembers wanting back. See `MenuNavigation`.

**Stats** are tracked extensively — per level, per pack and lifetime — covering scores,
times, completions, balls lost, power-ups collected and generated, and playtime. The
statistics screen shows them in five tabbed sections: Overall, plus one per mode, with
thousands separators in the reader's own locale. Nothing in the *scene* is grouped — a
score that gains and loses a separator as it crosses a thousand is movement where the eye
is already watching, and the HUD draws its digits on a fixed pitch for exactly that reason. What
each section holds is decided by where the game writes the number, not by hand — see
`StatsPage`, which turns a `TotalStats` into rows away from the screen that draws them.

**Reference pages.** Power-Ups, Bricks and Achievements share one detail screen
(`ItemsStatsViewController`): icon, name, description, then a table of facts. A power-up
that only exists in Endless Mayhem is marked in the list and says so on its own page.

**Pack Select** is a grid of square cells, three across, under the mode's name and logo —
the same treatment the two endless menus wear, so the three mode menus read as a set.
Tapping a cell plays the pack; the list mark in its top-left corner opens the pack's level
list instead. The logo shrinks as the grid scrolls, giving the room back to the cells.

---

## 9. Data and persistence

Four separate mechanisms, which is more than ideal:

| What | Where | Format |
|---|---|---|
| Settings | `UserDefaults` | Individual keys (`soundsSetting`, `ballSetting`, …) |
| Lifetime stats | `Documents/totalStatsStore.plist` | `TotalStats` via `PropertyListEncoder` |
| Saved game | `UserDefaults` | **Parallel arrays**, e.g. `saveGameSaveArray: [Int]` |
| Cross-device sync | `NSUbiquitousKeyValueStore` | Key-by-key mirror of the above |

**CloudKit is used only to check account availability** — the actual sync is the
key-value store. `CloudKitHandler` reads `ubiquityIdentityToken` first and treats a nil
token as "iCloud unavailable", because touching `CKContainer` without the entitlement
raises an uncatchable exception.

**The saved-game format is the fragile part, and it is guarded now.** It was a set of
parallel arrays read with a force-cast at launch, where any corruption was a crash loop.
`SavedGame` is a versioned `Codable` value that checks its own arrays agree
(`isConsistent`) and reads as no save rather than trapping; the old format is migrated once.
New fields are optional so older saves still decode.

**When a game is saved** (corrected in round 322b - this said "when the app backgrounds, and
when the scene disconnects", and nothing listens for either): on every pause, including the
one leaving the app triggers from play (`sceneWillResignActive` posts the pause); on reaching
the between-levels screen, after the level is banked; every ten metres of an endless run; and
as a ball is lost. Resuming restores the level, score, lives, brick layout, falling and active
power-ups, and returns the run paused - or, for a run left on the between-levels screen, to
that screen, whose Continue starts the next level. `ResumeTransitionTests` drives both.

---

## 10. Game Center

- **74 leaderboards**: 61 per-level boards, 11 per-pack boards, plus total score, best
  endless height and total endless height. (Best endless height appears in both the level
  and global lists, hence 74 unique rather than 75.)
- **41 achievements**, covering pack completions, score thresholds, level counts, speed
  runs, no-ball-lost runs, power-up usage and endless height milestones.
- Submission happens at the end of every level and game, and when opening stats screens.
  It is guarded on the player being authenticated. **The per-level boards are the exception:
  they exist and nothing has posted to them for years**, so anything reading a standing uses
  the boards that are kept current - each pack's total and each endless mode's best height.
- Leaderboards are opened directly to the relevant board from level and pack screens.
- The game-over screen names where the run stands: "3rd / 1,204 on the Classic Pack board",
  asked once as the screen goes up (`GameCenterHandler.loadRank`) against the board
  `GameMode.runLeaderboard(packNumber:)` chooses. Silent when there is no board or no answer:
  signed out, offline, or Single Level Mode. **Endless Mayhem is no longer one of those** -
  James had its boards approved on 21 August 2026, and this line went on saying they did not
  exist.

Game Center can be disabled in settings.

---

## 11. Settings

| Setting | Values |
|---|---|
| Sounds | on / off |
| Music | on / off |
| Haptics | on / off |
| Parallax | on / off (tilt-based motion effect on menu backgrounds) |
| Paddle sensitivity | 3 levels |
| Game Center | on / off |
| Ball / Paddle / Brick theme | 1 of 12 each, subject to unlocks |
| App icon | 1 of 12, subject to unlocks |
| Stats collapse | display preference on stats screens |
| Reset data | destructive, confirmed via warning screen |

---

## 12. Known constraints and quirks

**Ball physics rules that apply to every mode.** These were fixed together and are easy to
undo by accident:

- A wall or ceiling bounce reflects the velocity the ball *arrived* with, sampled before the
  physics step — not the one reported by the contact, which the engine has already turned
  round. Reflecting that a second time is what sent the ball back into the surface it had just
  left, and is why it used to run along the top of the screen.
- Two or more bricks struck in the same step are treated as **one surface**, so a ball landing
  on the seam between adjacent bricks leaves off the flat face rather than off a corner.
- The ball may travel vertically, but never horizontally — a horizontal ball never comes back.
  It is pushed off horizontal by the minimum angle plus a small random amount, so no two
  escapes are identical and it cannot settle into a loop.
- **The paddle is not solid from below.** While a ball is under it the paddle is not in the
  way, so a Backstop can actually return a ball that got past.


Things a newcomer would otherwise have to discover the hard way.

**Layout is measured, not guessed.** `computeLayoutMetrics()` solves the play area in
closed form from `safeAreaInsets` and the scene bounds, holding the play ratio at a fixed
1.8236 on every device. The scene is presented from `viewDidLayoutSubviews` rather than
`viewDidLoad`, because the insets are not resolved until the view is in a window. The old
three-way device-class string is gone; the two remaining iPad-specific values test
`horizontalSizeClass == .regular`.

The main menu logo being clipped by notification banners is *not* fixed — it is a UIKit
screen, and the safe-area work covered the SpriteKit scene only.

**`GameScene.swift` is ~5,600 lines** and holds nearly all gameplay logic, UI wiring and
persistence calls.

**Force-unwrapping is pervasive.** Settings and saved-game values are read as `x!`
throughout. Unexpected state crashes rather than degrades.

**Dead promo UI remains in Interface Builder.** `premiumTableView` outlets,
`IAPTableViewCell.xib` and the `ButtonPremium` / `iconPremium` assets are no longer
referenced from Swift but still exist in the storyboard and xibs. The promo table's cell
identifier is not registered, so showing it traps in `dequeueReusableCell` — it is
collapsed unconditionally.

**Levels are code, not data.** 110 Swift files, ~10,500 lines, compiled into the binary.
Each is a function that assigns textures across the grid.

~~**`UIRequiresFullScreen` is still true**, so the app does not participate in iPadOS
multitasking. Deprecated but currently honoured.~~ **Neither half of that is true** (checked
round 314). The key is not in `Info.plist` and not in the build settings either, so it is
absent rather than true - and iPadOS 26 ignores it in any case, which is how James came to be
playing in a window he could drag into any shape. Rounds 313f-h and 314a are the layout work
that followed from it: the scene letterboxes rather than crops, and the menus cap their
content to a phone's width and centre it. **The app participates in iPadOS multitasking**,
and has to be laid out as though it does.

**Audio session activation is synchronous on the main thread** during launch, which iOS
logs a warning about.

**Notification-driven flow.** Because most screen transitions are notifications rather
than direct calls, tracing "what happens when X finishes" means searching for the
notification name, not following a call stack.

---

## 13. Build and release

- Built and archived via **Xcode Cloud**, because the local Mac runs a beta macOS which
  caused App Store validation to reject locally-built binaries with ITMS-90111. 1.2 shipped
  from a workflow on `finalBranch`; 1.3 is on `release-1.3`.
- **The Icon Composer icons cannot be built by Xcode 26.6.** All thirteen `.icon`
  documents were authored by the Icon Composer that ships with macOS 27, and use schema
  keys — `features`, group `specular` and `lighting`, layer `fill-specializations` and
  `blend-mode` — that 26.6's `actool` cannot parse. It does not error, it crashes:

  ```
  error: Exception while running actool: *** -[__NSPlaceholderArray initWithObjects:count:]:
         attempt to insert nil object from objects[0]
  ```

  Reproducible with `actool` alone; the trigger is `--output-partial-info-plist`, which
  every real build passes. Xcode 27 beta compiles them. So local builds must use the beta
  toolchain, and an App Store build needs either Xcode 27 GA or the icons re-authored down
  to the 26.6 subset. Deferred until macOS 27 ships.
- **TestFlight readiness, checked 14 September 2026 (round 324b)**, the night before the first
  1.3 TestFlight build. macOS on this Mac is 27.0 (26A428, no beta suffix); the Xcode 27 here
  is still a beta (27A5228h), so a local upload would be rejected and the route is Xcode Cloud
  with the Xcode 27 RC selected in the workflow. What was checked so that build does not fail
  on something the Debug test runs cannot see:
  - A **Release** build for a generic iOS device succeeds, with one warning (App Intents
    metadata skipped - the app has no App Intents). The product carries
    `PrivacyInfo.xcprivacy`, the Icon Composer app icon compiled into `Assets.car`, and
    version 1.3 (83).
  - `ITSAppUsesNonExemptEncryption` is `false`, so builds are not held for export compliance.
  - No ad SDK is linked (no Google Mobile Ads in the project, code or plists), which is what
    makes the manifest's "no data collected, no tracking" true. The App Privacy answers in App
    Store Connect were recorded as stale from the AdMob days and are worth re-checking against
    that before external testers.
  - The only required-reason API used is `UserDefaults`, declared with reason `CA92.1`; no
    file-timestamp, boot-time, disk-space or active-keyboard APIs appear in the code.
  - Everything behind `#if DEBUG` is diagnostics or the daily's test clock, which reads 0 in
    Release, so a Release build loses nothing a player sees.
  - ~~`release-1.3` on GitHub was last pushed on 16 August (round 159) and the local branch is
    256 commits ahead, so Xcode Cloud builds nothing current until it is pushed.~~ **Pushed on
    14 September** (round 324c), and Xcode Cloud built from it: **1.3 has been on TestFlight for
    internal testers since 19 September** (James). Local commits after that push still have to
    be pushed before Xcode Cloud sees them - `git status -sb` says how many.
- **For external testers** (round 328's check, against what App Store Connect asks for):
  - **Test Information** has to be filled in once - beta description, feedback email, and a
    **privacy policy URL**, which external testing requires. `https://giga-ball.app/privacy`
    exists and says what the app does: no ads, no analytics, no tracking, no accounts, and
    iCloud and Game Center only. That matches `PrivacyInfo.xcprivacy` and the linked SDKs.
  - **The first build of a version goes to Beta App Review**; later builds of 1.3 usually do
    not. A public link can be turned on per group once approved.
  - **The App Privacy answers on the app's product page** are the one thing recorded as stale,
    from the AdMob days. The app collects nothing now, so they should read Data Not Collected -
    and beta review can compare the two.
- Xcode Cloud assigns its own build numbers; `CFBundleVersion` cannot be overridden from
  a pre-build script.
- Signing is automatic, team `ZAGZPD36YG`.
- `ExportOptions.plist` in the repo supports local command-line archiving if needed.
- The app declares a privacy manifest (`PrivacyInfo.xcprivacy`) covering `UserDefaults`
  access, and collects no data.
