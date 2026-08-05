//
//  StatsSync.swift
//  Megaball
//
//  Decides which side of an iCloud stats sync wins.
//
//  The sync merges by taking the highest value for every counter and OR-ing
//  every unlock flag, in both directions. For stats that only ever grow that
//  is right, and it needs no coordination between devices.
//
//  It cannot express a reset. Zeroing the stats on one device writes zeros to
//  iCloud, but the next device to sync merges its own larger numbers back up,
//  and the first device then pulls them down again - so the reset either
//  silently undoes itself or wipes the other device, depending on which
//  syncs first. A date was already stored alongside the data but never
//  compared, so nothing arbitrated.
//
//  A generation number does. It is incremented on reset and only then, so
//  "my generation is higher" means "my state supersedes yours" rather than
//  "my numbers are bigger".
//

import Foundation

enum SyncResolution: Equatable {
    /// Same generation: merge by highest value, as before.
    case merge
    /// The other device has reset since this one last did. Take its state whole,
    /// including values lower than the local ones.
    case adoptCloud
    /// This device has reset since the cloud copy. Its state wins, and merging
    /// would resurrect the numbers the reset cleared.
    case pushLocal
}

enum StatsSync {

    /// Where the generation is stored, in UserDefaults and in the key-value store.
    static let generationKey = "statsGeneration"

    /// Devices that have never reset are all at generation zero and merge as
    /// they always did, so this changes nothing until someone resets.
    static let initialGeneration = 0

    static func resolve(localGeneration: Int, cloudGeneration: Int) -> SyncResolution {
        if localGeneration > cloudGeneration { return .pushLocal }
        if cloudGeneration > localGeneration { return .adoptCloud }
        return .merge
    }

    /// The generation to write when resetting.
    ///
    /// Takes the higher of the two sides first, so a reset on a device that has
    /// not yet pulled a newer generation still supersedes it rather than
    /// colliding with it.
    static func generationAfterReset(localGeneration: Int, cloudGeneration: Int) -> Int {
        max(localGeneration, cloudGeneration) + 1
    }
}
