//
//  TracedBodyCache.swift
//  Megaball
//
//  Tracing a picture into a physics body, once per picture.
//
//  James, round 258: "Game is stuttering whilst certain power ups are enabled... Shaped
//  paddles". Measured rather than guessed at (`EndlessIIFrameCostTests`): a shaped paddle does
//  **not** retrace its body every frame - it retraces on a change and nothing else, which is
//  right - but one trace costs **8.8 milliseconds**, which is over half a frame at sixty.
//
//  `SKPhysicsBody(texture:size:)` walks the picture's alpha and builds a polygon from it, and
//  the cost is in the picture rather than in the shape: the *plain* paddle traces in 7.5ms.
//  So every shape a run collects, every Split Paddle, every safety bar and every mirror is a
//  dropped frame, and a stretch that collects several is several - which is what a stutter is.
//
//  ## Why a cache rather than a faster trace
//
//  There is no faster trace: it is one call into SpriteKit. What there is instead is the fact
//  that the game traces **the same dozen pictures at the same handful of sizes** over and over
//  - five shapes across twelve themes, at the paddle's width and whatever Split Paddle makes
//  of it. A run collecting Convex twice traces the same picture twice.
//
//  So the answer is to trace once and keep it. A body belongs to one node at a time, so what
//  is kept is a template and what is handed out is a `copy()` - which is a memcpy of a polygon
//  that has already been worked out, and is the whole saving.
//
//  **The cache is keyed on the picture and the size**, because those are the only two things
//  the trace reads. Everything else a body carries - its masks, whether it is dynamic, what it
//  is pinned to - is written on afterwards by whoever asked, exactly as before, because those
//  differ between the paddle, the safety bar and the mirror and none of them is a property of
//  the outline.
//
//  It is not bounded. The set of pictures is fixed at build time and the set of sizes a paddle
//  takes is small, so it settles within a run at a few dozen entries and stops growing. A cap
//  would be a guess at a number that never comes.
//

import SpriteKit

enum TracedBodyCache {

    private struct Key: Hashable {
        let texture: ObjectIdentifier
        let width: Int
        let height: Int
    }

    private static var cache: [Key: SKPhysicsBody] = [:]

    /// The body for a picture at a size, traced the first time and copied after.
    ///
    /// Sizes are rounded to a tenth of a point before they are asked about. Two paddles a
    /// thousandth of a point apart are the same outline to anything that can be seen, and
    /// keying on the raw `CGFloat` would miss the cache every time an animation left a
    /// rounding error behind - which is exactly when it matters most.
    ///
    /// Returns nil only when the copy fails, which it does not - the optional is there
    /// because `NSCopying` returns `Any`, and every call site already carries a rectangle
    /// fallback for the picture that will not trace.
    static func body(texture: SKTexture, size: CGSize) -> SKPhysicsBody? {
        let key = Key(texture: ObjectIdentifier(texture),
                      width: Int((size.width*10).rounded()),
                      height: Int((size.height*10).rounded()))

        if let kept = cache[key] { return kept.copy() as? SKPhysicsBody }

        let traced = SKPhysicsBody(texture: texture, size: size)
        cache[key] = traced
        return traced.copy() as? SKPhysicsBody
        // `SKPhysicsBody(texture:size:)` is declared non-optional and returns a body with no
        // outline at all for a picture it cannot trace, which is the same thing every caller
        // has always had to answer for - so it is kept and handed back rather than refused
        // here, and the `?? SKPhysicsBody(rectangleOf:)` at each call site still stands
        // The template is never handed out itself. A body attached to a node is owned by that
        // node, and a second node given the same one would be the first one's body moving
    }

    /// Forgets everything. For tests that want to time a cold trace.
    static func empty() { cache.removeAll() }

    static var count: Int { cache.count }
}
