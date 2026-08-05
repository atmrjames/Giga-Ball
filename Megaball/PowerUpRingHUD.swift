//
//  PowerUpRingHUD.swift
//  Megaball
//
//  The power-up display for Endless 2.0: only what is active, with the timer as a ring
//  around the icon rather than a bar beneath it.
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
//  it. That keeps this phase additive: Classic and Endless keep the tray untouched.
//

import SpriteKit

final class PowerUpRingHUD: SKNode {

    /// One power-up worth showing.
    struct Entry: Equatable {
        let id: String
        let texture: SKTexture
        /// How much of its time is left, from one down to zero.
        let remaining: CGFloat

        static func == (a: Entry, b: Entry) -> Bool { a.id == b.id }
    }

    private struct Slot {
        let container: SKNode
        let icon: SKSpriteNode
        let ring: SKShapeNode
    }

    private var slots: [String: Slot] = [:]
    private var order: [String] = []

    var iconSize: CGFloat = 30
    var spacing: CGFloat = 12

    private static let ringWidth: CGFloat = 3
    private static let appearDuration: TimeInterval = 0.2

    /// Brings the display in line with what is active.
    ///
    /// Called every frame, so it does as little as possible when nothing has changed:
    /// only the ring paths are rebuilt, and the layout is left alone unless the set of
    /// power-ups itself is different.
    func update(with entries: [Entry]) {
        let incoming = entries.map(\.id)

        if incoming != order {
            for id in order where !incoming.contains(id) {
                remove(id)
            }
            for entry in entries where slots[entry.id] == nil {
                add(entry)
            }
            order = incoming
            layoutSlots()
        }

        for entry in entries {
            slots[entry.id]?.ring.path = ringPath(remaining: entry.remaining)
        }
    }

    /// Everything gone, without animating - for a reset rather than an expiry.
    func clear() {
        slots.values.forEach { $0.container.removeFromParent() }
        slots.removeAll()
        order.removeAll()
    }

    // MARK: - Slots

    private func add(_ entry: Entry) {
        let container = SKNode()
        container.alpha = 0
        container.setScale(0.7)

        let icon = SKSpriteNode(texture: entry.texture)
        icon.size = CGSize(width: iconSize, height: iconSize)
        icon.zPosition = 1
        container.addChild(icon)

        let ring = SKShapeNode()
        ring.strokeColor = .white
        ring.lineWidth = PowerUpRingHUD.ringWidth
        ring.lineCap = .round
        ring.fillColor = .clear
        ring.zPosition = 2
        ring.path = ringPath(remaining: entry.remaining)
        container.addChild(ring)

        addChild(container)
        slots[entry.id] = Slot(container: container, icon: icon, ring: ring)

        container.run(.group([.fadeIn(withDuration: PowerUpRingHUD.appearDuration),
                              .scale(to: 1, duration: PowerUpRingHUD.appearDuration)]))
    }

    private func remove(_ id: String) {
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
            let x = firstX + CGFloat(index)*step
            slot.container.run(.move(to: CGPoint(x: x, y: 0),
                                     duration: PowerUpRingHUD.appearDuration))
        }
    }

    /// An arc from twelve o'clock, clockwise, covering the time left.
    private func ringPath(remaining: CGFloat) -> CGPath {
        let fraction = min(max(remaining, 0), 1)
        let radius = iconSize/2 + PowerUpRingHUD.ringWidth
        let start = CGFloat.pi/2
        // Clockwise from the top, so a draining ring unwinds the way a clock does
        let end = start - .pi*2*fraction

        if fraction >= 1 {
            return CGPath(ellipseIn: CGRect(x: -radius, y: -radius,
                                            width: radius*2, height: radius*2),
                          transform: nil)
        }
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: radius,
                    startAngle: start, endAngle: end, clockwise: true)
        return path
    }
}
