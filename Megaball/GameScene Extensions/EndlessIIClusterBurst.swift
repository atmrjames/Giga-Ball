//
//  EndlessIIClusterBurst.swift
//  Megaball
//
//  "Burst" in code because the word "cluster" already belongs to `EndlessIICluster`, the
//  row generator's designed brick formations - two unrelated ideas that happen to share
//  James's favourite word. On screen this power-up is simply Cluster.
//
//  Cluster: about twelve tiny balls burst upwards from the centre of the paddle at random
//  angles. Each counts as a single hit on whatever it meets and is destroyed on contact.
//
//  James's design, round 169, with one line that decides the whole implementation: "they do
//  not combine with other power-ups. They are just normal balls." So a cluster ball is not in
//  `endlessIIExtraBalls` - a Multi-Ball ball is a ball the run continues on, and a cluster
//  ball is ammunition (S12.0). Mechanically each one is a free-flying laser bolt dressed as a
//  tiny ball: it wears the laser's category, so every brick already tests contact with it and
//  `hitBrick`'s laser path already does "one hit, then the projectile dies" for every brick
//  type - Portals struck not entered, power-up bricks spent, Directionals asking which face.
//  What it adds over a laser is the ball-ness: it bounces off the side walls and dies quietly
//  at the top or the bottom, never costing a life on the way out.
//

import SpriteKit

let ClusterCategoryName = "clusterBall"

extension GameScene {

    /// How many balls a Cluster releases.
    static let endlessIIClusterCount = 12

    /// How far either side of straight up a cluster ball may leave, in degrees.
    ///
    /// Wide enough to feel like a burst and to reach the field's edges on the way up, and
    /// clear enough of horizontal that every ball starts by climbing - a release the player
    /// triggers at the paddle must not begin with a ball skimming into the paddle itself.
    static let endlessIIClusterSpreadDeg: ClosedRange<CGFloat> = 25...155

    func endlessIIReleaseCluster() {
        guard gameMode == .endlessII else { return }

        playMayhemSound("clusterRelease")
        // **James, round 340: "cluster release to be played when a cluster power-up is
        // collected and all the balls are released."** Once for the burst rather than once per
        // pellet: twelve copies of one recording started in the same frame is the comb
        // filtering round 334 chased, and `playOnce` would swallow eleven of them anyway.

        let speed = ballSpeedLimit > 0 ? ballSpeedLimit : 300
        // The live scene always has a limit by the time anything can be collected; the
        // fallback is for a burst released before the ball's speed is set, which must still
        // be a burst rather than twelve balls hanging in the air

        let size = ballSize*0.45
        // Tiny, and visibly the ball's own species rather than the laser's: the texture is
        // whatever the ball is currently dressed as, so a themed run bursts in its own theme
        for _ in 0..<GameScene.endlessIIClusterCount {
            let pellet = SKSpriteNode(texture: ball.texture)
            pellet.size = CGSize(width: size, height: size)
            pellet.position = CGPoint(x: paddle.position.x,
                                      y: paddle.position.y + paddle.size.height/2 + size)
            pellet.zPosition = 1
            pellet.name = ClusterCategoryName

            let body = SKPhysicsBody(circleOfRadius: size/2)
            body.allowsRotation = false
            body.friction = 0
            body.restitution = 1
            body.linearDamping = 0
            body.affectedByGravity = false
            body.usesPreciseCollisionDetection = true
            body.categoryBitMask = CollisionTypes.laserCategory.rawValue
            // The laser's category on purpose: every brick body already asks for contact
            // with it, so a new bit here would mean touching every place a brick is built
            body.collisionBitMask = CollisionTypes.screenBlockCategory.rawValue
                | CollisionTypes.boarderCategory.rawValue
            // Walls only - a brick contact destroys the ball before any bounce could matter,
            // and colliding with bricks would nudge the field
            body.contactTestBitMask = CollisionTypes.brickCategory.rawValue
                | CollisionTypes.screenBlockCategory.rawValue
                | CollisionTypes.bottomScreenBlockCategory.rawValue
            pellet.physicsBody = body

            addChild(pellet)
            let angle = CGFloat.random(in: GameScene.endlessIIClusterSpreadDeg)
                * .pi/180
            body.velocity = CGVector(dx: cos(angle)*speed,
                                     dy: sin(angle)*speed)
            // After `addChild`, or the write is lost: a velocity set on a body whose node
            // is not yet in a physics world does not survive the node arriving in one
        }

        if hapticsSetting { heavyHaptic.impactOccurred() }
        if soundsSetting { run(ballPaddleHitSound) }
    }

    /// Whether this contact is a cluster ball meeting a wall, and what to do about it.
    ///
    /// Called from the laser-hits-screen-block branch, because the category is shared. A
    /// laser only ever flies straight up and dies on the first block it meets; a cluster
    /// ball is a normal ball, so a *side* wall bounces it - the engine does the bounce, this
    /// only declines to remove it - and the ceiling swallows it, a hit on nothing.
    func endlessIIClusterSurvivesWall(_ projectile: SKNode, block: SKSpriteNode) -> Bool {
        projectile.name == ClusterCategoryName && block.size.width < block.size.height
    }
    /// Takes every cluster ball off the field at once.
    ///
    /// James, round 291: "cluster balls should disappear immediately if the ball is lost." They
    /// are the ball's own shot, so they end with it - otherwise a burst released a moment
    /// before the ball went down carries on breaking bricks, scoring and dropping power-ups
    /// through the lost-ball animation and into the next serve, with nothing on screen to
    /// explain what is doing it.
    ///
    /// Removed rather than faded. A pellet is a two-tenths-of-a-cell dot at ball speed, and a
    /// fade would be a dot that is still solid while it disappears - it would go on clearing
    /// bricks for as long as it took to become invisible, which is the same bug wearing a
    /// nicer coat.
    func endlessIIClearClusterBalls() {
        guard gameMode == .endlessII else { return }
        enumerateChildNodes(withName: ClusterCategoryName) { node, _ in
            node.removeFromParent()
        }
    }

}
