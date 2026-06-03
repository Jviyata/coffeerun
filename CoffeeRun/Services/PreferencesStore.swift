import Foundation
import ServiceManagement

/// Thin UserDefaults wrapper for persisted preferences.
struct PreferencesStore {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let displayName = "displayName"
        static let peerID = "peerID"
        static let expiryMinutes = "expiryMinutes"
        static let notificationsEnabled = "notificationsEnabled"
        static let soundEnabled = "soundEnabled"
        static let startAtLogin = "startAtLogin"
        static let coffeesToday = "coffeesToday"
        static let coffeesDate = "coffeesDate"
        static let userProfile = "userProfile_v1"
        static let cloudSyncEnabled = "cloudSyncEnabled"
        static let showSteamForAllSignals = "showSteamForAllSignals"
        static let lastPassiveStatus = "lastPassiveStatus"
        static let demoModeEnabled = "demoModeEnabled"
    }

    /// When on, the menu shows a small set of fake coworkers + a sample
    /// Brwup so a brand-new user can see what a populated office looks
    /// like. Purely cosmetic — nothing is broadcast and no stats change.
    var demoModeEnabled: Bool {
        get { defaults.bool(forKey: Keys.demoModeEnabled) }
        nonmutating set { defaults.set(newValue, forKey: Keys.demoModeEnabled) }
    }

    /// The last passive status the user explicitly chose
    /// (`.available` or `.notAvailable`). Persists across launches so we
    /// don't reset their visibility choice every time.
    /// Coffee signals (`.wantCoffee`, `.goingNow`, `.joining`) are *not*
    /// persisted — they always expire to this passive state.
    var lastPassiveStatus: CoffeeStatus {
        get {
            if let raw = defaults.string(forKey: Keys.lastPassiveStatus),
               let status = CoffeeStatus(rawValue: raw),
               status == .available || status == .notAvailable {
                return status
            }
            return .available
        }
        nonmutating set {
            guard newValue == .available || newValue == .notAvailable else { return }
            defaults.set(newValue.rawValue, forKey: Keys.lastPassiveStatus)
        }
    }

    /// When true, the full-screen steam fires for *any* incoming coffee
    /// signal nearby. Off by default — at office scale that would be
    /// constantly interrupting. Off keeps steam reserved for your own
    /// clicks and for moments where someone joins your run.
    var showSteamForAllSignals: Bool {
        get { defaults.bool(forKey: Keys.showSteamForAllSignals) }
        nonmutating set { defaults.set(newValue, forKey: Keys.showSteamForAllSignals) }
    }

    var cloudSyncEnabled: Bool {
        get { defaults.bool(forKey: Keys.cloudSyncEnabled) }
        nonmutating set { defaults.set(newValue, forKey: Keys.cloudSyncEnabled) }
    }

    var userProfile: UserProfile {
        get {
            if let data = defaults.data(forKey: Keys.userProfile),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                return profile
            }
            // First load — migrate from legacy fields.
            let migrated = UserProfile(
                id: peerID,
                displayName: displayName,
                avatarEmoji: nil,
                createdAt: Date(),
                lifetimeCoffees: legacyTodayCount(),
                coffeesByDate: legacyCoffeesByDate(),
                peopleMet: [],
                lastCoffeeAt: nil
            )
            saveUserProfile(migrated)
            return migrated
        }
        nonmutating set { saveUserProfile(newValue) }
    }

    private func saveUserProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: Keys.userProfile)
        }
    }

    private func legacyTodayCount() -> Int {
        guard let lastDate = defaults.object(forKey: Keys.coffeesDate) as? Date,
              Calendar.current.isDateInToday(lastDate) else { return 0 }
        return defaults.integer(forKey: Keys.coffeesToday)
    }

    private func legacyCoffeesByDate() -> [String: Int] {
        let count = legacyTodayCount()
        guard count > 0 else { return [:] }
        return [UserProfile.dateKey(for: Date()): count]
    }

    /// Local count of coffees consumed today. Resets automatically at midnight.
    var coffeesToday: Int {
        get {
            if let lastDate = defaults.object(forKey: Keys.coffeesDate) as? Date,
               Calendar.current.isDateInToday(lastDate) {
                return defaults.integer(forKey: Keys.coffeesToday)
            }
            return 0
        }
        nonmutating set {
            defaults.set(newValue, forKey: Keys.coffeesToday)
            defaults.set(Date(), forKey: Keys.coffeesDate)
        }
    }

    var displayName: String {
        get { defaults.string(forKey: Keys.displayName) ?? "" }
        nonmutating set { defaults.set(newValue, forKey: Keys.displayName) }
    }

    var peerID: UUID {
        if let raw = defaults.string(forKey: Keys.peerID), let id = UUID(uuidString: raw) {
            return id
        }
        let id = UUID()
        defaults.set(id.uuidString, forKey: Keys.peerID)
        return id
    }

    var expiryMinutes: Int {
        get {
            let v = defaults.integer(forKey: Keys.expiryMinutes)
            return v == 0 ? 30 : v
        }
        nonmutating set { defaults.set(newValue, forKey: Keys.expiryMinutes) }
    }

    var notificationsEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.notificationsEnabled) == nil { return true }
            return defaults.bool(forKey: Keys.notificationsEnabled)
        }
        nonmutating set { defaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    var soundEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.soundEnabled) == nil { return true }
            return defaults.bool(forKey: Keys.soundEnabled)
        }
        nonmutating set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }

    var startAtLogin: Bool {
        get { defaults.bool(forKey: Keys.startAtLogin) }
        nonmutating set {
            defaults.set(newValue, forKey: Keys.startAtLogin)
            applyLoginItem(newValue)
        }
    }

    private func applyLoginItem(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("CoffeeRun login item toggle failed: \(error)")
            }
        }
    }
}
