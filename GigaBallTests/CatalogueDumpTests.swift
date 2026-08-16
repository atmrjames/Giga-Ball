//
//  CatalogueDumpTests.swift
//  GigaBallTests
//
//  Checks the three catalogues are complete, and - when asked - writes them out as JSON so
//  the design workbook (Giga-Ball 2026.xlsx) can be generated from the game rather than
//  transcribed from it. A document typed out by hand is wrong the first time anything
//  changes; one generated from these tables cannot be.
//
//  The write is behind an environment variable, because a test that leaves files behind on
//  every run is a test with a side effect. To refresh the workbook's data:
//
//      GIGABALL_DUMP=/tmp/gigaball-catalogue.json xcodebuild ... \
//          -only-testing:GigaBallTests/CatalogueDumpTests test
//

import XCTest
@testable import Giga_Ball

final class CatalogueDumpTests: XCTestCase {

    func testEveryCatalogueIsComplete() throws {
        let setup = LevelPackSetup()
        var powerUps: [[String: Any]] = []

        for index in setup.powerUpNameArray.indices {
            let name = setup.powerUpNameArray[index]
            let entry = PowerUpCatalogue.all.first { $0.name == name }
            powerUps.append([
                "index": index,
                "name": name,
                "description": setup.powerUpDescriptionArray[index],
                "multiplier": setup.powerUpMultiplierArray[index],
                "timer": setup.powerUpTimerArray[index],
                "valence": entry.map { "\($0.valence)" } ?? "",
                "rarity": entry.map { "\($0.rarity)" } ?? "",
                "isTimed": entry?.isTimed ?? false,
                "stacking": entry.map { "\($0.stacking)" } ?? "",
                "conflict": entry?.conflict.map { "\($0)" } ?? "",
                "availability": entry.map { "\($0.availability)" } ?? "",
                "hidden": setup.powerUpHiddenUnlockedDescriptionArray[index],
                "unlock": setup.powerUpUnlockedDescriptionArray[index],
            ])
        }

        var styles: [[String: Any]] = []
        for style in EndlessIIStyle.allCases {
            styles.append([
                "name": BrickTypeCatalogue.name(of: style),
                "raw": style.rawValue,
                "description": BrickTypeCatalogue.allEntries.first { $0.name == BrickTypeCatalogue.name(of: style) }?.description ?? "",
                "stacks": EndlessIIStyle.allCases.filter { style.stacksWith($0) }
                    .map { BrickTypeCatalogue.name(of: $0) },
                "suits": [EndlessIIBehaviour.standard, .multiHit, .indestructibleOnce,
                          .indestructibleAlways, .invisible]
                    .filter { style.suits($0) }.map { "\($0)" },
                "firesOnHit": style.firesOnHit(with: .indestructibleAlways),
            ])
        }

        var twists: [[String: Any]] = []
        for twist in DailyTwist.allCases {
            twists.append([
                "name": twist.displayName,
                "raw": twist.rawValue,
                "blurb": twist.blurb,
                "category": "\(twist.category)",
                "weight": twist.weight,
                "modes": [GameMode.classic, .endless, .endlessII]
                    .filter { twist.applies(to: $0) }.map { $0.name },
            ])
        }

        var bricks: [[String: Any]] = []
        for section in BrickTypeCatalogue.sections {
            for entry in section.entries {
                bricks.append([
                    "section": section.title,
                    "name": entry.name,
                    "description": entry.description,
                    "isNew": entry.isNew,
                    "facts": entry.facts.map { ["label": $0.label, "value": $0.value] },
                ])
            }
        }

        let dump: [String: Any] = ["powerUps": powerUps, "styles": styles,
                                   "twists": twists, "bricks": bricks]
        XCTAssertEqual(powerUps.count, LevelPackSetup().powerUpNameArray.count)
        XCTAssertEqual(styles.count, EndlessIIStyle.allCases.count)
        XCTAssertEqual(twists.count, DailyTwist.allCases.count)
        XCTAssertEqual(bricks.count, BrickTypeCatalogue.allEntries.count)
        for entry in powerUps {
            XCTAssertFalse((entry["description"] as? String ?? "").isEmpty,
                           "\(entry["name"] ?? "") has no description for the reference page "
                           + "or the workbook")
        }

        guard let path = ProcessInfo.processInfo.environment["GIGABALL_DUMP"] else { return }
        let data = try JSONSerialization.data(withJSONObject: dump,
                                              options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: path))
    }
}
