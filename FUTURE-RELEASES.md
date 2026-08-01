# Future release backlog

Items deliberately deferred during the 1.2 (81) compatibility work. None of these
block shipping 1.2 — they are improvements, not defects, unless noted.

## Performance

### Audio session activation blocks the main thread
`MusicHandler.playMusic()` calls `AVAudioSession.sharedInstance().setActive(true)`
synchronously, and is invoked from `MenuViewController.viewDidLoad` on the main thread.
Activating a session can block for tens of milliseconds while the audio route is
established, so this sits directly in the launch path. iOS logs it explicitly:

```
SessionCore.mm:631  This method can lead to UI unresponsiveness if called on the
                    main thread while the audio session is active.
```

Fix: move session setup off the main thread, or adopt the async activate/deactivate API.

While in there: `AppDelegate` sets the category to `.ambient`, then `MusicHandler`
immediately overrides it to `.soloAmbient`. One of the two is redundant.

## iPad

### Not resizable, and the layout does not use the screen
`UIRequiresFullScreen` is still `true`. It is deprecated, and iPadOS 26+ expects apps
built against the current SDK to be resizable. The app currently runs full screen and
plays correctly, so this is not yet breaking — but it is on borrowed time.

The larger problem is design rather than configuration: the SpriteKit playfield and every
storyboard layout assume a fixed portrait aspect ratio, so the iPad renders a centred
phone-width column with empty bands either side. Making the game genuinely resizable is a
design project, not a plist change.

## Code health

### `premiumSetting` gating architecture
Roughly 40 references across 12 files gate level, pack and item unlocks on a flag that is
now unconditionally set to `true` by `MenuViewController.checkPremium()`. Dead weight, but
removing it is a behavioural refactor: getting one gate backwards silently locks content
for real users. Worth doing carefully, with the unlock paths tested.

### Pervasive force-unwrapping
Optionals are force-unwrapped throughout the view controllers (`premiumSetting!`,
`gameToResume!`, `saveGameSaveArray!` and many more). Any unexpected state is a crash
rather than a degradation. This is the single largest source of fragility in the codebase.

### `GameScene.swift` is ~5,600 lines
Difficult to reason about or change safely. Candidate for decomposition along the lines
already suggested by the `GameScene Extensions` folder.

### 117 `print()` calls
Harmless in Release, but noise. Worth a sweep.

## Repository

### No `.gitignore`
About 4 GB of marketing media, audio sources and graphics sit untracked in the repo root.
Nothing pulls them in today, but a stray `git add -A` would commit all of it. Xcode user
state (`xcuserdata`) is also tracked and generates churn on every commit.

## Verified, no action needed

- Power-up probabilities are at production values, byte-identical to the last shipped commit.
- No debug, cheat or unlock overrides anywhere in the project.
- The `com.apple.accounts Code=7` message on launch is benign; Game Center authenticates
  correctly.
