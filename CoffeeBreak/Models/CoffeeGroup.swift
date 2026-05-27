import Foundation

/// A persistent group you can have coffee runs with. Each member has its
/// own copy in their `UserProfile.joinedGroups`. Membership is whoever
/// currently broadcasts the group's ID — there's no admin server.
struct CoffeeGroup: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var joinedAt: Date

    init(id: UUID = UUID(), name: String, joinedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.joinedAt = joinedAt
    }

    /// Short human-friendly fingerprint derived from the UUID — first
    /// 6 hex chars uppercased. Useful to read out verbally / share in chat.
    var joinCode: String {
        String(id.uuidString.replacingOccurrences(of: "-", with: "").prefix(6)).uppercased()
    }
}

/// A pending invite this user has issued — kept in their profile until
/// the invitee joins (or the user revokes it).
struct PendingInvite: Codable, Equatable, Hashable {
    let inviteeID: UUID
    let groupID: UUID
}

/// An invite as seen over the wire — broadcast by the inviter, parsed by
/// the invitee from the inviter's TXT record.
struct BroadcastInvite: Equatable, Hashable, Identifiable {
    let inviteeID: UUID
    let groupID: UUID
    let groupName: String
    let inviterID: UUID
    let inviterName: String

    var id: String { "\(inviterID)-\(inviteeID)-\(groupID)" }
}
