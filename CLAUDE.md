# Working on Giga-Ball

An iOS SpriteKit brick-breaker, shipping since 2020. Two documents describe it:
[SPECIFICATION.md](SPECIFICATION.md) is the app **as it stands**;
[ENDLESS-2-SPECIFICATION.md](ENDLESS-2-SPECIFICATION.md) is the design and build log for
Endless Mayhem (`endlessII` in code) and tracks what is built in §12.0. Read the relevant one before changing anything — both carry
sections written specifically to stop mistakes being repeated.

## Two constraints that never bend

- **The play zone keeps a fixed 1.8236 aspect ratio on every device.** The game must play
  identically across a player's devices. `GameSceneLayout` owns this and asserts it.
- **Existing progress and Game Center leaderboards stay valid.** New mechanics ship as new
  packs and modes; nothing is retrofitted into existing ones. People hold years of scores.

## Build and test

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project Megaball.xcodeproj -scheme Megaball \
  -destination 'id=6C4F510D-FAC7-42B0-98CE-258809ABA4B7' test > run.log 2>&1
```

That is the iPhone 16 Pro on iOS 18.5, **the destination that works as of 25 September 2026**:
the iOS 27 runtimes here (24A5390f, 24A434) still do not match Xcode-beta's simulator SDK
(24A5390e), which is the hang described below. **Send the output to a file and read the file**
(`grep -c "' passed "`, then `Failing tests:` and `error: -[`), and run a full suite in the
background: piping `xcodebuild` straight into `grep` has hung twice.

- Local builds need `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`. Xcode
  26.6's `actool` **crashes** on the Icon Composer assets — see SPECIFICATION.md §13.
- Anything destined for the App Store is built by **Xcode Cloud on `release-1.3`**, because
  Apple rejects beta-toolchain uploads and this Mac runs a beta macOS.
- **`xcodebuild test` does not always relink the app.** Round 62 compiled a changed file,
  passed 761 tests, installed, and showed the *old* UI on the simulator: the `.o` was ten
  minutes newer than `Giga-Ball.debug.dylib`, which had never been rebuilt. A green suite is
  not evidence that the app bundle you are about to install contains your change. Worse, the
  next round the incremental build reported `BUILD SUCCEEDED` having compiled **nothing** -
  the build system's dependency state had stopped noticing edited files entirely, and only
  `xcodebuild clean` shifted it. Before believing a simulator screenshot, check the product:
  `nm -a .../Giga-Ball.app/Giga-Ball.debug.dylib | grep <a symbol you just added>`. Note the
  app's code is in that dylib, not in the 40KB `Giga-Ball` executable beside it. It has now
  happened three rounds running, so treat it as the norm: **`clean` before any build you
  intend to install and look at.** Two rounds of play-test feedback were answered against a
  binary that did not contain the answer.
- **Target the simulator by UDID, not by name.** There are two devices called `iPhone 17 Pro`
  on this Mac, and `-destination 'platform=iOS Simulator,name=iPhone 17 Pro'` is ambiguous
  between them: a suite that normally runs in 9 seconds started relaunching the app once per
  test, ~28s each, and never finished. `-destination 'id=EE6E3FF7-990D-482F-A92A-50CB2ADF6A81'`
  is the booted one and behaves.
- **If the suite starts relaunching the app every few tests, check the audio server.**
  Round 118 lost two hours to it: `Restarting after unexpected exit, crash, or test timeout`
  after roughly every fourth test, no failing assertion, crashes spread across unrelated
  classes. The crash report's triggered thread is the giveaway - `SKSoundContext init` ->
  OpenAL -> `AURemoteIO::Initialize` -> `_ReportRPCTimeout` -> `abort`. SpriteKit opens an
  audio context on launch and aborts when the host's audio server does not answer, so *every
  launch* dies and the harness keeps relaunching. It is not the destination-ambiguity trap
  below and not the code: a freshly booted device on a different runtime does it too, and
  `simctl shutdown`/`boot` and restarting `CoreSimulatorService` do not clear it. The fix is
  on the Mac - a reboot, or `sudo killall coreaudiod` - so it needs James. Until then,
  `-only-testing:` a few classes still works, because fewer launches means fewer chances to
  hit it.
- **If a build hangs before compiling anything, check the simulator runtime's build number.**
  Round 300 lost an afternoon to it. `xcodebuild` sat at `PruneExplicitPrecompiledModules`
  with **zero** `swift-frontend` processes, forever, and survived `xcodebuild clean`, a wiped
  `ModuleCache.noindex`, a killed `XCBBuildService`, and a completely fresh
  `-derivedDataPath`. The cause is a mismatch: Xcode-beta's simulator SDK is
  **24A5390e** and the installed iOS 27.0 runtime had updated to **24A5390f**. Compare
  `xcrun simctl list runtimes` against the build number in
  `DerivedData/SDKStatCaches.noindex/*.sdkstatcache` - if they differ, that is it, and
  clearing the cache does not help because xcodebuild regenerates it at the SDK's number.
  The fix is James's: update Xcode-beta, or reinstall the matching runtime. **The workaround
  is another runtime** - `-destination 'id=6C4F510D-FAC7-42B0-98CE-258809ABA4B7'` is an
  iPhone 16 Pro on iOS 18.5 and builds and tests normally. `SWIFT_ENABLE_EXPLICIT_MODULES=NO`
  gets the *compile* through and still hangs at the end, so it looks like progress and is not.
  The tell that separates this from every other build problem: it never compiles a single
  file, and the same command worked earlier the same day.

- **If the whole suite is slow, it is the app's launch reaching outside the process.** The app
  starts three external services on launch and a simulator has none of them, so each one waits
  for a timeout - **on every batch, because every batch launches the app**. The symptom is a
  batch that appears to **hang after its last test has already passed**, which sends you
  looking at the harness instead of the app. Round 306 found and guarded all three behind
  `GameCenterHandler.isRunningTests`:
  - **Game Center authentication**, the worst by far, at **30 to 207 seconds per launch**. The
    tell is already in the suite's own log: `grep "Authentication failed for player in"` and
    read the seconds.
  - **`NSUbiquitousKeyValueStore.synchronize()`** in `AppDelegate`, a main-thread call into a
    key-value store with no iCloud account behind it.
  - **The audio session**, which wants a server that may not answer - the same trap the audio
    note above describes, met at launch rather than in a crash report.

  A three-class batch went from minutes to **45 seconds including its build**. Nothing under
  test wants any of the three: no test asserts on Game Center, iCloud sync or audio, so the fix
  is not to start them. It is a runtime check rather than `#if DEBUG`, because the question is
  "am I being tested", not "is this a debug build" - James plays debug builds every round and
  they must behave exactly as the shipped one does.

- **A milder version of that relaunch trap looks like a failing test with no assertion.**
  Round 302 hit it three times in one night on iOS 18.5, across three unrelated classes
  (`EndlessIIBrickTests`, `EndlessIIDensityStepTests`, and a batch of frame-cost tests). The
  signature: `xcodebuild` prints **`Restarting after unexpected exit, crash, or test timeout;
  summary will include totals from previous launches`**, the batch ends `** TEST FAILED **` and
  names a test under `Failing tests:` that **never printed a `passed` or `failed` line and never
  failed an assertion** - and the same summary can say `Executed 59 tests, with 0 failures`,
  because the totals come from the relaunched run. **Every one of those classes passes when run
  alone.** Unlike round 118 there were *no* crash reports in `~/Library/Logs/DiagnosticReports`
  or `~/Library/Logs/CoreSimulator`, and it was rare - three in roughly 5,500 test executions -
  rather than every fourth test.
  So: a named failing test with no assertion behind it is not a failure, it is this. Re-run
  that class alone before believing it, and do not go looking for the bug in the code it names.
  Adding an app-side guard is not the answer - round 118 established the fix is on the Mac.

  **Round 313: it is no longer rare.** Four full-suite runs in one session, four of these -
  `EndlessIILockAndKeyTests`, `EndlessIISquareBrickArtTests`, then
  `EndlessIIStickyPaddleQueueTests` twice - one per run, each preceded by exactly one
  `Restarting after unexpected exit`, each passing on its own immediately afterwards. The
  totals still say `0 failures`, and the count they report (848) is the relaunched run's
  alone rather than the ~1,145 that actually executed, so **read the `Failing tests:` list
  and the relaunch count, not the total**. CoreAudio was complaining in the same logs
  (`HALC_ProxyIOContext::IOWorkLoop: skipping cycle due to overload`), which points back at
  round 118's diagnosis, so the remedy is still James's: a reboot, or `sudo killall
  coreaudiod`.
  **Round 313: he ran it, and it helped without curing it.** The reported total went from
  around 870 to **1,059** - far more of the suite now survives into the final launch - and the
  run still ended with exactly one relaunch and one named test, the first of
  `EndlessIIPowerUpBrickCountTests`, which passed alone straight afterwards. So `killall
  coreaudiod` is worth doing and is not the whole answer: treat one relaunch per full run as
  the current normal, read the `Failing tests:` list rather than the total, and re-run the
  named class alone before believing it.
  **Round 313, a full clean run after that: the gap between the total and the truth is much
  wider than it looks.** 2,244 tests executed with **not one assertion failure** anywhere in
  the log, one relaunch, and the summary still said `** TEST FAILED **` with
  `Executed 883 tests` - so the reported total was under **40%** of what actually ran. The
  named test was `EndlessIIStickyPaddleQueueTests.testAnExtraBallIsCaughtRatherThanBounced()`,
  which printed neither `passed` nor `failed`, and its class ran 12 of 12 alone in eight
  seconds immediately afterwards. The CoreAudio errors are right above the relaunch in the log
  (`AQMEIO.cpp:379 error -66680 finding/initializing`, `HALDefaultDevice.cpp:742 Could not
  find default device`), which is the same signature round 118 diagnosed. So: **count the
  `passed` lines** - `grep -c "' passed "` - rather than reading the summary's total, because
  the summary is counting one launch and the suite ran across two.
  **Round 314: sometimes two relaunches rather than one**, so "one per full run" is a typical
  value and not a rule - two full runs that day each relaunched twice, and each of the four was
  immediately preceded in the log by the same CoreAudio burst (`AQMEIO.cpp:379 error -66680`),
  which is round 118's signature and confirms that diagnosis rather than adding to it. Every
  named class passed alone. What this changes is the expectation only: read the `Failing
  tests:` list and re-run whatever it names, however many there are, rather than going looking
  for a second cause the moment the count is not one.

- **Stale derived data has twice hidden a new file from the test target**, producing "cannot
  find X in scope" for code that builds fine in the app. If a brand-new file's symbols are
  missing from tests, `xcodebuild clean` before believing the error.

- **The simulator plays no sound on this Mac.** Both the suite and a normal launch log
  `SKAction: Error loading sound resource` for every file, though every file is in the bundle.
  It is the host's audio server, the same one the relaunch notes above describe, and not the
  app: James's devices play all of them. Do not go looking for a missing file.

- **Two measuring tools live in `tools/`.** `crap.py` scores untested complexity from a
  coverage run (`-enableCodeCoverage YES -resultBundlePath run.xcresult`); `mutate.py` puts one
  small bug at a time into a file and runs that file's tests to see whether they notice. Both
  explain themselves in their headers. They were rebuilt in round 345 because the first ones
  lived in a session's scratch directory and were lost with it.

## Adding a file

There is no file-system-synchronised group; `Megaball.xcodeproj/project.pbxproj` is
hand-edited. A new file needs four entries: `PBXBuildFile`, `PBXFileReference`, membership in
its `PBXGroup`, and — the one that is easy to miss — the **right target's** `Sources` phase.
`1A5A947D2309E4F30076D635` is the app, `1AF1000000000003` is `GigaBallTests`.

## How work is judged here

- **Pure logic gets tested; visual work gets verified on the simulator.** Both, for anything
  that has both. Take a screenshot and look at it — several bugs in this project were only
  ever going to be caught by looking.
- **A round is not finished when its own tests pass.** Rounds 315 to 318 each ran their own
  classes, passed, and were committed; the last full suite was round 316's and **nobody read
  its result**. It was holding 27 assertion failures, two of them faults in round 318 that
  round 318's own new test had already caught - correct test, written for exactly that fault,
  never part of a run that reached the end. Targeted runs are the right tool while working and
  they cannot see across rounds: half of those failures were tests pinning a look James changed
  two rounds later, which no single round's own classes would ever run. Start the full suite,
  and **read what it says**.

- **A test may not write anything that outlives its process.** The daily's test-day offset is
  a `UserDefaults` integer only a test sets; the test that set it restored the old value in a
  `defer`, which a killed process never runs. The relaunch trap above kills one per full run as
  a matter of course, so the value stuck - and the leak fed itself, because the next run read
  the leaked 1 as "the old value" and put it back. Every date-dependent test had been running a
  day ahead of the calendar for an unknown number of rounds, silently, and the app installed
  from the same build read the same default. Where a test has to write, give the code an
  injectable store (`KeyValueStore`, `InMemoryKeyValueStore`) and point the test at memory.
  **Round 322b found it had happened again, bigger:** the simulator's installed app was holding
  a test's saved game, the resume flag and `gameInProgress`, so its next launch offered to
  resume a fixture. A scene writes all three in ordinary use - entering `Playing`, saving on
  every pause - and the resume-card tests wrote a real save for the splash screen to find. So
  under tests a `GameScene`'s `defaults` is now a suite of its own
  (`GameScene.settingsStore`), its `totalStatsStore` is nil, and the iCloud push stands down,
  all on `GameCenterHandler.isRunningTests`; the splash screen takes a `defaults` too. A suite
  still *reads* through to the app's domain, so a test that cares what a setting says sets it.
  After a change near any of this, look at the simulator app's preferences plist once the
  suite has run.
  **Round 325 found the same leak running the other way.** The suite launches the app, and the
  app's menu reads its own settings - so a save left by *playing* on the test simulator was
  resumed behind the tests, laid out the next time a test waited on the run loop, and
  trapped. Two relaunches in a full run, both naming a frame-cost test that had only waited.
  The menu no longer resumes under `isRunningTests`. If a relaunch names a test with no
  assertion, read the crash report's stack before blaming the audio server: `ls -t
  ~/Library/Logs/DiagnosticReports/Giga-Ball-*` - the audio trap is `SKSoundContext init`,
  and anything else is a real fault.

- **The system's accessibility settings are honoured, not just the app's own** (round 328).
  Giga-Ball has had a parallax setting since long before it had any regard for
  `UIAccessibility.isReduceMotionEnabled`, and the two are different questions: the app's
  setting is a preference about this game, the system's is a decision made once for every app
  on the phone. Motion effects are added through `UIView.motionEffectsAreWelcome` now, which
  asks the system, and the player's own setting is never written to or turned off - nothing
  changes back when they stop reducing motion. The round buttons carry VoiceOver names from
  `MainMenuCollectionViewCell.spokenName`, keyed by the artwork every caller already passes, so
  a new button added to the glass table without a name fails `RoundButtonVoiceOverTests`.

- **Tests are written from play-test reports.** When a bug is described, the test says what
  was reported, in the comment, in the reporter's terms. That is what stops a fix regressing
  into something that merely passes.
- **Derive rather than duplicate.** Reference pages read their facts off the types that own
  them; test expectations read counts off the array that defines them. A second copy of a
  decision is wrong the first time the decision changes.
- Comments explain **why**, especially where the code looks wrong and is not. Match the
  surrounding density — this codebase comments heavily and in prose.

## Traps this project has actually fallen into

The full list is ENDLESS-2-SPECIFICATION.md §8.6, and it is worth reading before touching the
scene. The ones that bite widest:

- **A contact reports the velocity *after* the engine's bounce.** Anything needing the
  approach — which face was struck, which way a portal should send the ball — must sample it
  in `update`, before physics. `ballStateBeforeStep` is that sample. Reflecting a reported
  velocity bounces it twice, which is how the ball ended up running along the ceiling.
- **A brick's `position.y` is its row.** The descent and the bottom-row check both read it. A
  brick off its row centre is cleared at the wrong moment or blocks generation for ever.
  Larger bricks keep the node on a row centre and express size as an anchor point plus an
  offset body.
- **Nothing runs a repeating `SKAction` on a brick.** `countBricks()` gates row generation on
  `hasActions()`, so a permanent action stops the field descending for ever. Spinning,
  flashing, falling and wandering are driven from `update`.
- **Adding a power-up lengthens about a dozen parallel arrays.** Name, icon, description,
  multiplier, timer, two unlock-description lists, display order, pack order, the unlock array,
  the two counters in the stats file, the probability array and the texture array. The suite
  fails loudly on any one missed, which is the only reason this is survivable - see the
  fifty-first power-up, Wipe. The iCloud copies used to be the one the tests could not catch,
  and missing them crashed the app on launch for a player with years of synced data;
  `CloudKitHandler.padded(_:toMatch:)` now grows a short cloud array to match the local one, so
  that particular trap is closed.
- **A style has to be in a pool to exist.** Being in the enum, the grid, the reference page
  and the progression is not enough. From the outside, "never offered" looks exactly like
  "very rare".

## Where outstanding work is tracked

Each spec owns its queue - there is no separate TODO file, deliberately, so the list can
never drift from the document that explains it:

- **ENDLESS-2-SPECIFICATION.md §12.0** - "Open, in rough priority order" (queued play-test
  features) and "Backlogged" (items blocked on something external). §8.5 is the asset and
  sound shopping list, which is James's side along with the App Store Connect leaderboards.
  (The Quick Start Guide was too, until its 1.3 pages arrived in round 322.)
- **DAILY-CHALLENGE-SPECIFICATION.md** - the status header says which build phases exist,
  §12 is the phase plan, §13 the open questions. The daily's test clock was the standing
  release blocker; its controls are gone as of round 19 and only
  `DailyChallengeSession.testDayOffset` remains, driven by a user default that no screen
  writes. Nothing is left to do there.
- Play-test feedback arrives as lists from James; the convention is: fix what fits,
  queue the rest in §12.0 with enough context to build from cold.

## Scope

Ordinary work, done as asked. Where a fix touches shared mechanics — physics, scoring,
paddle, save format — it applies to **all three modes**, and Classic and the original Endless
deserve a few levels of play-testing before it ships, because those are the leaderboards with
years of scores on them.

## Menus

There is no navigation controller. A screen is a child view controller whose view is added
over the one that opened it, and each has its own back button in a collection view - so
"back" is `menuNavigationGoBack()`, which every back button and the left-edge swipe both
call. Adding a screen means conforming to `MenuNavigable`, routing its back button through
that method, and calling `installMenuNavigationSwipes()` in `viewDidLoad`.

That swipe is **horizontal only**, and it has to be: a plain pan recognises a drag in any
direction, and with `cancelsTouchesInView` on it then cancels the touch a table underneath
was scrolling with. That is why the menus would not scroll, and three rounds went into the
scroll affordance before the gesture was suspected. `gestureRecognizerShouldBegin` compares
the translation's x against its y - a pan reports its translation by the time it is asked.

A `UIPanGestureRecognizer` only begins after the touch has travelled its slop, so
`location(in:)` at `.began` is already well inside the screen - the start has to be worked
back out from the translation, or a swipe from the very edge reads as starting outside the
edge strip.

One swipe reaches **every** screen in the stack, because each screen's view is a subview of
the one that opened it. Only the frontmost may act on it, or a swipe three screens deep goes
back three times.
