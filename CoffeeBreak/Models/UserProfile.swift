import Foundation

/// Local persistent profile. Tracks lifetime stats across all networks
/// this Mac has joined. Never leaves the device.
struct UserProfile: Codable, Equatable {
    /// Stable per-device identity (same UUID used as the Bonjour peer ID).
    let id: UUID
    var displayName: String
    var avatarEmoji: String?
    var createdAt: Date

    /// Total coffees ever logged on this device.
    var lifetimeCoffees: Int
    /// Per-day counts keyed by `yyyy-MM-dd` so we can compute today / week.
    var coffeesByDate: [String: Int]
    /// Per-day count of cups that happened in runs *we organized* —
    /// either our own cup during our own run, or a joiner's cup while
    /// they were in our run. This is the "coffees sparked by you" metric.
    var sparkedByDate: [String: Int] = [:]
    /// Distinct peer IDs we've ever broadcast alongside on any network.
    var peopleMet: Set<UUID>
    /// Timestamp of the most recent coffee logged.
    var lastCoffeeAt: Date?
    /// Bumped whenever displayName / avatarEmoji is changed locally —
    /// last-writer-wins on cross-device merges.
    var metadataUpdatedAt: Date = .distantPast

    /// Coffee groups this user is currently a member of.
    var joinedGroups: [CoffeeGroup] = []
    /// Outstanding invites this user has sent. Cleared when the invitee
    /// shows up as a member of the group on the network.
    var pendingInvitesSent: [PendingInvite] = []
    /// Group IDs the user explicitly declined — we suppress further
    /// notifications for these.
    var declinedGroupInvites: Set<UUID> = []

    // MARK: - Derived stats

    var coffeesToday: Int {
        coffeesByDate[Self.dateKey(for: Date())] ?? 0
    }

    var coffeesThisWeek: Int {
        let calendar = Calendar.current
        let today = Date()
        var sum = 0
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            sum += coffeesByDate[Self.dateKey(for: date)] ?? 0
        }
        return sum
    }

    /// Sum of "sparked" cups (cups in runs we organized) across the last
    /// 7 days. This is the headline number on the personal stat tile.
    var sparkedThisWeek: Int {
        let calendar = Calendar.current
        let today = Date()
        var sum = 0
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            sum += sparkedByDate[Self.dateKey(for: date)] ?? 0
        }
        return sum
    }

    /// Today's sparked count.
    var sparkedToday: Int {
        sparkedByDate[Self.dateKey(for: Date())] ?? 0
    }

    /// Distinct dates on which at least one coffee was logged.
    var daysActive: Int {
        coffeesByDate.values.filter { $0 > 0 }.count
    }

    /// Count of consecutive days ending today (or yesterday if today has
    /// no coffee yet) on which at least one cup was logged. A "3 day streak"
    /// means three calendar days in a row.
    var coffeeStreak: Int {
        Self.streakLength(in: coffeesByDate)
    }

    /// Streak of consecutive days on which we sparked at least one cup —
    /// i.e. organized a coffee run that resulted in someone (us or a joiner)
    /// having a coffee. This is what the personal tile shows.
    var sparkedStreak: Int {
        Self.streakLength(in: sparkedByDate)
    }

    private static func streakLength(in counts: [String: Int]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checking = Date()
        if (counts[Self.dateKey(for: checking)] ?? 0) == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checking) else { return 0 }
            checking = yesterday
        }
        while (counts[Self.dateKey(for: checking)] ?? 0) > 0 {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checking) else { break }
            checking = prev
            if streak > 365 { break }   // safety
        }
        return streak
    }

    /// This-week-vs-last-week delta in cups. Positive = up, negative = down.
    var weeklyDelta: Int {
        let cal = Calendar.current
        let now = Date()
        func sumDays(offset: Int, count: Int) -> Int {
            var total = 0
            for i in 0..<count {
                guard let d = cal.date(byAdding: .day, value: -(offset + i), to: now) else { continue }
                total += coffeesByDate[Self.dateKey(for: d)] ?? 0
            }
            return total
        }
        return sumDays(offset: 0, count: 7) - sumDays(offset: 7, count: 7)
    }

    // MARK: - Mutation

    mutating func recordCoffee(at date: Date = Date()) {
        let key = Self.dateKey(for: date)
        coffeesByDate[key, default: 0] += 1
        lifetimeCoffees += 1
        lastCoffeeAt = date
    }

    /// Credit one cup as "sparked by us." Called once per cup we lit:
    /// our own cup during our own run, or a joiner's cup while they're
    /// in our run.
    mutating func recordSparkedCup(at date: Date = Date()) {
        let key = Self.dateKey(for: date)
        sparkedByDate[key, default: 0] += 1
    }

    mutating func noteSeen(peerID: UUID) {
        peopleMet.insert(peerID)
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()

    static func dateKey(for date: Date) -> String {
        dateFormatter.string(from: date)
    }

    // MARK: - Cross-device merge (CRDT-ish semantics)

    /// Combine a local copy with a remote (cloud) copy.
    ///   - Counts use **max per date** so neither side loses logs.
    ///   - Sets are **unioned**.
    ///   - Timestamps pick the **most recent** event (and earliest creation).
    ///   - Display name / avatar use last-writer-wins via `metadataUpdatedAt`.
    static func merged(local: UserProfile, remote: UserProfile) -> UserProfile {
        let allDates = Set(local.coffeesByDate.keys).union(remote.coffeesByDate.keys)
        var mergedDates: [String: Int] = [:]
        for date in allDates {
            mergedDates[date] = max(local.coffeesByDate[date] ?? 0, remote.coffeesByDate[date] ?? 0)
        }
        let mergedLifetime = max(
            mergedDates.values.reduce(0, +),
            max(local.lifetimeCoffees, remote.lifetimeCoffees)
        )
        // Same max-per-date rule for sparked counts so cross-device sync
        // keeps the larger of the two values per day.
        let allSparkedDates = Set(local.sparkedByDate.keys).union(remote.sparkedByDate.keys)
        var mergedSparked: [String: Int] = [:]
        for date in allSparkedDates {
            mergedSparked[date] = max(local.sparkedByDate[date] ?? 0, remote.sparkedByDate[date] ?? 0)
        }

        let metaWinner = (remote.metadataUpdatedAt > local.metadataUpdatedAt) ? remote : local
        // Merge groups by id; keep most-recent join date.
        var groupsByID: [UUID: CoffeeGroup] = [:]
        for g in local.joinedGroups + remote.joinedGroups {
            if let existing = groupsByID[g.id], existing.joinedAt > g.joinedAt {
                continue
            }
            groupsByID[g.id] = g
        }
        return UserProfile(
            id: local.id,  // local identity wins — this is "my" profile on this device
            displayName: metaWinner.displayName,
            avatarEmoji: metaWinner.avatarEmoji,
            createdAt: min(local.createdAt, remote.createdAt),
            lifetimeCoffees: mergedLifetime,
            coffeesByDate: mergedDates,
            sparkedByDate: mergedSparked,
            peopleMet: local.peopleMet.union(remote.peopleMet),
            lastCoffeeAt: [local.lastCoffeeAt, remote.lastCoffeeAt].compactMap { $0 }.max(),
            metadataUpdatedAt: max(local.metadataUpdatedAt, remote.metadataUpdatedAt),
            joinedGroups: Array(groupsByID.values).sorted { $0.joinedAt < $1.joinedAt },
            pendingInvitesSent: Array(Set(local.pendingInvitesSent).union(remote.pendingInvitesSent)),
            declinedGroupInvites: local.declinedGroupInvites.union(remote.declinedGroupInvites)
        )
    }
}
