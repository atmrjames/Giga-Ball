//
//  PowerUpRingHUD.swift
//  Megaball
//
//  The power-up display for Endless 2.0: only what is active, with the timer as a ring
//  around the icon rather than a bar beneath it, in a container that grows and shrinks
//  with what is running.
//
//  The existing tray shows a fixed row of eight, including power-ups that are not running
//  and ones the player has not unlocked, each with a bar underneath. That reads well
//  enough at eight. Endless 2.0 has forty-six, so a fixed row is not an option and most
//  of it would be empty most of the time.
//
//  This reads the state rather than being told about it. Every timed power-up already
//  shows a bar whose horizontal scale is the fraction of time remaining, which is how the
//  save format works out how long is left - so "which are active, and how far through" is
//  a question the scene can already answer, and no activation code has to change to ask
//  it. That keeps this additive: Classic and Endless keep the tray untouched.
//

import SpriteKit

final class PowerUpRingHUD: SKNode {

    /// One power-up worth showing.
    struct Entry {
        let id: String
        let texture: SKTexture
        /// How much is left, from one down to zero.
        let remaining: CGFloat
        /// How many turns the ring counts down, for the power-ups that count rather than
        /// time - the sticky paddle's catches. A segmented ring says "two catches left"
        /// where a smooth one only says "about a third".
        var segments: Int?
    }

    /// The Giga-Ball yellow-green, the colour the game uses for anything of its own.
    static let ringColour = UIColor(red: 0.8235294118, green: 1, blue: 0, alpha: 1)

    /// How far the soft pass blooms past its own stroke.
    ///
    /// Small. `glowWidth` spreads in both directions from the line, so this is doubled on
    /// screen before it is added to the halo's already-wide stroke - and a ring that glows
    /// more than the bricks do stops being a timer and becomes decoration.
    static let ringGlow: CGFloat = 3

    private struct Slot {
        let container: SKNode
        let icon: SKSpriteNode
        let ring: SKShapeNode
        let halo: SKShapeNode
        var remaining: CGFloat
        var segments: Int?
    }

    private var slots: [String: Slot] = [:]
    /// Collection order, oldest first. New arrivals go on the right, and a power-up
    /// collected again while it is running moves there too - so the rightmost is always
    /// the one that just happened.
    private var order: [String] = []

    private let container = SKShapeNode()
    private var containerSlots: CGFloat = 0

    var iconSize: CGFloat = 30
    var spacing: CGFloat = 12

    /// The container never narrows past this, so an empty one still reads as the place
    /// power-ups appear rather than as nothing at all.
    static let minimumSlots = 3

    /// How tall the container is, for whoever has to leave room for it.
    var containerHeight: CGFloat { iconSize + PowerUpRingHUD.padding*2 }
    /// How far in from the icon's edge the ring sits, as a fraction of the icon.
    ///
    /// Inward rather than around, but only just. The icons carry some empty margin, so a ring
    /// drawn outside them spends space the row does not have - but the first attempt put it
    /// at fourteen per cent in, three points thick and with a halo three times that, which
    /// covered most of the icon it was supposed to be timing. It sits close to the edge now
    /// and the glow is a suggestion rather than a light source.
    private static let ringInset: CGFloat = 0.05
    private static let ringWidth: CGFloat = 2
    private static let padding: CGFloat = 8
    private static let appearDuration: TimeInterval = 0.2
    /// A jump in remaining time means it was collected again rather than drained.
    private static let recollectionThreshold: CGFloat = 0.05

    override init() {
        super.init()
        container.strokeColor = .clear
        container.fillColor = UIColor(white: 1, alpha: 0.08)
        container.zPosition = -1
        addChild(container)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Brings the display in line with what is active.
    ///
    /// Called every frame, so it does as little as possible when nothing has changed: the
    /// ring paths are rebuilt, and the layout is left alone unless the running set or its
    /// order is different.
    func update(with entries: [Entry]) {
        var changed = false

        for id in order where entries.contains(where: { $0.id == id }) == false {
            remove(id)
            changed = true
        }

        for entry in entries {
            if slots[entry.id] == nil {
                add(entry)
                order.append(entry.id)
                changed = true
            } else if entry.remaining > (slots[entry.id]?.remaining ?? 0)
                        + PowerUpRingHUD.recollectionThreshold {
                // Collected again while running. Moving it to the right is what makes the
                // row a history of what just happened rather than an arbitrary order.
                order.removeAll { $0 == entry.id }
                order.append(entry.id)
                changed = true
            }
            slots[entry.id]?.remaining = entry.remaining
            slots[entry.id]?.segments = entry.segments
            let path = ringPath(remaining: entry.remaining, segments: entry.segments)
            slots[entry.id]?.ring.path = path
            slots[entry.id]?.halo.path = path
        }

        if changed { layoutSlots() }
        layoutContainer()
    }

    /// Everything gone, without animating - for a reset rather than an expiry.
    func clear() {
        slots.values.forEach { $0.container.removeFromParent() }
        slots.removeAll()
        order.removeAll()
    }

    // MARK: - Slots

    private func add(_ entry: Entry) {
        let holder = SKNode()
        holder.alpha = 0
        holder.setScale(0.7)

        let icon = SKSpriteNode(texture: entry.texture)
        icon.size = CGSize(width: iconSize, height: iconSize)
        icon.zPosition = 1
        holder.addChild(icon)

        // Drawn twice: a soft wide pass underneath and a bright thin one on top. That is
        // what the Giga-Ball glow is everywhere else in the game, and doing it here ties the
        // timer to the rest of the art rather than leaving it as a plain white arc
        let halo = SKShapeNode()
        halo.strokeColor = PowerUpRingHUD.ringColour
        halo.lineWidth = PowerUpRingHUD.ringWidth*2
        halo.lineCap = .round
        halo.fillColor = .clear
        halo.alpha = 0.16
        halo.zPosition = 2
        halo.blendMode = .add
        halo.glowWidth = PowerUpRingHUD.ringGlow
        // A real bloom on the soft pass, not just a wider stroke (play-test rounds 10 and
        // 13 both asked for the glow twice). The thin bright ring on top stays crisp - it is
        // the one carrying the reading, and a blurred timer is a timer you squint at
        holder.addChild(halo)

        let ring = SKShapeNode()
        ring.strokeColor = PowerUpRingHUD.ringColour
        ring.lineWidth = PowerUpRingHUD.ringWidth
        ring.lineCap = .round
        ring.fillColor = .clear
        ring.zPosition = 3
        holder.addChild(ring)

        for shape in [halo, ring] {
            shape.path = ringPath(remaining: entry.remaining, segments: entry.segments)
        }

        addChild(holder)
        slots[entry.id] = Slot(container: holder, icon: icon, ring: ring, halo: halo,
                               remaining: entry.remaining, segments: entry.segments)

        holder.run(.group([.fadeIn(withDuration: PowerUpRingHUD.appearDuration),
                           .scale(to: 1, duration: PowerUpRingHUD.appearDuration)]))
    }

    private func remove(_ id: String) {
        order.removeAll { $0 == id }
        guard let slot = slots.removeValue(forKey: id) else { return }
        // Fades rather than vanishing, so an expiry is something the player sees happen
        slot.container.run(.sequence([
            .group([.fadeOut(withDuration: PowerUpRingHUD.appearDuration),
                    .scale(to: 0.7, duration: PowerUpRingHUD.appearDuration)]),
            .removeFromParent()
        ]))
    }

    /// Centred, growing from the middle, so the row's width tracks what is active.
    private func layoutSlots() {
        let count = CGFloat(order.count)
        guard count > 0 else { return }
        let step = iconSize + spacing
        let firstX = -((count - 1)*step)/2

        for (index, id) in order.enumerated() {
            guard let slot = slots[id] else { continue }
            slot.container.run(.move(to: CGPoint(x: firstX + CGFloat(index)*step, y: 0),
                                     duration: PowerUpRingHUD.appearDuration))
        }
    }

    /// Grows and shrinks with what is running, the way the lives row does.
    private func layoutContainer() {
        let wanted = CGFloat(max(order.count, PowerUpRingHUD.minimumSlots))
        guard wanted != containerSlots else { return }

        let from = containerSlots
        containerSlots = wanted
        let duration = PowerUpRingHUD.appearDuration

        guard from > 0 else {
            setContainerPath(slots: wanted)
            return
        }
        container.removeAllActions()
        container.run(.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self else { return }
            let t = min(1, elapsed/CGFloat(duration))
            let eased = 1 - pow(1 - t, 3)
            self.setContainerPath(slots: from + (wanted - from)*eased)
        })
    }

    private func setContainerPath(slots count: CGFloat) {
        let step = iconSize + spacing
        let width = (count - 1)*step + iconSize + PowerUpRingHUD.padding*2
        let height = iconSize + PowerUpRingHUD.padding*2
        let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        // Rebuilt rather than scaled, or the rounded ends would stretch with it
        container.path = CGPath(roundedRect: rect,
                                cornerWidth: height/2, cornerHeight: height/2,
                                transform: nil)
    }

    // MARK: - Rings

    private func radius() -> CGFloat {
        iconSize/2 - iconSize*PowerUpRingHUD.ringInset
    }

    private func ringPath(remaining: CGFloat, segments: Int?) -> CGPath {
        PowerUpRingHUD.ringPath(remaining: remaining, segments: segments,
                                radius: radius())
    }

    /// An arc from twelve o'clock, clockwise, covering what is left.
    ///
    /// Broken into segments where the power-up counts turns rather than time, with a gap
    /// between each - so three catches read as three marks rather than as three quarters.
    ///
    /// Static and radius-parameterised because two displays draw it now: Mayhem's
    /// only-active row, and the old modes' fixed tray - one geometry, or the same
    /// power-up would read differently between modes.
    static func ringPath(remaining: CGFloat, segments: Int?, radius: CGFloat) -> CGPath {
        let fraction = min(max(remaining, 0), 1)

        guard let segments, segments > 1 else {
            if fraction >= 1 {
                return CGPath(ellipseIn: CGRect(x: -radius, y: -radius,
                                                width: radius*2, height: radius*2),
                              transform: nil)
            }
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: radius,
                        startAngle: .pi/2, endAngle: .pi/2 - .pi*2*fraction, clockwise: true)
            return path
        }

        let lit = Int((fraction*CGFloat(segments)).rounded())
        guard lit > 0 else { return CGMutablePath() }

        let path = CGMutablePath()
        let sweep = CGFloat.pi*2/CGFloat(segments)
        let gap = min(sweep*0.22, 0.28)
        for index in 0..<lit {
            let start = CGFloat.pi/2 - sweep*CGFloat(index) - gap/2
            // Moved to before each arc, not just drawn. `addArc` joins to whatever the
            // current point is, so without this every gap is filled in by the line
            // connecting one segment to the next and the ring reads as solid
            path.move(to: CGPoint(x: cos(start)*radius, y: sin(start)*radius))
            path.addArc(center: .zero, radius: radius,
                        startAngle: start, endAngle: start - (sweep - gap), clockwise: true)
        }
        return path
    }
}

/// The old modes' tray, wearing the ring.
///
/// Classic and the original Endless keep their permanent row of eight - same icons, same
/// order, same geometry, so `layoutUnit` and the brick sizes on scored levels cannot
/// move - and only the *indicator* changes: the bar under each icon becomes the ring
/// dial around it, in the same Giga-Ball colour Mayhem's row wears (James's design,
/// which is what unblocked this port).
///
/// The bars are still in the scene, invisible: their hidden state and horizontal scale
/// are the signal the activation code writes and the save format reads, and this draws
/// the rings from what they say - the same read-the-state trick the Mayhem row uses, so
/// no activation code changes here either.
final class PowerUpTrayRings: SKNode {

    private struct Slot {
        let holder: SKNode
        let ring: SKShapeNode
        let halo: SKShapeNode
        var wasActive = false
    }

    private var slots: [Slot] = []
    private var radius: CGFloat = 14

    private static let ringWidth: CGFloat = 2
    private static let appearDuration: TimeInterval = 0.2

    /// Puts one (empty) ring over each tray icon. Called once the tray has its layout.
    func build(over icons: [SKSpriteNode], iconSize: CGFloat) {
        removeAllChildren()
        slots = []
        radius = iconSize/2 + PowerUpTrayRings.ringWidth
        // Just outside the icon's edge: the tray icons are art, not padded badges like
        // Mayhem's, and a ring drawn inside them sat across the artwork

        for icon in icons {
            let holder = SKNode()
            holder.position = icon.position
            holder.alpha = 0

            let halo = SKShapeNode()
            halo.strokeColor = PowerUpRingHUD.ringColour
            halo.lineWidth = PowerUpTrayRings.ringWidth*2
            halo.lineCap = .round
            halo.fillColor = .clear
            halo.alpha = 0.16
            halo.blendMode = .add
            halo.glowWidth = PowerUpRingHUD.ringGlow
            // The same bloom the Mayhem row wears, so the two modes' timers are one thing
            holder.addChild(halo)

            let ring = SKShapeNode()
            ring.strokeColor = PowerUpRingHUD.ringColour
            ring.lineWidth = PowerUpTrayRings.ringWidth
            ring.lineCap = .round
            ring.fillColor = .clear
            ring.zPosition = 1
            holder.addChild(ring)

            addChild(holder)
            slots.append(Slot(holder: holder, ring: ring, halo: halo))
        }
    }

    /// Brings each slot's ring in line with its bar. Called every frame.
    ///
    /// An entry is nil where the power-up is not running - the ring fades out the way
    /// Mayhem's expire, rather than vanishing.
    func update(remaining: [(fraction: CGFloat, segments: Int?)?]) {
        for (index, entry) in remaining.enumerated() where slots.indices.contains(index) {
            if let entry {
                let path = PowerUpRingHUD.ringPath(remaining: entry.fraction,
                                                  segments: entry.segments,
                                                  radius: radius)
                slots[index].ring.path = path
                slots[index].halo.path = path
                if slots[index].wasActive == false {
                    slots[index].wasActive = true
                    slots[index].holder.removeAllActions()
                    slots[index].holder.run(
                        .fadeIn(withDuration: PowerUpTrayRings.appearDuration))
                }
            } else if slots[index].wasActive {
                slots[index].wasActive = false
                slots[index].holder.removeAllActions()
                slots[index].holder.run(
                    .fadeOut(withDuration: PowerUpTrayRings.appearDuration))
            }
        }
    }
}
