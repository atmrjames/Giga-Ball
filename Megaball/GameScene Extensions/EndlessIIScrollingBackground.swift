//
//  EndlessIIScrollingBackground.swift
//  Megaball
//
//  The backdrop that climbs with the run (§7.2).
//
//  Endless Mayhem's score is height, and nothing on screen ever said so: the field descends
//  but the world stands still. This scrolls a backdrop downward as the run climbs - slower
//  than the field moves, which is what makes it read as distance rather than as another
//  moving part.
//
//  Two copies of one tile leapfrog each other, so the image only has to loop vertically.
//  The scene file's own background node will not accept a new texture at runtime (§7.2), so
//  this is a code-owned pair from the start, sitting just above the painted background and
//  below everything that plays.
//
//  The artwork is a named asset slot - see §8.5. Until the real tile lands, a drawn
//  placeholder takes its place: a dim vertical gradient mirrored so it loops, deliberately
//  quiet, because a backdrop that competes with the field is worse than none. Drop an asset
//  named `EndlessMayhemBackdrop` into the catalogue and it is used instead, untouched.
//

import SpriteKit

/// Where the two tiles sit for a given scroll. Pure, so the leapfrog is testable.
enum EndlessIIBackdropScroll {

    /// How many points the backdrop moves per metre climbed.
    ///
    /// Well under the field's own row-per-metre, which is what makes it parallax: the field
    /// is near, the backdrop is far, and the difference in their speeds is the depth.
    static let pointsPerMetre: CGFloat = 6

    /// The y offsets of the two tiles, for a backdrop whose scroll has reached this far.
    ///
    /// The pair covers the screen at every scroll value: the first tile starts at zero and
    /// rises as the run climbs (the world moving down is the tile moving up through the
    /// window), wrapping a tile at a time; the second sits one tile below the first.
    static func tileYs(scroll: CGFloat, tileHeight: CGFloat) -> (first: CGFloat, second: CGFloat) {
        guard tileHeight > 0 else { return (0, 0) }
        let wrapped = scroll.truncatingRemainder(dividingBy: tileHeight)
        return (wrapped, wrapped - tileHeight)
    }
}

extension GameScene {

    /// The asset slot the real artwork fills (§8.5). A vertically-looping tile.
    static let endlessIIBackdropAssetName = "EndlessMayhemBackdrop"

    /// Puts the backdrop pair up, behind everything that plays. Endless Mayhem only.
    func setupEndlessIIBackdrop() {
        guard gameMode == .endlessII, endlessIIBackdropTiles.isEmpty else { return }

        let texture = endlessIIBackdropTexture()
        let height = frame.height
        for index in 0..<2 {
            let tile = SKSpriteNode(texture: texture)
            tile.size = CGSize(width: frame.width, height: height)
            tile.anchorPoint = CGPoint(x: 0.5, y: 0)
            tile.position = CGPoint(x: 0, y: -frame.height/2 + CGFloat(index)*height)
            tile.zPosition = 0.6
            // Above the painted background overlay (0.5), below the bricks and the field's
            // own furniture (1) - the layer the run climbs past
            addChild(tile)
            endlessIIBackdropTiles.append(tile)
        }
    }

    /// Scrolls the backdrop toward where the current height puts it.
    ///
    /// Eased rather than stepped: the field descends a row at a time, and a backdrop that
    /// jumped with it would read as attached to it. The easing makes it drift - the far
    /// thing catching up with the near thing.
    func tickEndlessIIBackdrop() {
        guard gameMode == .endlessII, endlessIIBackdropTiles.count == 2 else { return }

        let target = CGFloat(endlessHeight)*EndlessIIBackdropScroll.pointsPerMetre
        endlessIIBackdropScroll += (target - endlessIIBackdropScroll)*0.04
        // Four percent of the gap per frame: a row's worth of climb settles in about a
        // second, and a Descent's worth keeps drifting long after the burst

        let height = endlessIIBackdropTiles[0].size.height
        let ys = EndlessIIBackdropScroll.tileYs(scroll: endlessIIBackdropScroll,
                                                tileHeight: height)
        let floor = -frame.height/2
        endlessIIBackdropTiles[0].position.y = floor + ys.first
        endlessIIBackdropTiles[1].position.y = floor + ys.second
    }

    func endlessIIResetBackdrop() {
        endlessIIBackdropScroll = 0
        endlessIIBackdropTiles.forEach { $0.removeFromParent() }
        endlessIIBackdropTiles.removeAll()
    }

    /// The real tile if the asset exists, the quiet placeholder if not.
    private func endlessIIBackdropTexture() -> SKTexture {
        if let image = UIImage(named: GameScene.endlessIIBackdropAssetName) {
            return SKTexture(image: image)
        }

        let size = CGSize(width: 64, height: 512)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let colours = [UIColor(white: 1, alpha: 0.0).cgColor,
                           UIColor(red: 0.5, green: 0.9, blue: 0.4, alpha: 0.05).cgColor,
                           UIColor(white: 1, alpha: 0.0).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colours as CFArray,
                                      locations: [0, 0.5, 1])!
            context.cgContext.drawLinearGradient(gradient,
                                                 start: .zero,
                                                 end: CGPoint(x: 0, y: size.height),
                                                 options: [])
        }
        return SKTexture(image: image)
        // Symmetric top to bottom, so the loop has no seam. Barely-there on purpose: the
        // placeholder's job is to prove the scroll works, not to be the artwork
    }
}
