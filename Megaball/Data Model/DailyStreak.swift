//
//  DailyStreak.swift
//  Megaball
//
//  How many days in a row the player has posted a daily.
//
//  §7: "Streaks are tracked locally (§10) and surfaced on the challenge screen", and §14 calls
//  them "the single strongest retention mechanic a daily can have".
//
//  ## Derived, not stored
//
//  §10 lists `dailyStreak` and `longestStreak` as fields to add to `TotalStats`, alongside the
//  per-day records. They are not added, because the records already answer: every one carries
//  its `dateKey` and whether it `posted`, and a streak is a question about that list rather than
//  a separate fact about the player.
//
//  Storing it would mean two more numbers in the iCloud arrays - "the trap that crashed sync
//  once already", in §10's own words - and, worse, two numbers that can disagree with the
//  history they are counting. A device that syncs a day it missed would have to know to
//  recompute them; one that did not would carry a streak its own records deny. Asked of the
//  records, the answer is right by construction on every device, including one that has just
//  merged another's history.
//
//  ## What counts, and where a streak ends
//
//  **A posted day.** Not a day played - practice is playable all day and posting is the thing
//  the board is about, so a streak of days somebody opened would be a streak of nothing.
//
//  **Today not being played does not break it.** The day is not over. So the current streak
//  counts back from today if today is posted, and from yesterday if it is not - and is zero
//  only once yesterday has been missed as well. Anything else would show a player their streak
//  broken every morning until they played.
//
//  Everything is in UTC, like every other date in this feature: the day boundary is the board's
//  reset, not the player's midnight.
//

import Foundation

enum DailyStreak {

    /// How many days in a row, ending today or yesterday, the player has posted.
    static func current(records: [DailyChallengeRecord], today: Date) -> Int {
        let posted = postedKeys(records)
        guard posted.isEmpty == false else { return 0 }

        let start = DailyDay.utcCalendar.startOfDay(for: today)
        guard var day = posted.contains(DailyDay.key(for: start))
                ? start
                : DailyDay.utcCalendar.date(byAdding: .day, value: -1, to: start)
        else { return 0 }
        guard posted.contains(DailyDay.key(for: day)) else { return 0 }
        // Yesterday is the last day a streak can still be alive on. Missing both it and today
        // is the streak being over rather than being in progress

        var length = 0
        while posted.contains(DailyDay.key(for: day)) {
            length += 1
            guard let before = DailyDay.utcCalendar.date(byAdding: .day, value: -1, to: day)
            else { break }
            day = before
        }
        return length
    }

    /// The longest run of consecutive posted days there has ever been.
    ///
    /// Walked over the sorted keys rather than by counting days between dates, so a history
    /// with a decade of gaps in it costs no more than a dense one.
    static func longest(records: [DailyChallengeRecord]) -> Int {
        let posted = postedKeys(records).sorted()
        guard posted.isEmpty == false else { return 0 }

        var best = 1, run = 1
        for (earlier, later) in zip(posted, posted.dropFirst()) {
            run = isTheDayAfter(later, earlier) ? run + 1 : 1
            best = max(best, run)
        }
        return best
    }

    /// Whether the second key is the day immediately after the first.
    ///
    /// Asked through the calendar rather than by comparing strings, because "the day after
    /// 2026-02-28" is a question only a calendar can answer.
    static func isTheDayAfter(_ later: String, _ earlier: String) -> Bool {
        guard let start = date(fromKey: earlier),
              let next = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: start)
        else { return false }
        return DailyDay.key(for: next) == later
    }

    /// A date key read back into the day it names. Nil for anything that is not one.
    ///
    /// **Checked by writing the answer back out.** `Calendar.date(from:)` is lenient: handed a
    /// 30th of February it does not refuse, it rolls forward and returns the 2nd of March. Keys
    /// the app writes are always real days, but records arrive off disk and out of iCloud, and
    /// a corrupted one silently becoming a different day is a day that could join a streak it
    /// has nothing to do with. If the date does not spell the key back, the key was not a day.
    static func date(fromKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = DailyDay.utcCalendar.date(from: DateComponents(year: parts[0],
                                                                        month: parts[1],
                                                                        day: parts[2])),
              DailyDay.key(for: date) == key
        else { return nil }
        return date
    }

    private static func postedKeys(_ records: [DailyChallengeRecord]) -> Set<String> {
        Set(records.filter { $0.posted }.map(\.dateKey))
    }
}
