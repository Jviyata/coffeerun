import Foundation

/// Thin wrapper around `NSUbiquitousKeyValueStore` that syncs the user
/// profile across the same Apple ID's Macs — no servers, no accounts
/// beyond iCloud. Falls back to a no-op when iCloud is unavailable or
/// the app isn't entitled.
@MainActor
final class CloudProfileSync {
    private static let profileKey = "userProfile_v1"

    private let store = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?

    /// Fires when a fresh profile arrives from another Mac.
    var onRemoteChange: ((UserProfile) -> Void)?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.handleExternalChange(note)
            }
        }
        store.synchronize()
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// `true` when the user is signed into iCloud (regardless of whether
    /// this app has the entitlement to actually sync — we use this to
    /// decide whether the toggle in Preferences should be enabled).
    var isAccountSignedIn: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func save(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        store.set(data, forKey: Self.profileKey)
        store.synchronize()
    }

    func load() -> UserProfile? {
        guard let data = store.data(forKey: Self.profileKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return profile
    }

    private func handleExternalChange(_ notification: Notification) {
        guard let reasonNumber = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else { return }
        let reason = reasonNumber.intValue
        switch reason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            if let profile = load() {
                onRemoteChange?(profile)
            }
        default:
            break
        }
    }
}
