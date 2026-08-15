//
//  PowerUpIcon.swift
//  Megaball
//
//  Placeholder icons for the power-ups that do not have artwork yet.
//
//  §8.5 has the icons down as still to make, and deliberately last: a placeholder that reads
//  correctly is worth more while a mechanic is still moving than finished art for something
//  that might change. What matters is that the placeholder belongs to the *set* - the same
//  rounded square, the same green for beneficial, a white glyph - so a new power-up looks like
//  a power-up in the tray, in the drop and on the information page, rather than looking like a
//  gap where an asset should be.
//
//  Drawn rather than added as an asset for the same reason the brick styles are: when the real
//  icon arrives this file is where the slot stops being filled from.
//

import UIKit

enum PowerUpIcon {

    /// The size the existing icons are drawn at.
    static let canvas = CGSize(width: 120, height: 120)

    /// The green every beneficial power-up wears, and the red every harmful one does.
    static let beneficial = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 1)
    static let harmful = #colorLiteral(red: 0.9098039216, green: 0.2666666667, blue: 0.2666666667, alpha: 1)

    /// Multi-Ball: three balls where there was one.
    ///
    /// Three rather than four, which is the maximum - a picture of the limit says "four balls"
    /// where a picture of more than one says "another ball", and the second is what the
    /// power-up does.
    static let multiBall: UIImage = badge { context, rect in
        let radius = rect.width*0.115
        let centres = [CGPoint(x: rect.midX, y: rect.midY - rect.height*0.14),
                       CGPoint(x: rect.midX - rect.width*0.19, y: rect.midY + rect.height*0.13),
                       CGPoint(x: rect.midX + rect.width*0.19, y: rect.midY + rect.height*0.13)]

        context.setFillColor(UIColor.white.cgColor)
        for centre in centres {
            context.fillEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                           width: radius*2, height: radius*2))
        }
    }

    /// Trajectory Line: the path ahead, drawn as it will be drawn - a line with a bounce in it.
    static let trajectoryLine: UIImage = badge { context, rect in
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(rect.width*0.07)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.2, y: rect.maxY - rect.height*0.2))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.25, y: rect.midY))
        context.addLine(to: CGPoint(x: rect.minX + rect.width*0.3, y: rect.minY + rect.height*0.22))
        context.strokePath()

        let radius = rect.width*0.09
        let end = CGPoint(x: rect.minX + rect.width*0.3, y: rect.minY + rect.height*0.22)
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: end.x - radius, y: end.y - radius,
                                       width: radius*2, height: radius*2))
        // The ball at the end of its path
    }

    /// Landing Marker: the ghost ball above the paddle's line.
    static let landingMarker: UIImage = badge { context, rect in
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(rect.width*0.07)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.18, y: rect.maxY - rect.height*0.24))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18, y: rect.maxY - rect.height*0.24))
        context.strokePath()
        // The paddle's line

        let radius = rect.width*0.14
        let centre = CGPoint(x: rect.midX, y: rect.midY - rect.height*0.08)
        context.strokeEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                         width: radius*2, height: radius*2))
        // The ghost of the ball, empty because it is a prediction rather than a ball
    }

    // MARK: - The paddle batch

    /// Aimed Sticky: a held ball with the aim arrow leaving it.
    static let aimedSticky: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.07)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.18, y: rect.maxY - rect.height*0.2))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18, y: rect.maxY - rect.height*0.2))
        context.strokePath()
        // The paddle

        let start = CGPoint(x: rect.midX - rect.width*0.06, y: rect.maxY - rect.height*0.3)
        let end = CGPoint(x: rect.maxX - rect.width*0.26, y: rect.minY + rect.height*0.24)
        context.move(to: start)
        context.addLine(to: end)
        context.move(to: CGPoint(x: end.x - rect.width*0.14, y: end.y + rect.height*0.02))
        context.addLine(to: end)
        context.addLine(to: CGPoint(x: end.x - rect.width*0.02, y: end.y + rect.height*0.15))
        context.strokePath()
        // The aim, leaving at an angle a drag chose

        dot(context, at: start, radius: rect.width*0.08)
    }

    /// Magnetism: the ball's path curving in toward the paddle.
    static let magnetism: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.07)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.18, y: rect.maxY - rect.height*0.2))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18, y: rect.maxY - rect.height*0.2))
        context.strokePath()

        context.move(to: CGPoint(x: rect.minX + rect.width*0.24, y: rect.minY + rect.height*0.2))
        context.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.32),
                             control: CGPoint(x: rect.maxX - rect.width*0.2, y: rect.minY + rect.height*0.4))
        context.strokePath()
        dot(context, at: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.32),
            radius: rect.width*0.08)
    }

    /// Portal Paddle: in at the paddle, out at the top.
    static let portalPaddle: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.07)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.18, y: rect.maxY - rect.height*0.2))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18, y: rect.maxY - rect.height*0.2))
        context.strokePath()

        context.setLineDash(phase: 0, lengths: [rect.width*0.08, rect.width*0.07])
        context.move(to: CGPoint(x: rect.minX + rect.width*0.18, y: rect.minY + rect.height*0.2))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18, y: rect.minY + rect.height*0.2))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
        // The top it comes back in from, dashed because it is not really there

        dot(context, at: CGPoint(x: rect.midX, y: rect.minY + rect.height*0.38),
            radius: rect.width*0.08)
    }

    /// Paddle Halo: the glow reaching up from the paddle.
    static let paddleHalo: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.07)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.18, y: rect.maxY - rect.height*0.24))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18, y: rect.maxY - rect.height*0.24))
        context.strokePath()

        context.addArc(center: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.24),
                       radius: rect.width*0.3, startAngle: .pi, endAngle: 0, clockwise: false)
        context.strokePath()
    }

    /// Ball Steering: the ball leaning both ways.
    static let ballSteering: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.07)
        dot(context, at: CGPoint(x: rect.midX, y: rect.midY - rect.height*0.1),
            radius: rect.width*0.11)

        let y = rect.maxY - rect.height*0.28
        context.move(to: CGPoint(x: rect.minX + rect.width*0.2, y: y))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.2, y: y))
        for direction: CGFloat in [-1, 1] {
            let tip = CGPoint(x: rect.midX + direction*(rect.width*0.3), y: y)
            context.move(to: CGPoint(x: tip.x - direction*rect.width*0.1, y: y - rect.height*0.08))
            context.addLine(to: tip)
            context.addLine(to: CGPoint(x: tip.x - direction*rect.width*0.1, y: y + rect.height*0.08))
        }
        context.strokePath()
    }

    /// Inert Paddle: the bounce coming off exactly as it went in.
    static let inertPaddle: UIImage = badge(harmful) { context, rect in
        stroke(context, width: rect.width*0.07)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.18, y: rect.maxY - rect.height*0.24))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18, y: rect.maxY - rect.height*0.24))
        context.strokePath()

        context.move(to: CGPoint(x: rect.midX - rect.width*0.2, y: rect.minY + rect.height*0.22))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.3))
        context.addLine(to: CGPoint(x: rect.midX + rect.width*0.2, y: rect.minY + rect.height*0.22))
        context.strokePath()
        // The one bounce the paddle no longer has a say in
    }

    /// Flipped Angle: the bounce sent back the way it came from.
    static let flippedAngle: UIImage = badge(harmful) { context, rect in
        stroke(context, width: rect.width*0.07)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.18, y: rect.maxY - rect.height*0.24))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18, y: rect.maxY - rect.height*0.24))
        context.strokePath()

        let base = CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.3)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.24, y: rect.minY + rect.height*0.26))
        context.addLine(to: base)
        let end = CGPoint(x: rect.minX + rect.width*0.32, y: rect.minY + rect.height*0.5)
        context.addLine(to: end)
        context.move(to: CGPoint(x: end.x + rect.width*0.02, y: end.y + rect.height*0.14))
        context.addLine(to: end)
        context.addLine(to: CGPoint(x: end.x + rect.width*0.15, y: end.y + rect.height*0.04))
        context.strokePath()
        // In from the left, out to the left - the influence turned round
    }

    /// Reversed Controls: the finger goes one way, the paddle the other.
    static let reversedControls: UIImage = badge(harmful) { context, rect in
        stroke(context, width: rect.width*0.07)
        for (y, direction) in [(rect.midY - rect.height*0.14, CGFloat(1)),
                               (rect.midY + rect.height*0.14, CGFloat(-1))] {
            context.move(to: CGPoint(x: rect.midX - direction*rect.width*0.24, y: y))
            context.addLine(to: CGPoint(x: rect.midX + direction*rect.width*0.24, y: y))
            let tip = CGPoint(x: rect.midX + direction*rect.width*0.24, y: y)
            context.move(to: CGPoint(x: tip.x - direction*rect.width*0.1, y: y - rect.height*0.07))
            context.addLine(to: tip)
            context.addLine(to: CGPoint(x: tip.x - direction*rect.width*0.1, y: y + rect.height*0.07))
        }
        context.strokePath()
    }

    /// Cull: half the field, gone.
    static let cull: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.06)
        context.setFillColor(UIColor.white.cgColor)
        for (index, y) in [rect.minY + rect.height*0.28, rect.midY,
                           rect.maxY - rect.height*0.28].enumerated() {
            for column in 0..<3 {
                let x = rect.minX + rect.width*(0.24 + 0.26*CGFloat(column))
                let cell = CGRect(x: x - rect.width*0.09, y: y - rect.height*0.06,
                                  width: rect.width*0.18, height: rect.height*0.12)
                if (index + column).isMultiple(of: 2) {
                    context.fill(cell)
                } else {
                    context.stroke(cell)
                }
            }
        }
    }

    /// Clear And Retreat: the bottom row going, the field moving up.
    static let clearAndRetreat: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.07)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.2, y: rect.maxY - rect.height*0.22))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.2, y: rect.maxY - rect.height*0.22))
        context.strokePath()
        // The row on its way out

        let tip = CGPoint(x: rect.midX, y: rect.minY + rect.height*0.2)
        context.move(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.36))
        context.addLine(to: tip)
        context.move(to: CGPoint(x: tip.x - rect.width*0.13, y: tip.y + rect.height*0.14))
        context.addLine(to: tip)
        context.addLine(to: CGPoint(x: tip.x + rect.width*0.13, y: tip.y + rect.height*0.14))
        context.strokePath()
    }

    /// Laser Beam: the column, floor to ceiling.
    static let laserBeam: UIImage = badge { context, rect in
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: rect.midX - rect.width*0.07, y: rect.minY + rect.height*0.14,
                            width: rect.width*0.14, height: rect.height*0.72))
        for x in [rect.midX - rect.width*0.22, rect.midX + rect.width*0.22] {
            context.fill(CGRect(x: x - rect.width*0.025, y: rect.minY + rect.height*0.3,
                                width: rect.width*0.05, height: rect.height*0.4))
        }
    }

    /// Wrecking Ball: a heavier ball, with impact marks.
    static let wreckingBall: UIImage = badge { context, rect in
        dot(context, at: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width*0.17)
        stroke(context, width: rect.width*0.06)
        for angle in stride(from: CGFloat.pi/6, to: 2*CGFloat.pi, by: CGFloat.pi/3) {
            let from = CGPoint(x: rect.midX + cos(angle)*rect.width*0.24,
                               y: rect.midY + sin(angle)*rect.width*0.24)
            let to = CGPoint(x: rect.midX + cos(angle)*rect.width*0.34,
                             y: rect.midY + sin(angle)*rect.width*0.34)
            context.move(to: from)
            context.addLine(to: to)
        }
        context.strokePath()
    }

    /// Aura: the ball inside its glow.
    static let aura: UIImage = badge { context, rect in
        dot(context, at: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width*0.11)
        stroke(context, width: rect.width*0.06)
        context.strokeEllipse(in: CGRect(x: rect.midX - rect.width*0.28,
                                         y: rect.midY - rect.width*0.28,
                                         width: rect.width*0.56, height: rect.width*0.56))
    }

    /// Infill: bricks arriving where there were none.
    static let infill: UIImage = badge(harmful) { context, rect in
        context.setFillColor(UIColor.white.cgColor)
        for (row, columns) in [(0.3, [0, 2]), (0.55, [1]), (0.8, [0, 2])] {
            for column in columns {
                let x = rect.minX + rect.width*(0.24 + 0.26*CGFloat(column))
                let cell = CGRect(x: x - rect.width*0.1, y: rect.minY + rect.height*row - rect.height*0.06,
                                  width: rect.width*0.2, height: rect.height*0.12)
                context.fill(cell)
            }
        }
    }

    /// Descent: the field on its way down.
    static let descent: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.06)
        for y in [rect.minY + rect.height*0.26, rect.minY + rect.height*0.42] {
            context.move(to: CGPoint(x: rect.minX + rect.width*0.22, y: y))
            context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.22, y: y))
        }
        context.strokePath()
        // The rows

        let tip = CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.18)
        context.move(to: CGPoint(x: rect.midX, y: rect.midY + rect.height*0.04))
        context.addLine(to: tip)
        context.move(to: CGPoint(x: tip.x - rect.width*0.13, y: tip.y - rect.height*0.14))
        context.addLine(to: tip)
        context.addLine(to: CGPoint(x: tip.x + rect.width*0.13, y: tip.y - rect.height*0.14))
        context.strokePath()
    }

    /// Auto-Aim: the crosshair the paddle puts on the lowest brick.
    static let autoAim: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.06)
        let centre = CGPoint(x: rect.midX, y: rect.midY - rect.height*0.06)
        let radius = rect.width*0.2
        context.strokeEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                         width: radius*2, height: radius*2))
        for (dx, dy) in [(CGFloat(0), radius), (0, -radius), (radius, 0), (-radius, 0)] {
            context.move(to: CGPoint(x: centre.x + dx*0.55, y: centre.y + dy*0.55))
            context.addLine(to: CGPoint(x: centre.x + dx*1.35, y: centre.y + dy*1.35))
        }
        context.strokePath()
        dot(context, at: centre, radius: rect.width*0.05)

        context.move(to: CGPoint(x: rect.minX + rect.width*0.22, y: rect.maxY - rect.height*0.16))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.22, y: rect.maxY - rect.height*0.16))
        context.strokePath()
        // The paddle doing the aiming
    }

    /// Wrap-Around: out one side, in the other.
    static let wrapAround: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.06)
        for x in [rect.minX + rect.width*0.16, rect.maxX - rect.width*0.16] {
            context.setLineDash(phase: 0, lengths: [rect.width*0.07, rect.width*0.06])
            context.move(to: CGPoint(x: x, y: rect.minY + rect.height*0.2))
            context.addLine(to: CGPoint(x: x, y: rect.maxY - rect.height*0.2))
            context.strokePath()
        }
        context.setLineDash(phase: 0, lengths: [])
        // The walls, dashed because they are not really there

        let y = rect.midY
        context.move(to: CGPoint(x: rect.midX - rect.width*0.1, y: y))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.2, y: y))
        let tip = CGPoint(x: rect.maxX - rect.width*0.2, y: y)
        context.move(to: CGPoint(x: tip.x - rect.width*0.09, y: y - rect.height*0.07))
        context.addLine(to: tip)
        context.addLine(to: CGPoint(x: tip.x - rect.width*0.09, y: y + rect.height*0.07))
        context.strokePath()
        dot(context, at: CGPoint(x: rect.minX + rect.width*0.28, y: y), radius: rect.width*0.08)
        // Leaving right, so the ball on the left is the same ball arriving
    }

    /// Lock: a padlock, shut. Freezes every running clock (§5.4).
    static let lock: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.07)
        let body = CGRect(x: rect.minX + rect.width*0.24, y: rect.midY - rect.height*0.04,
                          width: rect.width*0.52, height: rect.height*0.36)
        context.stroke(body)

        // The shackle, closed: both feet land on the body
        let span = rect.width*0.15
        let top = rect.minY + rect.height*0.22
        context.move(to: CGPoint(x: rect.midX - span, y: body.minY))
        context.addLine(to: CGPoint(x: rect.midX - span, y: top + span))
        context.addArc(center: CGPoint(x: rect.midX, y: top + span), radius: span,
                       startAngle: .pi, endAngle: 0, clockwise: true)
        context.addLine(to: CGPoint(x: rect.midX + span, y: body.minY))
        context.strokePath()

        dot(context, at: CGPoint(x: body.midX, y: body.midY), radius: rect.width*0.05)
    }

    /// Key: the way out of a Lock. Deliberately the same weight of line, because the two
    /// are read together - one is only ever on screen because the other is.
    static let key: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.07)
        let bow = rect.width*0.15
        let centre = CGPoint(x: rect.minX + rect.width*0.31, y: rect.midY)
        context.strokeEllipse(in: CGRect(x: centre.x - bow, y: centre.y - bow,
                                         width: bow*2, height: bow*2))

        context.move(to: CGPoint(x: centre.x + bow, y: centre.y))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18, y: centre.y))
        context.strokePath()
        // The teeth, on the shaft's end
        for x in [rect.maxX - rect.width*0.30, rect.maxX - rect.width*0.20] {
            context.move(to: CGPoint(x: x, y: centre.y))
            context.addLine(to: CGPoint(x: x, y: centre.y + rect.height*0.12))
            context.strokePath()
        }
    }

    /// Wipe: everything you had running, gone.
    ///
    /// Three rings of decreasing weight with a stroke through them - the ring is the shape the
    /// power-up timers are drawn as everywhere else in this mode, so what is being crossed out
    /// is recognisable as *your timers* rather than as a generic no-entry sign.
    static let wipe: UIImage = badge(harmful) { context, rect in
        stroke(context, width: rect.width*0.07)
        let radius = rect.width*0.11
        for (index, x) in [rect.width*0.28, rect.width*0.5, rect.width*0.72].enumerated() {
            context.setAlpha(1 - CGFloat(index)*0.3)
            // Fading left to right: the ones already wiped, and the one going
            let centre = CGPoint(x: rect.minX + x, y: rect.midY + rect.height*0.06)
            context.strokeEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                             width: radius*2, height: radius*2))
        }
        context.setAlpha(1)

        context.setLineWidth(rect.width*0.09)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.16,
                                 y: rect.midY + rect.height*0.26))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.16,
                                    y: rect.midY - rect.height*0.14))
        context.strokePath()
        // One stroke through all three, heavier than the rings it cancels
    }

    /// A ball meeting a surface and leaving it three ways at once.
    ///
    /// The arriving line is solid and the three departing ones fade, because what the
    /// power-up takes away is knowing which of them you will get - drawn as a fan rather
    /// than as dice or a question mark, so the picture is of the *bounce* going wrong
    /// rather than of randomness in the abstract.
    static let randomisedBounce: UIImage = badge(harmful) { context, rect in
        stroke(context, width: rect.width*0.08)

        let hit = CGPoint(x: rect.midX, y: rect.midY + rect.height*0.2)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.16,
                                 y: rect.minY + rect.height*0.18))
        context.addLine(to: hit)
        context.strokePath()
        // The approach, solid: the only part of the bounce still known

        for (index, angle) in [-0.95, -0.45, 0.1].enumerated() {
            context.setAlpha(0.85 - CGFloat(index)*0.2)
            let length = rect.width*0.34
            context.move(to: hit)
            context.addLine(to: CGPoint(x: hit.x + cos(angle)*length,
                                        y: hit.y - sin(angle)*length))
            context.strokePath()
        }
        context.setAlpha(1)

        context.setLineWidth(rect.width*0.09)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.2, y: hit.y + rect.height*0.02))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.2, y: hit.y + rect.height*0.02))
        context.strokePath()
        // The surface itself, heavier than the paths leaving it
    }

    /// A ball drawn as a dashed outline, with the brick line it reappears under.
    ///
    /// Dashes rather than a faint circle: a power-up icon is drawn small and at low alpha it
    /// would read as a rendering fault rather than as the ball being *absent*. The line under
    /// it is the lowest brick row - what the player gets back is the last part of the flight,
    /// which is the part they can still do something about.
    static let ghostBall: UIImage = badge(harmful) { context, rect in
        stroke(context, width: rect.width*0.07)
        let radius = rect.width*0.2
        let centre = CGPoint(x: rect.midX, y: rect.midY - rect.height*0.06)
        context.saveGState()
        context.setLineDash(phase: 0, lengths: [rect.width*0.1, rect.width*0.07])
        context.strokeEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                         width: radius*2, height: radius*2))
        context.restoreGState()

        context.setLineWidth(rect.width*0.09)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.18,
                                 y: rect.maxY - rect.height*0.22))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.18,
                                    y: rect.maxY - rect.height*0.22))
        context.strokePath()
    }

    /// The Daily Challenge's menu mark: a calendar with today burning in it.
    static let dailyChallenge: UIImage = badge { context, rect in
        stroke(context, width: rect.width*0.06)
        let card = CGRect(x: rect.minX + rect.width*0.2, y: rect.minY + rect.height*0.24,
                          width: rect.width*0.6, height: rect.height*0.52)
        context.stroke(card)
        context.move(to: CGPoint(x: card.minX, y: card.minY + card.height*0.28))
        context.addLine(to: CGPoint(x: card.maxX, y: card.minY + card.height*0.28))
        context.strokePath()
        for x in [card.minX + card.width*0.3, card.maxX - card.width*0.3] {
            context.move(to: CGPoint(x: x, y: card.minY))
            context.addLine(to: CGPoint(x: x, y: rect.minY + rect.height*0.16))
            context.strokePath()
        }
        dot(context, at: CGPoint(x: card.midX, y: card.midY + card.height*0.14),
            radius: rect.width*0.09)
    }

    // MARK: - Daily twist icons

    /// The violet every twist badge wears.
    ///
    /// Deliberately neither the power-up green nor the harmful red: a twist is not a
    /// pickup, it is the day's rule, and it should read as its own kind of thing beside
    /// the twist's name on the briefing screen, the pause summary and the level intro.
    /// Lighter than the app's deep purple, which vanished against the dark menu blur.
    /// Placeholders in the same sense as the power-up icons above - James's real twist
    /// artwork replaces these here, and nowhere else.
    static let twist = #colorLiteral(red: 0.4235294118, green: 0.1843137255, blue: 0.6196078431, alpha: 1)

    /// One Life: a single ball, nothing behind it.
    static let twistOneLife: UIImage = badge(twist) { context, rect in
        dot(context, at: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width*0.14)
    }

    /// Loaded: the generous day - a rack full of balls.
    static let twistLoaded: UIImage = badge(twist) { context, rect in
        let r = rect.width*0.085
        for (x, y) in [(0.5, 0.3), (0.3, 0.5), (0.7, 0.5), (0.38, 0.72), (0.62, 0.72)] {
            dot(context, at: CGPoint(x: rect.minX + rect.width*x,
                                     y: rect.minY + rect.height*y), radius: r)
        }
    }

    /// Sudden Death: the run, crossed out.
    static let twistSuddenDeath: UIImage = badge(twist) { context, rect in
        stroke(context, width: rect.width*0.09)
        context.move(to: CGPoint(x: rect.minX + rect.width*0.3, y: rect.minY + rect.height*0.3))
        context.addLine(to: CGPoint(x: rect.maxX - rect.width*0.3, y: rect.maxY - rect.height*0.3))
        context.move(to: CGPoint(x: rect.maxX - rect.width*0.3, y: rect.minY + rect.height*0.3))
        context.addLine(to: CGPoint(x: rect.minX + rect.width*0.3, y: rect.maxY - rect.height*0.3))
        context.strokePath()
    }

    /// Spare Balls: the ball in play, and the two racked behind it.
    static let twistSpareBalls: UIImage = badge(twist) { context, rect in
        dot(context, at: CGPoint(x: rect.midX, y: rect.minY + rect.height*0.34),
            radius: rect.width*0.13)
        let r = rect.width*0.085
        dot(context, at: CGPoint(x: rect.midX - rect.width*0.14, y: rect.maxY - rect.height*0.28), radius: r)
        dot(context, at: CGPoint(x: rect.midX + rect.width*0.14, y: rect.maxY - rect.height*0.28), radius: r)
    }

    /// No Power-Ups: the pickup, barred.
    static let twistNoPowerUps: UIImage = badge(twist) { context, rect in
        stroke(context, width: rect.width*0.07)
        let radius = rect.width*0.24
        context.strokeEllipse(in: CGRect(x: rect.midX - radius, y: rect.midY - radius,
                                         width: radius*2, height: radius*2))
        context.move(to: CGPoint(x: rect.midX - radius*0.7, y: rect.midY + radius*0.7))
        context.addLine(to: CGPoint(x: rect.midX + radius*0.7, y: rect.midY - radius*0.7))
        context.strokePath()
    }

    /// No Good News: only the bad ones fall.
    static let twistNoGoodNews: UIImage = badge(twist) { context, rect in
        stroke(context, width: rect.width*0.08)
        let x = rect.midX
        context.move(to: CGPoint(x: x, y: rect.minY + rect.height*0.26))
        context.addLine(to: CGPoint(x: x, y: rect.maxY - rect.height*0.3))
        context.move(to: CGPoint(x: x - rect.width*0.14, y: rect.maxY - rect.height*0.44))
        context.addLine(to: CGPoint(x: x, y: rect.maxY - rect.height*0.3))
        context.addLine(to: CGPoint(x: x + rect.width*0.14, y: rect.maxY - rect.height*0.44))
        context.strokePath()
        // A falling arrow: what is coming down is not good
    }

    /// No Bad News: only the good ones fall.
    static let twistNoBadNews: UIImage = badge(twist) { context, rect in
        stroke(context, width: rect.width*0.08)
        let x = rect.midX
        context.move(to: CGPoint(x: x, y: rect.maxY - rect.height*0.26))
        context.addLine(to: CGPoint(x: x, y: rect.minY + rect.height*0.3))
        context.move(to: CGPoint(x: x - rect.width*0.14, y: rect.minY + rect.height*0.44))
        context.addLine(to: CGPoint(x: x, y: rect.minY + rect.height*0.3))
        context.addLine(to: CGPoint(x: x + rect.width*0.14, y: rect.minY + rect.height*0.44))
        context.strokePath()
    }

    /// Power Shower: the drops, everywhere.
    static let twistPowerShower: UIImage = badge(twist) { context, rect in
        stroke(context, width: rect.width*0.07)
        for (x, top) in [(0.3, 0.24), (0.5, 0.34), (0.7, 0.24)] {
            let lineX = rect.minX + rect.width*x
            context.move(to: CGPoint(x: lineX, y: rect.minY + rect.height*top))
            context.addLine(to: CGPoint(x: lineX, y: rect.minY + rect.height*(top + 0.18)))
            context.strokePath()
            dot(context, at: CGPoint(x: lineX, y: rect.minY + rect.height*(top + 0.42)),
                radius: rect.width*0.06)
        }
        // Three streaks with drops beneath - rain, in the set's own vocabulary
    }

    /// Drought: one drop, a long way apart from the next.
    static let twistDrought: UIImage = badge(twist) { context, rect in
        stroke(context, width: rect.width*0.06)
        for x in [0.3, 0.5, 0.7] {
            let dashX = rect.minX + rect.width*x
            context.move(to: CGPoint(x: dashX, y: rect.minY + rect.height*0.3))
            context.addLine(to: CGPoint(x: dashX, y: rect.minY + rect.height*0.38))
            context.strokePath()
        }
        dot(context, at: CGPoint(x: rect.midX, y: rect.maxY - rect.height*0.28),
            radius: rect.width*0.06)
        // The shower's shape with almost everything missing
    }

    /// Fog of War: a brick you cannot see yet.
    static let twistFogOfWar: UIImage = badge(twist) { context, rect in
        stroke(context, width: rect.width*0.06)
        context.setLineDash(phase: 0, lengths: [rect.width*0.1, rect.width*0.08])
        context.stroke(CGRect(x: rect.minX + rect.width*0.24, y: rect.midY - rect.height*0.13,
                              width: rect.width*0.52, height: rect.height*0.26))
        context.setLineDash(phase: 0, lengths: [])
        // A brick drawn in dashes: there, but not shown until struck
    }

    /// Vanilla: the app icon itself (play-test round 11: "for vanilla icon, just use app
    /// icon") - the plain game is the game. The drawn brick-and-ball stays as the
    /// fallback for the unlikely build where the icon files cannot be read.
    static let twistVanilla: UIImage = {
        if let icon = GameMode.appIconArtwork { return icon }
        // The app's own icon, read from the one copy of it the app can load - see
        // GameMode.appIconArtwork. It used to go through CFBundleIcons, which returns
        // the small home-screen sizes rather than the artwork
        return badge(twist) { context, rect in
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(x: rect.minX + rect.width*0.22,
                                y: rect.midY + rect.height*0.04,
                                width: rect.width*0.56, height: rect.height*0.18))
            dot(context, at: CGPoint(x: rect.midX, y: rect.midY - rect.height*0.22),
                radius: rect.width*0.1)
            // The whole game in two marks: a brick, and the ball on its way to it
        }
    }()

    // MARK: - Drawing helpers


    private static func stroke(_ context: CGContext, width: CGFloat) {
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
    }

    private static func dot(_ context: CGContext, at centre: CGPoint, radius: CGFloat) {
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                       width: radius*2, height: radius*2))
    }

    /// The rounded square every power-up icon is, with a glyph drawn into it.
    ///
    /// Green unless told otherwise - the harmful ones wear the same red the falling assets
    /// do, so what a power-up will do to you is readable before it does it.
    private static func badge(_ colour: UIColor = beneficial,
                              _ glyph: (CGContext, CGRect) -> Void) -> UIImage {
        UIGraphicsImageRenderer(size: canvas).image { context in
            let rect = CGRect(origin: .zero, size: canvas).insetBy(dx: 4, dy: 4)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.width*0.22)
            colour.setFill()
            path.fill()
            glyph(context.cgContext, rect)
        }
    }
}

extension DailyTwist {

    /// The twist's badge, everywhere a twist is named: the briefing screen, the pause
    /// summary, the level intro.
    ///
    /// On the type rather than looked up by the screens, so a new twist cannot compile
    /// without answering for its icon - the switch has no default for exactly that reason.
    var icon: UIImage {
        switch self {
        case .oneLife: return PowerUpIcon.twistOneLife
        case .loaded: return PowerUpIcon.twistLoaded
        case .suddenDeath: return PowerUpIcon.twistSuddenDeath
        case .spareBalls: return PowerUpIcon.twistSpareBalls
        case .noPowerUps: return PowerUpIcon.twistNoPowerUps
        case .noGoodNews: return PowerUpIcon.twistNoGoodNews
        case .noBadNews: return PowerUpIcon.twistNoBadNews
        case .powerShower: return PowerUpIcon.twistPowerShower
        case .drought: return PowerUpIcon.twistDrought
        case .fogOfWar: return PowerUpIcon.twistFogOfWar
        }
    }

    /// The twist's name with its badge in front, sized to sit in a line of the given font.
    ///
    /// One builder for every screen that lists twists, so they cannot drift apart in how
    /// a twist reads. The icon rides slightly below the baseline, which is where a glyph
    /// the height of a capital sits without looking like it is floating.
    func titleLine(font: UIFont, colour: UIColor) -> NSAttributedString {
        DailyTwist.badgedLine(icon: icon, name: displayName, font: font, colour: colour)
    }

    /// What a day with no twists is called, and its badge.
    ///
    /// A baseline day is a *kind* of day, not an absence of one - the play test asked for
    /// it to be named and iconned like any twist, which is also what §3 means by "the
    /// baseline day is what makes twist days feel like twists".
    static let vanillaName = "Vanilla"
    static let vanillaBlurb = "No twists - the game exactly as it comes."

    static func vanillaLine(font: UIFont, colour: UIColor) -> NSAttributedString {
        badgedLine(icon: PowerUpIcon.twistVanilla, name: vanillaName, font: font,
                   colour: colour)
    }

    /// One builder for every screen that names a twist, so they cannot drift apart in how
    /// a twist reads. The icon rides slightly below the baseline, which is where a glyph
    /// the height of a capital sits without looking like it is floating.
    static func badgedLine(icon: UIImage, name: String, font: UIFont,
                           colour: UIColor) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = icon
        let side = font.capHeight*1.5
        attachment.bounds = CGRect(x: 0, y: (font.capHeight - side)/2,
                                   width: side, height: side)

        let line = NSMutableAttributedString(attachment: attachment)
        line.append(NSAttributedString(string: "  \(name)",
                                       attributes: [.font: font,
                                                    .foregroundColor: colour]))
        return line
    }
}
