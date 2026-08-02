# Safe-area layout rewrite — plan

Design note for the 1.3 layout work. Written before any code so the geometry is
agreed in plain English first.

## The constraint

**The play area keeps one aspect ratio on every device.** A player moving between
iPhone and iPad must get the same game. Everything else — HUD, power-up tray, side
borders — adapts around it.

On iPad the borders are wider. Elements already placed into the border area on iPad may
continue to move; the play zone itself does not change shape.

## What the current code does

Layout comes from a device-class guess in `GameScene`:

```swift
screenRatio = frame.size.height / frame.size.width
if screenRatio > 2      { screenSize = "X"   }
else if screenRatio < 1.7 { screenSize = "Pad" }
else                    { screenSize = "8"   }

gameWidth = (screenSize == "X") ? h/2.16 : (h/2.16) * 1.1
```

Everything scales from `layoutUnit = gameWidth / 22`. The top bar is
`layoutUnit * 3`, except on notched devices where it is `layoutUnit * 7.4`.

There is no use of `safeAreaInsets` anywhere in the project.

## What that produces today

| Device | Class | gameWidth | Side border | Top bar | Play height | **Ratio** |
|---|---|---|---|---|---|---|
| iPhone 8 | 8 | 339.7 | 17.7 | 46.3 | 620.7 | **1.827** |
| iPhone X / 11 Pro | X | 375.9 | −0.5 | 126.4 | 685.6 | **1.824** |
| iPhone 14 Pro | X | 394.4 | −0.7 | 132.7 | 719.3 | **1.824** |
| iPhone 17 Pro | X | 404.6 | −1.3 | 136.1 | 737.9 | **1.824** |
| iPhone 17 Pro Max | X | 442.6 | −1.3 | 148.9 | 807.1 | **1.824** |
| iPad 10.9 portrait | Pad | 600.9 | 109.5 | 81.9 | 1098.1 | **1.827** |
| iPad Pro 13 portrait | Pad | 700.7 | 165.6 | 95.6 | 1280.4 | **1.827** |

Three conclusions:

1. **The ratio is already constant at ~1.825.** The `× 1.1` and the two top-bar
   multipliers are calibrated to hold it. There is a single number to preserve, and
   the rewrite does not change how the game plays.
2. **Side borders go slightly negative on notched phones.** The playfield is 0.5–1.3pt
   wider than the screen and is clipped. Cosmetically irrelevant, but it confirms the
   formula targets edge-to-edge at iPhone X proportions.
3. **The notch allowance is a guess.** The extra `layoutUnit * 4.4` is about 81pt on a
   17 Pro where the real top inset is around 62pt. It is a fixed multiple of a unit
   derived from screen height, not a measurement. That single fact explains both
   symptoms: content bleeding under the top bar on some devices, and wasted space on
   others.

## Measured baseline

Instrumented build, iPhone 17 Pro, entering endless mode:

```
LAYOUT-BASELINE scene=402x874 class=X insets(t:0.0 b:0.0 l:0.0 r:0.0)
                gameWidth=404.63 layoutUnit=18.3923 topBar=136.10
                playHeight=737.90 ratio=1.8236 sideBorder=-1.31
```

Matches the computed table exactly, which confirms the model above.

**But note `insets` are all zero.** The geometry is computed in
`GameScene.didMove(to view:)`, which runs before the view has been laid out, so
`view.safeAreaInsets` is not yet populated. This is a blocker for the rewrite as
originally sketched: reading insets at that point would always give zero and silently
produce the wrong layout.

### Reading from the window does not work

Tested, and conclusively not viable:

```
LAYOUT-INSETS view(t:0.0 b:0.0) window(t:0.0 b:0.0) hasWindow=NO
```

The scene's view is **not in a window at all** during `didMove(to view:)`. There is no
window to read insets from, so no variation on "read them from somewhere else at the
same moment" can work. The geometry pass has to move.

### What moving it requires

`didMove(to view:)` spans **585 lines** and interleaves three different jobs:

- 51 `childNode(withName:)` lookups — binding scene nodes
- 192 `.size` / `.position` assignments — the geometry
- the rest — game state, textures, settings, observers

Only the geometry is size-dependent and needs re-running when insets or bounds change.
So the work is:

1. Extract the 192 geometry assignments into a `layoutScene(insets:)` that can be called
   repeatedly and is safe to re-run, leaving node binding and state setup in `didMove`.
2. Call it from `GameViewController.viewDidLayoutSubviews()`, which fires after the safe
   area is known and again on any resize or rotation.
3. Apply the closed-form sizing above, driven by real insets.

Step 1 is the substantial part and should be done as its own change, verified against the
recorded baseline, before the formula changes at all. Splitting it that way means the
refactor can be proven inert — same numbers in, same numbers out — and only then does the
behaviour change.

## The rewrite

Replace the device-class guess with a measurement. Keep the ratio explicit.

```
PLAY_RATIO = 1.825            // play height : play width, fixed

topInset    = safeAreaInsets.top
bottomInset = safeAreaInsets.bottom
hudHeight   = 3 * layoutUnit  // the HUD and power-up tray, unchanged
```

The definition is circular — `hudHeight` depends on `layoutUnit`, which depends on
`gameWidth`, which depends on play height, which depends on `hudHeight`. It solves in
closed form:

```
playHeight = (H - topInset - bottomInset) / (1 + 3 / (22 * PLAY_RATIO))
gameWidth  = playHeight / PLAY_RATIO
```

Then clamp and centre:

```
gameWidth   = min(gameWidth, W - safeAreaInsets.left - safeAreaInsets.right)
borderWidth = (W - gameWidth) / 2
```

Clamping matters for short, wide layouts — a resized iPad window or landscape — where
height-derived width would otherwise exceed the available width. Falling back to a
width-derived play area with taller top and bottom borders keeps the ratio intact.

## What changes per element

| Element | Behaviour |
|---|---|
| Play zone | Fixed ratio, centred. Never reshaped |
| Top bar (HUD, power-up tray) | Sits below `safeAreaInsets.top`, height unchanged in layout units |
| Side borders | Absorb all leftover width. Wider on iPad |
| Bottom block | Respects `safeAreaInsets.bottom` so the home indicator does not overlap the paddle |
| Everything scaled from `layoutUnit` | Unchanged. Derived from `gameWidth` exactly as now |

## How to verify

The ratio is the thing that must not move.

1. Log `playHeight / gameWidth` on every device class before and after. It must stay at
   1.825 within rounding.
2. Compare `layoutUnit` before and after on each device. Brick, ball and paddle sizes
   all derive from it, so an unchanged `layoutUnit` means unchanged gameplay feel.
3. Screenshot the same level on iPhone 8, a notched iPhone, and iPad, before and after.
   The playfield should be indistinguishable; only the borders and HUD position change.
4. Confirm no content sits under the Dynamic Island or the home indicator.

Worth doing before touching the code: add a temporary log of these values on the
current build so there is a recorded baseline to diff against, rather than trusting the
table above after the fact.

## Follow-on, not in scope here

Once layout is measured rather than guessed, `UIRequiresFullScreen` can be dropped and
the app becomes resizable. The same clamp handles it: a narrow multitasking slot gets a
smaller play area with the same ratio. Landscape works the same way, with the leftover
width becoming much wider side borders.

That is a separate piece of work and should not be bundled into this one.
