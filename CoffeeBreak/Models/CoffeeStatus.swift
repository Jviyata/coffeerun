import Foundation

enum CoffeeStatus: String, Codable, CaseIterable, Identifiable {
    case available
    case wantCoffee
    case goingNow
    case joining
    case notAvailable

    var id: String { rawValue }

    var displayText: String {
        switch self {
        case .available: return "Available for coffee"
        case .wantCoffee: return "Wants coffee"
        case .goingNow: return "Going for coffee now"
        case .joining: return "Joining coffee"
        case .notAvailable: return "Not available"
        }
    }

    var shortText: String {
        switch self {
        case .available: return "available"
        case .wantCoffee: return "wants coffee"
        case .goingNow: return "is going now"
        case .joining: return "is joining"
        case .notAvailable: return "not available"
        }
    }

    var symbol: String {
        switch self {
        case .available: return "○"
        case .wantCoffee: return "☕"
        case .goingNow: return "🚶"
        case .joining: return "👋"
        case .notAvailable: return "✕"
        }
    }

    var isCoffeeSignal: Bool {
        self == .wantCoffee || self == .goingNow || self == .joining
    }
}
