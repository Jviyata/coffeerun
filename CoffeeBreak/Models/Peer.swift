import Foundation

struct Peer: Identifiable, Equatable, Hashable {
    let id: UUID
    let displayName: String
    let status: CoffeeStatus
    let timestamp: Date
    let note: String?
    /// The peer ID of the run organizer this peer is part of. When this
    /// equals `id`, this peer is the organizer of their own run. When it
    /// points to someone else's ID, this peer is joining that person.
    /// `nil` means not in any run.
    let runID: UUID?
    /// How many coffees this peer has logged today.
    let coffeesToday: Int
    /// When the run actually starts. `nil` means "immediate / now".
    let startsAt: Date?
    /// Groups this peer claims to be a member of.
    let groupIDs: Set<UUID>
    /// Pending invites *this peer is offering* to others — we parse these
    /// to detect invites addressed to us.
    let outgoingInvites: [BroadcastInvite]
    /// If this peer is hosting a run, the group it's scoped to. `nil`
    /// means open to everyone visible on the network.
    let audienceGroupID: UUID?

    /// Whole minutes until this peer's run starts. `nil` if no schedule;
    /// `<= 0` means it's happening now or already passed.
    var minutesUntilStart: Int? {
        guard let startsAt = startsAt else { return nil }
        let diff = startsAt.timeIntervalSinceNow / 60.0
        return Int(ceil(diff))
    }

    /// True if this peer started their own run (i.e. they're the host).
    var isRunOrganizer: Bool {
        runID == id && status.isCoffeeSignal
    }

    func relativeTimeString(now: Date = Date()) -> String {
        let seconds = Int(now.timeIntervalSince(timestamp))
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }
}
