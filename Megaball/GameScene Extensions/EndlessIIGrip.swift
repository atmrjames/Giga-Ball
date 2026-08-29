//
//  EndlessIIGrip.swift
//  Megaball
//
//  The grip: what the paddle wears while Ball Control is steering.
//
//  James, round 261: "Grip is the texture to use when the ball steering power-up is active -
//  it replaces the sticky and aimed sticky power-up and textures when caught. The grip texture
//  is effectively just a black version of the sticky texture."
//
//  ## Why it lives with the sticky face rather than beside it
//
//  A paddle has one top. Sticky, Aimed Sticky and now the grip all dress it, and they cannot
//  all be on at once - so this is not a fourth overlay but a fourth *reason* for the one
//  overlay the paddle already has, `paddleSticky`, wearing a different picture. That is also
//  why the shaped set arrived complete: twelve themes by six shapes of `Grip` art, drawn to sit
//  exactly where the sticky art sits, so every path that already knew how to place a sticky
//  face needs nothing said to it about this one.
//
//  ## What "replaces when caught" means
//
//  Collecting Ball Control **ends** any Sticky or Aimed Sticky outright, which is the whole of
//  James's sentence: the power-ups, not only their pictures. So the two states cannot overlap
//  and there is no priority to decide between them.
//
//  **The reverse is not stated and is not assumed.** A Sticky collected while Ball Control is
//  steering takes the face, because a paddle that is about to catch a ball has to look like one
//  - and Ball Control carries on steering underneath, because ending a timed aid over a
//  collection it was never said to conflict with would be inventing a rule. Worth a play-test
//  eye: if James wants that symmetric, it is one line here.
//
//  ## Retro
//
//  Retro is the one theme whose plain sticky picture is not in the others' style, so it wears
//  its own overlay node (`paddleRetroStickyTexture`) rather than the shared one. James, round
//  261: "for retro, its regular sticky texture is quite different from the other paddles, but
//  its grip texture is in the same style as the other paddles." So the grip goes on the
//  *shared* node even in retro, and the retro overlay stands down while it does - which is the
//  one place this file has to know that retro exists.
//

import SpriteKit

extension GameScene {

    /// Whether the paddle should be wearing the grip rather than a sticky face.
    var endlessIIWearsGrip: Bool {
        gameMode == .endlessII && endlessIIBallSteeringClock.isRunning
    }

    /// Which overlay picture the paddle's top wants: the grip's or the sticky's.
    ///
    /// The one place the choice is made, so every caller that dresses the paddle - the shaped
    /// dressing, the plain setup, a resize - asks rather than decides.
    var endlessIIPaddleTopKind: String { endlessIIWearsGrip ? "Grip" : "Sticky" }

    /// The plain, unshaped picture for whichever of the two is wanted.
    ///
    /// Grip is themed like everything else and every theme has one, so it goes through the same
    /// lookup the shapes use with an empty shape name. Sticky keeps `stickyPaddleTexture`,
    /// which carries the historical aliases the theme list cannot express - ice borrows glass's.
    var endlessIIPaddleTopTexture: SKTexture {
        guard endlessIIWearsGrip else { return stickyPaddleTexture }
        return SKTexture(imageNamed: endlessIIThemedShapeArt("Grip", ""))
    }

    /// Puts the grip on, and takes the catching power-ups off with it.
    ///
    /// Called from the Ball Control collection, which is the only thing that starts a grip.
    func startEndlessIIGrip() {
        guard gameMode == .endlessII else { return }

        stickyPaddleCatches = 0
        stickyPaddleCatchesTotal = 0
        stickyPaddleIconBar.isHidden = true
        stickyPaddleIcon.texture = iconStickyPaddleDisabledTexture
        endlessIICancelAimedSticky()
        // "It replaces the sticky and aimed sticky power-up... when caught" - the power-ups,
        // not only their pictures. `endlessIICancelAimedSticky` keeps a hold the player is in
        // right now, so a ball already sitting on the paddle mid-aim still gets its launch

        endlessIIReleaseRemainingHeldBalls()
        // Anything the sticky face was holding leaves now rather than waiting for a tap it no
        // longer has any claim to - the same thing the last sticky catch does

        showEndlessIIGripFace()
    }

    /// Shows the grip overlay, wherever the theme keeps its sticky face.
    func showEndlessIIGripFace() {
        guard endlessIIWearsGrip else { return }
        paddleSticky.texture = endlessIIPaddleTopTexture
        paddleSticky.isHidden = false
        paddleRetroStickyTexture.isHidden = true
        // The shared node even in retro, which is the whole of James's note about it: retro's
        // plain sticky picture is its own thing and its grip is in everybody else's style
        refreshEndlessIIPaddleShapeDressing(
            endlessIIShapeOwnsTheBounce
                ? endlessIIPaddleSurface.flatMap { endlessIIPaddleShapeSuffix($0) } : nil)
        // Straight through the shaped dressing, so a grip collected while a shape is running
        // wears that shape's grip rather than the flat one
    }
}
