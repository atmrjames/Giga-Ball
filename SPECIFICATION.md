# Giga-Ball — application specification

**What this is:** a description of how the app works *as it currently stands*, written to
be self-contained. It exists so a reader with no prior context — a new conversation, or
you in six months — can understand the app without reading 5,600 lines of `GameScene`.

**What this is not:** a design document or a wish list. Planned work lives in
[FUTURE-RELEASES.md](FUTURE-RELEASES.md). Where current behaviour is awkward, that is
recorded here as fact, not as a proposal.

Current version 1.2 (August 2026). Bundle ID `com.atmrjames.Megaball`, product name
`Giga-Ball`, Apple ID `1494628204`.

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

There is **no test target**, no dependency manager, and no analytics or crash-reporting
SDK.

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
  View Controllers/            All UIKit screens
  Custom Cells/                Table and collection view cells with .xib files
  CloudKitHandler.swift        iCloud sync via key-value store
  GameCenterHandler.swift      Leaderboard submission
  MusicHandler.swift           Background music
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

---

## 4. Gameplay mechanics

**Playfield.** A 22 × 11 brick grid. The play zone holds a **fixed aspect ratio on every
device** — deliberately, so the game plays identically across a player's devices. On iPad
and wider screens this produces vertical borders either side rather than a stretched
field.

**Paddle.** Dragged horizontally by touch. Sensitivity is a user setting (three levels)
controlling the ratio of finger movement to paddle movement. The paddle cannot pass the
side walls.

**Ball.** Launched from the paddle by tapping. Bounce angle off the paddle depends on
where it strikes, giving the player directional control. A minimum speed is enforced to
prevent the ball settling into a flat, unwinnable path.

**Lives.** Three in Classic, one in Endless. Losing the ball resets the multiplier to
1.0, clears active power-ups, and returns the ball to the paddle. Losing the last life
ends the run.

**Scoring.** Everything is multiplied by the current multiplier at the moment it is
awarded:

| Event | Base value |
|---|---|
| Brick destroyed | 10 |
| Level completed | 100 |
| Timer bonus | starts at 500, reduced by time taken, floored at 0 |
| Point power-ups | ±100, ±1000 |

Brick score is flat regardless of colour or type — colour is decorative and used for
save/restore indexing, not scoring.

The **multiplier** rises by 0.1 per brick destroyed, caps at **2.0**, and resets to 1.0
whenever a ball is lost. It is displayed as `x1.0` … `x2.0`. Because the timer bonus is
also multiplied, finishing a level quickly while holding a high multiplier is worth
considerably more than the brick score alone.

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
distinction, which matters for colour-blind players.

---

## 6. Power-ups

Bricks may drop a falling power-up, caught with the paddle. There are **28**, a mix of
beneficial and harmful, some instant and some timed:

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

*(Note: `premiumSetting` still gates unlock logic across 12 files, but is unconditionally
forced true on every menu refresh, so everything is effectively unlocked. It is dead
weight from the removed in-app purchase.)*

---

## 8. Screens

```
Splash (animated logo, tap to skip)
  └─ Main Menu ─────── Classic Mode ── Pack Select ── Level Select ── Level Detail
     │                                                                   └─ Game
     ├─────────────── Endless Mode ── Endless Detail ── Game
     ├─ Info (i) ──── Items / Stats / Items Detail / Item Stats / About
     └─ Settings ──── (also reachable from the pause menu)

Game ─┬─ Pause Menu (pause, game over, pack complete — one screen, three modes)
      ├─ Between Levels (level intro and level results)
      └─ Warning (confirmations: reset data, single-level play, first pause)

Intro / onboarding: 5 pages, shown on first launch only
```

Screens are presented by adding child view controllers and their views as subviews, not
by navigation controller pushes or modal presentation. The pause menu, between-levels
screen and warnings are all overlays added onto the game view controller.

**Stats** are tracked extensively — per level, per pack and lifetime — covering scores,
times, completions, balls lost, power-ups collected and generated, and playtime.

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

**The saved-game format is the fragile part.** It is a set of parallel arrays read with a
force-cast (`as! [Int]?`) at launch while restoring. Any corruption or schema change is an
unrecoverable crash during resume.

A game is saved automatically when a level ends, when the app backgrounds, and when the
scene disconnects. Resuming restores the level, score, lives, brick layout and active
power-ups.

---

## 10. Game Center

- **74 leaderboards**: 61 per-level boards, 11 per-pack boards, plus total score, best
  endless height and total endless height. (Best endless height appears in both the level
  and global lists, hence 74 unique rather than 75.)
- **41 achievements**, covering pack completions, score thresholds, level counts, speed
  runs, no-ball-lost runs, power-up usage and endless height milestones.
- Submission happens at the end of every level and game, and when opening stats screens.
  It is guarded on the player being authenticated.
- Leaderboards are opened directly to the relevant board from level and pack screens.

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

Things a newcomer would otherwise have to discover the hard way.

**Layout is a device-class guess, not safe areas.** `GameScene` computes an aspect ratio
and sorts every device into one of three buckets — `"X"`, `"Pad"`, `"8"` — then branches
on that string in six places. There is **no `safeAreaInsets` usage anywhere in the
project**. This is why the main menu logo is clipped by notification banners and why
power-ups can bleed through the top bar.

**`GameScene.swift` is ~5,600 lines** and holds nearly all gameplay logic, UI wiring and
persistence calls.

**Force-unwrapping is pervasive.** Settings and saved-game values are read as `x!`
throughout. Unexpected state crashes rather than degrades.

**Levels are code, not data.** 110 Swift files, ~10,500 lines, compiled into the binary.
Each is a function that assigns textures across the grid.

**`premiumSetting` is vestigial** but still threaded through the unlock paths.

**`UIRequiresFullScreen` is still true**, so the app does not participate in iPadOS
multitasking. Deprecated but currently honoured.

**Audio session activation is synchronous on the main thread** during launch, which iOS
logs a warning about.

**Notification-driven flow.** Because most screen transitions are notifications rather
than direct calls, tracing "what happens when X finishes" means searching for the
notification name, not following a call stack.

---

## 13. Build and release

- Built and archived via **Xcode Cloud** (workflow on branch `finalBranch`), because the
  local Mac runs a beta macOS which caused App Store validation to reject locally-built
  binaries with ITMS-90111.
- Xcode Cloud assigns its own build numbers; `CFBundleVersion` cannot be overridden from
  a pre-build script.
- Signing is automatic, team `ZAGZPD36YG`.
- `ExportOptions.plist` in the repo supports local command-line archiving if needed.
- The app declares a privacy manifest (`PrivacyInfo.xcprivacy`) covering `UserDefaults`
  access, and collects no data.
