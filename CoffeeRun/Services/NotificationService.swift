import Foundation
import UserNotifications
import AppKit

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let coffeeCategoryID = "COFFEE_CATEGORY"
    static let joinActionID = "JOIN_ACTION"
    static let dismissActionID = "DISMISS_ACTION"

    static let groupInviteCategoryID = "GROUP_INVITE_CATEGORY"
    static let acceptInviteActionID = "ACCEPT_INVITE_ACTION"
    static let declineInviteActionID = "DECLINE_INVITE_ACTION"

    /// Called on the main actor when the user taps the "Join" action on
    /// a coffee-run notification.
    var onJoin: (() -> Void)?
    /// Called when the user accepts a group invite from the system
    /// notification. Passed the inviter peer ID and the group ID.
    var onAcceptGroupInvite: ((_ inviterID: UUID, _ groupID: UUID) -> Void)?
    /// Called when the user declines a group invite.
    var onDeclineGroupInvite: ((_ inviterID: UUID, _ groupID: UUID) -> Void)?

    override init() {
        super.init()
        // UNUserNotificationCenter requires a live bundle proxy.
        // When run as a bare binary (e.g. Xcode launches the executable directly
        // instead of the .app bundle), bundleProxyForCurrentProcess is nil and
        // any call to UNUserNotificationCenter.current() throws a fatal exception.
        // Guard by checking that we're actually inside an .app bundle.
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        registerCategory()
    }

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    func notifyGroupInvite(_ invite: BroadcastInvite, sound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "\(invite.inviterName) invited you to \(invite.groupName)"
        content.body = "Accept to start seeing this group's Brwups."
        content.categoryIdentifier = Self.groupInviteCategoryID
        // Stash the IDs in userInfo so the delegate callback knows
        // which invite the action applies to.
        content.userInfo = [
            "inviterID": invite.inviterID.uuidString,
            "groupID": invite.groupID.uuidString
        ]
        if sound {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("coffee.caf"))
        }
        let request = UNNotificationRequest(
            identifier: "group-invite-\(invite.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func sendTestNotification(sound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Brwup test buzz ☕"
        content.body = "Looks like buzzes are working."
        content.categoryIdentifier = Self.coffeeCategoryID
        if sound {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("coffee.caf"))
        }
        let request = UNNotificationRequest(
            identifier: "coffee-test-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func registerCategory() {
        // Brwup notifications: Join / Dismiss
        let join = UNNotificationAction(
            identifier: Self.joinActionID,
            title: "Join",
            options: [.foreground]
        )
        let dismiss = UNNotificationAction(
            identifier: Self.dismissActionID,
            title: "Dismiss",
            options: []
        )
        let coffeeCategory = UNNotificationCategory(
            identifier: Self.coffeeCategoryID,
            actions: [join, dismiss],
            intentIdentifiers: [],
            options: []
        )

        // Group invite notifications: Accept / Decline
        let accept = UNNotificationAction(
            identifier: Self.acceptInviteActionID,
            title: "Accept",
            options: [.foreground]
        )
        let decline = UNNotificationAction(
            identifier: Self.declineInviteActionID,
            title: "Decline",
            options: []
        )
        let inviteCategory = UNNotificationCategory(
            identifier: Self.groupInviteCategoryID,
            actions: [accept, decline],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([coffeeCategory, inviteCategory])
    }

    func notify(peer: Peer, sound: Bool) {
        let content = UNMutableNotificationContent()
        let verb: String
        switch peer.status {
        case .wantCoffee: verb = "wants coffee"
        case .goingNow: verb = "is going for coffee now"
        case .joining: verb = "is joining for coffee"
        default: return
        }
        content.title = "\(peer.displayName) \(verb) ☕"
        if let note = peer.note, !note.isEmpty {
            content.body = note
        } else {
            content.body = "Open Brwup to join."
        }
        content.categoryIdentifier = Self.coffeeCategoryID
        if sound {
            // Custom ceramic-cup chime bundled in Resources/coffee.caf
            content.sound = UNNotificationSound(named: UNNotificationSoundName("coffee.caf"))
        }

        let request = UNNotificationRequest(
            identifier: "coffee-\(peer.id.uuidString)-\(Int(peer.timestamp.timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - Delegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let category = response.notification.request.content.categoryIdentifier
        let action = response.actionIdentifier

        switch (category, action) {
        case (Self.coffeeCategoryID, Self.joinActionID):
            DispatchQueue.main.async { [weak self] in
                self?.onJoin?()
            }

        case (Self.groupInviteCategoryID, Self.acceptInviteActionID),
             (Self.groupInviteCategoryID, Self.declineInviteActionID):
            let userInfo = response.notification.request.content.userInfo
            guard
                let inviterRaw = userInfo["inviterID"] as? String,
                let groupRaw = userInfo["groupID"] as? String,
                let inviterID = UUID(uuidString: inviterRaw),
                let groupID = UUID(uuidString: groupRaw)
            else { break }
            DispatchQueue.main.async { [weak self] in
                if action == Self.acceptInviteActionID {
                    self?.onAcceptGroupInvite?(inviterID, groupID)
                } else {
                    self?.onDeclineGroupInvite?(inviterID, groupID)
                }
            }

        default:
            break
        }
        completionHandler()
    }
}
