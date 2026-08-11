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
xcodebuild -project Megaball.xcodeproj -scheme Megaball \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

- Local builds need `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`. Xcode
  26.6's `actool` **crashes** on the Icon Composer assets — see SPECIFICATION.md §13.
- Anything destined for the App Store is built by **Xcode Cloud on `release-1.3`**, because
  Apple rejects beta-toolchain uploads and this Mac runs a beta macOS.
- **Stale derived data has twice hidden a new file from the test target**, producing "cannot
  find X in scope" for code that builds fine in the app. If a brand-new file's symbols are
  missing from tests, `xcodebuild clean` before believing the error.

## Adding a file

There is no file-system-synchronised group; `Megaball.xcodeproj/project.pbxproj` is
hand-edited. A new file needs four entries: `PBXBuildFile`, `PBXFileReference`, membership in
its `PBXGroup`, and — the one that is easy to miss — the **right target's** `Sources` phase.
`1A5A947D2309E4F30076D635` is the app, `1AF1000000000003` is `GigaBallTests`.

## How work is judged here

- **Pure logic gets tested; visual work gets verified on the simulator.** Both, for anything
  that has both. Take a screenshot and look at it — several bugs in this project were only
  ever going to be caught by looking.
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
  sound shopping list, which is James's side along with the Quick Start Guide and the
  App Store Connect leaderboards.
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

A `UIPanGestureRecognizer` only begins after the touch has travelled its slop, so
`location(in:)` at `.began` is already well inside the screen - the start has to be worked
back out from the translation, or a swipe from the very edge reads as starting outside the
edge strip.

One swipe reaches **every** screen in the stack, because each screen's view is a subview of
the one that opened it. Only the frontmost may act on it, or a swipe three screens deep goes
back three times.
