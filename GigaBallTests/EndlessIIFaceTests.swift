//
//  EndlessIIFaceTests.swift
//  GigaBallTests
//
//  The shaped bricks (§12.0's brick geometries) rest on two rules that are invisible on
//  screen until they are broken, and break in ways that look like something else:
//
//  A body piece that is not convex is silently mangled by `SKPhysicsBody(polygonFrom:)` -
//  the brick keeps a shape but bounces off a different one, which reads as "the physics is
//  wrong" rather than as "the path is wrong".
//
//  A hiding rectangle that is not inside the silhouette leaves a corner of the sprite
//  poking out of the shape, which reads as a drawing glitch.
//
//  Both are pure geometry, so both are checked here rather than eyeballed on a device.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIFaceTests: XCTestCase {

    /// A cell, at the proportions the game uses: twice as wide as it is tall.
    private let cell = CGSize(width: 40, height: 20)

    func testEveryBodyPieceIsConvex() {
        for face in EndlessIIFace.allCases {
            for mirrored in [false, true] {
                for piece in EndlessIIFaceGeometry.bodyPieces(face, size: cell,
                                                              mirrored: mirrored) {
                    var points: [CGPoint] = []
                    piece.applyWithBlock { element in
                        let type = element.pointee.type
                        if type == .moveToPoint || type == .addLineToPoint {
                            points.append(element.pointee.points[0])
                        }
                    }
                    XCTAssertTrue(EndlessIIFaceGeometry.isConvex(points),
                                  "\(face) mirrored:\(mirrored) has a piece a polygon body cannot take")
                }
            }
        }
    }

    func testTheSpriteHidesInsideTheFace() {
        // The rule the Wedge exists to break: its hypotenuse runs through the node's own
        // centre, so no centred rectangle fits inside it and the hiding rectangle has to
        // be off-centre. Checked for every face, both ways round.
        for face in EndlessIIFace.allCases {
            for mirrored in [false, true] {
                let silhouette = EndlessIIFaceGeometry.silhouette(face, size: cell,
                                                                  mirrored: mirrored)
                let hide = EndlessIIFaceGeometry.hidingRect(face, size: cell,
                                                            mirrored: mirrored)
                let corners = [CGPoint(x: hide.minX, y: hide.minY),
                               CGPoint(x: hide.maxX, y: hide.minY),
                               CGPoint(x: hide.maxX, y: hide.maxY),
                               CGPoint(x: hide.minX, y: hide.maxY)]
                for corner in corners {
                    XCTAssertTrue(silhouette.contains(corner),
                                  "\(face) mirrored:\(mirrored) leaves \(corner) outside its own face")
                }
                XCTAssertGreaterThan(hide.width, 0)
                XCTAssertGreaterThan(hide.height, 0)
            }
        }
    }

    func testTheWedgeIsTheOnlyFaceWhoseSpriteSitsOffCentre() {
        // Which is the whole reason hiding rectangles are rectangles rather than a scale
        // factor. If a dome or a notch ever needs an offset too, this is the reminder to
        // check that nothing else assumed the sprite was centred.
        for face in EndlessIIFace.allCases {
            let hide = EndlessIIFaceGeometry.hidingRect(face, size: cell)
            let centred = abs(hide.midX) < 0.001 && abs(hide.midY) < 0.001
            XCTAssertEqual(centred, face != .wedge, "\(face)")
        }
    }

    func testMirroringAWedgeReflectsItRatherThanMovingIt() {
        let right = EndlessIIFaceGeometry.corners(.wedge, size: cell)
        let left = EndlessIIFaceGeometry.corners(.wedge, size: cell, mirrored: true)
        XCTAssertEqual(Set(right.map { abs($0.x) }), Set(left.map { abs($0.x) }))
        XCTAssertEqual(right.map(\.x).reduce(0, +), -left.map(\.x).reduce(0, +),
                       accuracy: 0.001, "a mirrored wedge points the other way")
    }

    func testTheFaceAndStyleNamesAreOneToOne() {
        // The one place the two vocabularies meet. A face that lost its style would be a
        // shape the reference page, the recents and the compatibility grid never mention
        for face in EndlessIIFace.allCases {
            XCTAssertEqual(face.style.face, face)
        }
        let faceStyles = EndlessIIStyle.allCases.filter(\.isFace)
        XCTAssertEqual(faceStyles.count, EndlessIIFace.allCases.count)
    }

    // MARK: - How they combine

    func testAShapedBrickRefusesEverythingThatWouldRedrawOrMoveIt() {
        for face in EndlessIIFace.allCases {
            let style = face.style
            for other in EndlessIIStyle.refusedByAFace {
                XCTAssertFalse(style.stacksWith(other), "\(style) must not stack with \(other)")
                XCTAssertFalse(other.stacksWith(style), "and the rule reads both ways")
            }
        }
    }

    func testTwoShapesNeverShareABrick() {
        for face in EndlessIIFace.allCases {
            for other in EndlessIIFace.allCases {
                XCTAssertFalse(face.style.stacksWith(other.style),
                               "two shapes are two answers to the same question")
            }
        }
    }

    func testAShapeStillStacksWithWhatItDoesNotTouch() {
        // Colour, alpha and neighbours are none of a shape's business, so these three stay
        // available - a flashing wedge and an exploding dome are the point of having an
        // axis at all
        for face in EndlessIIFace.allCases {
            for other: EndlessIIStyle in [.flashing, .exploding, .spawner] {
                XCTAssertTrue(face.style.stacksWith(other), "\(face) should stack with \(other)")
            }
        }
    }

    func testAShapeGoesOnAnyBehaviourButInvisible() {
        for face in EndlessIIFace.allCases {
            XCTAssertFalse(face.style.suits(.invisible),
                           "a slope nobody can see is a slope nobody can aim off")
            for behaviour: EndlessIIBehaviour in [.standard, .multiHit, .indestructibleOnce,
                                                  .indestructibleAlways] {
                XCTAssertTrue(face.style.suits(behaviour), "\(face) on \(behaviour)")
            }
        }
    }
}
