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

    /// The green every beneficial power-up wears.
    static let beneficial = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 1)

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

    /// The rounded square every power-up icon is, with a glyph drawn into it.
    private static func badge(_ glyph: (CGContext, CGRect) -> Void) -> UIImage {
        UIGraphicsImageRenderer(size: canvas).image { context in
            let rect = CGRect(origin: .zero, size: canvas).insetBy(dx: 4, dy: 4)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.width*0.22)
            beneficial.setFill()
            path.fill()
            glyph(context.cgContext, rect)
        }
    }
}
