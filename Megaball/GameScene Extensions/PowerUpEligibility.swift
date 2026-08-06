//
//  PowerUpEligibility.swift
//  Megaball
//
//  Whether a power-up has anything to do right now.
//
//  Most power-ups can turn up at any time. A few only make sense in a particular state: Show
//  Bricks is nothing without invisible bricks to show, Backstop is nothing while a Backstop is
//  already out, and the scoring ones are nothing in a mode that has no score to take points
//  from. The falling power-up generator has asked these questions since 2020, one case at a
//  time, inside the switch that also chose the texture.
//
//  Endless 2.0's power-up brick needed the same answers - a brick holding Show Bricks in a
//  field with nothing hidden in it is a brick that does nothing when you break it - so the
//  questions moved here, where both can ask them. A second copy of a decision is wrong the
//  first time the decision changes.
//
//  Stated as "can this appear" rather than "remove this power-up", because that is the
//  question, and because the answer is now needed before anything has been created.
//

import SpriteKit

extension GameScene {

    /// Whether this power-up could do anything if it appeared now.
    ///
    /// Locked power-ups are not this method's business: the drop path removes those where it
    /// picks, and the brick path checks the same array. This is only about the state of play.
    func powerUpCanAppear(_ index: Int) -> Bool {
        switch index {
        case 0:
            // Get a life. Endless mode has one life by definition
            return numberOfLives < 5 && endlessMode == false

        case 1:
            // Lose a life, and every other bad one: never in place of a Mystery, which would
            // be a Mystery that is always worth avoiding
            return numberOfLives > 0 && mysteryPowerUp == false && endlessMode == false

        case 8, 10:
            // Points. There is no score to add to in endless mode - height is the score
            return endlessMode == false

        case 9:
            // -100 points, only where there is more than that to lose
            return levelScore > 100*2 && mysteryPowerUp == false && endlessMode == false

        case 11:
            return levelScore > 1000*2 && mysteryPowerUp == false && endlessMode == false

        case 12:
            // Max multiplier, only below the cap
            return multiplier < 2.0 && endlessMode == false

        case 13:
            return multiplier > 1.1 && mysteryPowerUp == false && endlessMode == false

        case 14:
            // Complete Level. Endless has no next level to skip to
            return mysteryPowerUp == false && endlessMode == false

        case 15:
            // Show Bricks, only where something is hidden
            return bricksMatching { $0.isHidden } >= 3

        case 16:
            // Hide Bricks, only where there are ordinary bricks to hide
            return bricksMatching { brick in
                brick.texture != self.brickMultiHit1Texture
                    && brick.texture != self.brickMultiHit2Texture
                    && brick.texture != self.brickMultiHit3Texture
                    && brick.texture != self.brickMultiHit4Texture
                    && brick.texture != self.brickInvisibleTexture
                    && brick.texture != self.brickIndestructible1Texture
                    && brick.texture != self.brickIndestructible2Texture
            } >= 3

        case 17:
            // Clear Multi-Hit, only where there are multi-hit bricks
            return bricksMatching { brick in
                brick.texture == self.brickMultiHit1Texture
                    || brick.texture == self.brickMultiHit2Texture
            } >= 3

        case 18:
            // Reset Multi-Hit, only where some have been hit
            return bricksMatching { brick in
                brick.texture == self.brickMultiHit2Texture
                    || brick.texture == self.brickMultiHit3Texture
                    || brick.texture == self.brickMultiHit4Texture
            } >= 3

        case 19:
            // Zap Indestructible, only where there are some
            return bricksMatching { brick in
                brick.texture == self.brickIndestructible1Texture
                    || brick.texture == self.brickIndestructible2Texture
            } >= 3

        case 23:
            // Quicksand. Not with the field already at the bottom, and not in endless mode,
            // where the field comes down by itself
            return endlessMode == false && bricksAreAtTheBottom == false

        case 24:
            // Mystery, never in place of another Mystery
            return mysteryPowerUp == false

        case 25:
            // Backstop, only when one is not already out
            return backstopCatches <= 0

        case 28:
            // Multi-Ball, only below the cap and only in the mode that has it
            return endlessIICanAddBall

        default:
            return true
        }
    }

    /// How many bricks on the field answer to this.
    ///
    /// Counted rather than found, because every one of the questions above is "are there
    /// enough of these to be worth a power-up", and three is the number the game has always
    /// used for that.
    private func bricksMatching(_ test: @escaping (SKSpriteNode) -> Bool) -> Int {
        var found = 0
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode else { return }
            if test(brick) { found += 1 }
        }
        return found
    }

    /// Whether the field has already reached the paddle.
    var bricksAreAtTheBottom: Bool {
        var reached = false
        enumerateChildNodes(withName: BrickCategoryName) { node, stop in
            if node.position.y < self.paddle.position.y + self.minPaddleGap {
                reached = true
                stop.initialize(to: true)
            }
        }
        return reached
    }
}
