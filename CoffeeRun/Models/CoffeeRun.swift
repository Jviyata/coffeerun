import Foundation

/// A Brwup is one organizer plus the people who joined them.
/// Built by `AppState` from the flat list of network peers.
struct CoffeeRun: Identifiable, Equatable {
    /// Always equals the organizer's peer ID.
    let id: UUID
    let organizer: Peer
    let joiners: [Peer]

    var participantCount: Int { 1 + joiners.count }

    /// Compact "+ Aunindra" / "+ Aunindra, Tony" / "+ Aunindra, Tony +2" line.
    var joinerSummary: String? {
        guard !joiners.isEmpty else { return nil }
        let names = joiners.map { $0.displayName }
        switch names.count {
        case 1: return "+ \(names[0]) joined"
        case 2: return "+ \(names[0]) and \(names[1]) joined"
        default: return "+ \(names[0]), \(names[1]) and \(names.count - 2) more joined"
        }
    }
}
