import Foundation
import Combine
import AppKit
import UserNotifications

@MainActor
final class AppState: ObservableObject {
    // Identity
    @Published var displayName: String
    @Published var hasCompletedSetup: Bool

    // Own status — initial value loaded from prefs in `init()` so we
    // restore the user's last passive choice across launches.
    @Published private(set) var ownStatus: CoffeeStatus = .available
    @Published private(set) var ownNote: String = ""
    @Published private(set) var statusTimestamp: Date = Date()
    @Published private(set) var ownRunID: UUID? = nil
    @Published private(set) var ownStartsAt: Date? = nil
    /// If non-nil, our active Brwup is scoped to this group — only
    /// members of the group will see the run card on their menu.
    @Published private(set) var ownAudienceGroupID: UUID? = nil

    /// Local persistent profile — lifetime stats across every network this
    /// Mac has been on. Always reflects the latest in-memory state.
    @Published private(set) var profile: UserProfile

    /// Today's coffee count, sourced from the profile (kept as a property
    /// so existing view code can read it directly).
    var ownCoffeesToday: Int { profile.coffeesToday }

    /// Stable peer ID for this device. Exposed so views can recognise our
    /// own runs in the grouped peer list.
    let ownPeerID: UUID

    // Preferences
    @Published var expiryMinutes: Int { didSet { prefs.expiryMinutes = expiryMinutes; scheduleExpiry() } }
    @Published var notificationsEnabled: Bool { didSet { prefs.notificationsEnabled = notificationsEnabled } }
    @Published var soundEnabled: Bool { didSet { prefs.soundEnabled = soundEnabled } }
    @Published var startAtLogin: Bool { didSet { prefs.startAtLogin = startAtLogin } }
    @Published var showSteamForAllSignals: Bool { didSet { prefs.showSteamForAllSignals = showSteamForAllSignals } }

    // Peers (re-exposed so views observe AppState only)
    @Published private(set) var peers: [Peer] = []

    /// Increments whenever a brand-new coffee signal arrives from another
    /// peer. Views observe it to fire a one-shot wiggle animation.
    @Published private(set) var incomingSignalTick: Int = 0

    /// Current macOS-level notification permission state. The in-app
    /// `notificationsEnabled` toggle only matters when this is `.authorized`.
    @Published private(set) var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    // Services
    private let prefs = PreferencesStore()
    private let network: NetworkService
    private let notifications = NotificationService()
    private let steamOverlay = SteamOverlayController()
    private let sleepBlocker = SleepBlocker()
    private let cloudSync = CloudProfileSync()

    /// Set by `AppDelegate` so views can ask the menu bar popover to close
    /// (used when opening Profile & Settings, etc.).
    var dismissMenuBar: (() -> Void)?

    /// Set by `AppDelegate` so views can open the Profile & Settings window
    /// without depending on SwiftUI's `openWindow` environment.
    var openSettings: (() -> Void)?

    /// Set by `AppDelegate` so views can pop the Invite a Coworker sheet
    /// from anywhere in the menu.
    var openInvite: (() -> Void)?

    @Published private(set) var isCaffeinated: Bool = false

    /// When on, a small set of fake coworkers + a sample run are merged into
    /// `activePeers` so a brand-new user can see what a populated office
    /// looks like. Doesn't broadcast or persist anything outside the toggle.
    @Published var demoModeEnabled: Bool {
        didSet {
            prefs.demoModeEnabled = demoModeEnabled
            if demoModeEnabled {
                refreshDemoPeers()
            } else {
                demoPeers = []
            }
        }
    }

    /// Stable in-memory fake peers used when `demoModeEnabled` is on.
    private var demoPeers: [Peer] = []

    @Published var cloudSyncEnabled: Bool {
        didSet {
            prefs.cloudSyncEnabled = cloudSyncEnabled
            if cloudSyncEnabled {
                // Push the local snapshot and pull any remote one immediately.
                cloudSync.save(profile)
                if let remote = cloudSync.load() {
                    applyMergedProfile(local: profile, remote: remote, save: true)
                }
            }
        }
    }

    /// True if the user is signed into iCloud — only then does the cloud
    /// toggle actually do anything.
    var iCloudAvailable: Bool { cloudSync.isAccountSignedIn }

    /// Which group is currently filtering the menu. `nil` means
    /// "Everyone nearby" (no filter).
    @Published var activeGroupFilter: UUID? = nil

    // Internal state
    private var expiryTimer: Timer?
    private var staleSweepTimer: Timer?
    private var lastSeenSignalForPeer: [UUID: Date] = [:]
    private var recentNotificationTimes: [Date] = []
    /// Group IDs we've already fired a system notification for in this
    /// session, so we don't repeatedly ping the user for the same invite.
    private var notifiedGroupInvites: Set<UUID> = []
    private var cancellables = Set<AnyCancellable>()
    /// Peer IDs we've already credited as joiners for the run we're
    /// currently organizing. Reset every time we start / end a run.
    private var notedRunJoiners: Set<UUID> = []

    /// Highest `coffeesToday` value we've seen per peer today. Lets the
    /// "Coffees today nearby" stat keep growing even when a peer briefly
    /// drops off the network (sleep, app restart, status change), so the
    /// number doesn't flicker back down. Reset at midnight.
    private var peerCupsSeenToday: [UUID: Int] = [:]
    private var peerCupsSeenDate: Date = Date()

    /// While we're hosting a run, snapshot of each joiner's `coffeesToday`
    /// the moment we last observed them in our run. Any increase from this
    /// baseline gets credited as a cup we "sparked." Cleared when we stop
    /// organizing or the joiner leaves.
    private var sparkedRunJoinerBaseline: [UUID: Int] = [:]

    /// Cap how many native notifications we fire per rolling window so
    /// large offices don't ding the user dozens of times an hour.
    private let maxNotificationsPerWindow = 3
    private let notificationWindowSeconds: TimeInterval = 600

    init() {
        self.displayName = prefs.displayName
        self.hasCompletedSetup = !prefs.displayName.isEmpty
        self.expiryMinutes = prefs.expiryMinutes
        self.notificationsEnabled = prefs.notificationsEnabled
        self.soundEnabled = prefs.soundEnabled
        self.startAtLogin = prefs.startAtLogin
        self.showSteamForAllSignals = prefs.showSteamForAllSignals
        self.ownPeerID = prefs.peerID
        self.profile = prefs.userProfile
        self.cloudSyncEnabled = prefs.cloudSyncEnabled
        self.demoModeEnabled = prefs.demoModeEnabled
        // Restore the user's last passive choice so they don't get reset
        // to Available on every launch.
        self.ownStatus = prefs.lastPassiveStatus
        self.network = NetworkService(peerID: prefs.peerID)

        network.$peers
            .receive(on: RunLoop.main)
            .sink { [weak self] newPeers in
                self?.handlePeersUpdate(newPeers)
            }
            .store(in: &cancellables)

        notifications.onJoin = { [weak self] in
            self?.setStatus(.joining)
            self?.showMenuBarIfPossible()
        }
        notifications.onAcceptGroupInvite = { [weak self] _, groupID in
            guard let self else { return }
            if let invite = self.pendingIncomingInvites.first(where: { $0.groupID == groupID }) {
                self.acceptInvite(invite)
            }
            self.showMenuBarIfPossible()
        }
        notifications.onDeclineGroupInvite = { [weak self] _, groupID in
            guard let self else { return }
            if let invite = self.pendingIncomingInvites.first(where: { $0.groupID == groupID }) {
                self.declineInvite(invite)
            }
        }

        if hasCompletedSetup {
            startBroadcasting()
            notifications.requestAuthorization { [weak self] _ in
                self?.refreshNotificationAuthStatus()
            }
        }
        refreshNotificationAuthStatus()

        // Periodically prune peers whose timestamps have gone stale (e.g. went offline).
        staleSweepTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pruneStalePeers() }
        }

        // Cloud sync hookup.
        cloudSync.onRemoteChange = { [weak self] remote in
            self?.applyMergedProfile(local: self?.profile ?? remote, remote: remote, save: true)
        }
        if cloudSyncEnabled, let remote = cloudSync.load() {
            applyMergedProfile(local: profile, remote: remote, save: true)
        }

        // didSet doesn't fire from init, so seed demo peers manually when
        // the toggle was already on at launch.
        if demoModeEnabled {
            refreshDemoPeers()
        }
    }

    /// Replace the in-memory profile with a merged version of local + remote.
    /// `save: true` writes the merged result back to local prefs and pushes
    /// to iCloud (when enabled) so all stores converge.
    private func applyMergedProfile(local: UserProfile, remote: UserProfile, save: Bool) {
        let merged = UserProfile.merged(local: local, remote: remote)
        self.profile = merged
        if save {
            prefs.userProfile = merged
            if cloudSyncEnabled {
                cloudSync.save(merged)
            }
            network.updateCoffees(merged.coffeesToday)
        }
    }

    private func persistProfile() {
        prefs.userProfile = profile
        if cloudSyncEnabled {
            cloudSync.save(profile)
        }
    }

    // MARK: - Derived state

    /// Peers whose status hasn't aged past the expiry window. The list is
    /// already sorted by NetworkService (coffee signals first, then recency).
    /// Filtered by `activeGroupFilter` when one is set.
    var activePeers: [Peer] {
        let cutoff = Date().addingTimeInterval(-Double(expiryMinutes * 60))
        // Heads-down peers explicitly opted out of being seen, so we drop
        // them from every social surface (presence, stats, runs).
        let fresh = peers.filter { $0.timestamp >= cutoff && $0.status != .notAvailable }
        let combined = demoModeEnabled ? (fresh + demoPeers) : fresh
        if let groupID = activeGroupFilter {
            return combined.filter { $0.groupIDs.contains(groupID) }
        }
        return combined
    }

    /// Total peers known (unfiltered by crew) — used to display "people nearby"
    /// totals without the group filter mattering. Heads-down peers are still
    /// excluded because the intent is "people who want to be seen".
    var allRecentPeers: [Peer] {
        let cutoff = Date().addingTimeInterval(-Double(expiryMinutes * 60))
        let fresh = peers.filter { $0.timestamp >= cutoff && $0.status != .notAvailable }
        return demoModeEnabled ? (fresh + demoPeers) : fresh
    }

    var nearbyCoffeeSeekers: [Peer] {
        activePeers.filter { $0.status.isCoffeeSignal }
    }

    /// All currently-published Brwups nearby, organizer first then
    /// joiners. Sorted with the most-recent organizer at the top.
    /// Audience-scoped runs are filtered out if we're not a member.
    ///
    /// When we're hosting a run, we synthesize ourselves as an organizer.
    /// `NetworkService` only discovers *other* peers, so our own peer
    /// never appears in `activePeers` — without this, the organizer would
    /// never see their own run (or its joiners) in the activity feed.
    var activeRuns: [CoffeeRun] {
        let active = activePeers
        let myGroupIDs = Set(profile.joinedGroups.map { $0.id })

        var organizers: [Peer] = active.filter { peer in
            guard peer.isRunOrganizer else { return false }
            // Open to everyone
            guard let audience = peer.audienceGroupID else { return true }
            // Audience-scoped — must be a member to see it
            return myGroupIDs.contains(audience)
        }

        // Synthesize self as an organizer when we're hosting.
        if ownStatus.isCoffeeSignal && ownRunID == ownPeerID {
            let selfPeer = Peer(
                id: ownPeerID,
                displayName: displayName,
                status: ownStatus,
                timestamp: statusTimestamp,
                note: ownNote.isEmpty ? nil : ownNote,
                runID: ownPeerID,
                coffeesToday: profile.coffeesToday,
                startsAt: ownStartsAt,
                groupIDs: myGroupIDs,
                outgoingInvites: [],
                audienceGroupID: ownAudienceGroupID
            )
            organizers.insert(selfPeer, at: 0)
        }

        return organizers.map { organizer in
            let joiners = active.filter { peer in
                peer.runID == organizer.id && peer.id != organizer.id
            }
            return CoffeeRun(id: organizer.id, organizer: organizer, joiners: joiners)
        }
        .sorted { $0.organizer.timestamp > $1.organizer.timestamp }
    }

    /// Peers that aren't part of any visible run (either because they're not
    /// in a run, or because the organizer they joined isn't visible to us).
    var soloPeers: [Peer] {
        let active = activePeers
        let visibleOrganizerIDs = Set(active.filter { $0.isRunOrganizer }.map { $0.id })
        return active.filter { peer in
            if peer.isRunOrganizer { return false }
            if let runID = peer.runID, visibleOrganizerIDs.contains(runID) { return false }
            return true
        }
    }

    /// The run we're currently part of, if any.
    var ownRun: CoffeeRun? {
        guard let runID = ownRunID else { return nil }
        return activeRuns.first { $0.id == runID }
    }

    /// Sum of coffees logged today by you and everyone you've seen today.
    /// Uses the max-seen snapshot so the number doesn't drop when a peer
    /// briefly disappears (status flip, sleep) — once today's cup is
    /// counted it stays counted until midnight.
    var totalCoffeesOnNetwork: Int {
        ownCoffeesToday + peerCupsSeenToday.values.reduce(0, +)
    }

    /// Approximate "lifetime" cups across the visible network. We have
    /// our own lifetime exactly, and use peers' today-only counts (since
    /// peers only broadcast today's count) as the rest. Best-effort.
    var networkLifetimeCoffees: Int {
        profile.lifetimeCoffees + activePeers.reduce(0) { $0 + $1.coffeesToday }
    }

    /// Count of people (including you) who have logged at least one coffee today.
    var coffeeDrinkerCount: Int {
        let peerDrinkers = activePeers.filter { $0.coffeesToday > 0 }.count
        return peerDrinkers + (ownCoffeesToday > 0 ? 1 : 0)
    }

    var menuBarSymbolName: String {
        if ownStatus == .notAvailable { return "cup.and.saucer" }
        if !nearbyCoffeeSeekers.isEmpty { return "cup.and.saucer.fill" }
        if ownStatus.isCoffeeSignal { return "cup.and.saucer.fill" }
        return "cup.and.saucer"
    }

    /// Cup variant for the menu bar — filled when actively signalling,
    /// outline otherwise. Status differentiation comes from an accent badge
    /// rendered alongside this cup (see `menuBarAccent`).
    var statusSymbolName: String {
        ownStatus.isCoffeeSignal ? "cup.and.saucer.fill" : "cup.and.saucer"
    }

    /// Tiny SF Symbol shown next to the cup to disambiguate each status.
    /// Returns `nil` when the cup alone is enough (Available or "I want coffee").
    var menuBarAccent: (symbol: String, colorName: String)? {
        switch ownStatus {
        case .goingNow:
            return ("arrow.right", "green")
        case .joining:
            return ("hand.wave.fill", "blue")
        case .notAvailable:
            return ("xmark.circle.fill", "red")
        case .wantCoffee, .available:
            return nil
        }
    }

    var menuBarBadgeCount: Int { nearbyCoffeeSeekers.count }

    // MARK: - Setup

    func completeSetup(displayName: String) {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.displayName = trimmed
        prefs.displayName = trimmed
        self.hasCompletedSetup = true
        startBroadcasting()
        notifications.requestAuthorization()
    }

    func updateDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.displayName = trimmed
        prefs.displayName = trimmed
        profile.displayName = trimmed
        profile.metadataUpdatedAt = Date()
        persistProfile()
        network.updateDisplayName(trimmed)
    }

    func updateAvatarEmoji(_ emoji: String?) {
        let trimmed = emoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.avatarEmoji = (trimmed?.isEmpty == false) ? trimmed : nil
        profile.metadataUpdatedAt = Date()
        persistProfile()
    }

    // MARK: - Status

    func setStatus(_ status: CoffeeStatus, note: String? = nil) {
        let previousStatus = self.ownStatus
        let appliedNote = note ?? (status.isCoffeeSignal ? ownNote : "")
        self.ownStatus = status
        self.ownNote = appliedNote
        self.statusTimestamp = Date()

        // Run identity:
        //   wantCoffee / goingNow → we host a run (runID = our own peerID)
        //   joining               → preserve whatever runID was set by joinRun
        //   available / not available → clear it AND persist this passive choice
        switch status {
        case .wantCoffee, .goingNow:
            self.ownRunID = ownPeerID
            self.notedRunJoiners.removeAll()        // fresh run, fresh joiner set
        case .available, .notAvailable:
            self.ownRunID = nil
            self.ownStartsAt = nil
            self.ownAudienceGroupID = nil           // clear audience scope
            self.notedRunJoiners.removeAll()
            prefs.lastPassiveStatus = status        // remember across launches
        case .joining:
            self.notedRunJoiners.removeAll()        // we're no longer the organizer
        }

        network.updateStatus(
            status,
            note: appliedNote.isEmpty ? nil : appliedNote,
            runID: ownRunID,
            startsAt: ownStartsAt,
            audienceGroupID: ownAudienceGroupID,
            timestamp: statusTimestamp
        )
        scheduleExpiry()

        // Full-screen steam celebration when the user actively declares they
        // want coffee or are going for one — only when it's a real transition,
        // not a re-click of the same status.
        if (status == .wantCoffee || status == .goingNow)
            && status != previousStatus
            && !isCaffeinated {
            // Own action — always show, ignore cooldown. Suppressed while
            // Caffeinated since the user explicitly signalled heads-down.
            steamOverlay.show(respectCooldown: false)
        }
    }

    /// Start a Brwup that others can join. `minutes` is how many
    /// minutes from now the run actually starts (0 = immediately).
    /// `audience` is the group ID the run is scoped to — pass `nil`
    /// to make it visible to everyone on the network.
    func startCoffeeRun(inMinutes minutes: Int, audience: UUID? = nil) {
        let clamped = max(0, min(minutes, 60))
        self.ownStartsAt = clamped > 0 ? Date().addingTimeInterval(Double(clamped) * 60) : nil
        self.ownAudienceGroupID = audience
        setStatus(.goingNow)
    }

    /// Join an existing Brwup published by another peer. We inherit
    /// the run's audience scope so we don't accidentally widen visibility.
    func joinRun(_ run: CoffeeRun) {
        self.ownRunID = run.id
        self.ownStartsAt = run.organizer.startsAt
        self.ownAudienceGroupID = run.organizer.audienceGroupID
        setStatus(.joining)
    }

    /// Leave the run you're part of (whether you hosted or joined) and go
    /// back to whichever passive state the user had picked.
    func leaveRun() {
        self.ownRunID = nil
        setStatus(prefs.lastPassiveStatus)
    }

    /// True when we're currently a participant in the given run.
    func isInRun(_ run: CoffeeRun) -> Bool {
        ownStatus.isCoffeeSignal && ownRunID == run.id
    }

    // MARK: - Groups

    func createGroup(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let group = CoffeeGroup(name: trimmed)
        profile.joinedGroups.append(group)
        persistProfile()
        republishGroupsAndInvites()
    }

    func leaveGroup(_ groupID: UUID) {
        profile.joinedGroups.removeAll { $0.id == groupID }
        profile.pendingInvitesSent.removeAll { $0.groupID == groupID }
        if activeGroupFilter == groupID { activeGroupFilter = nil }
        // If we were running a session scoped to this group, drop the
        // audience so the run becomes open (or end the run entirely if
        // it now points to a group we left).
        if ownAudienceGroupID == groupID {
            ownAudienceGroupID = nil
        }
        persistProfile()
        republishGroupsAndInvites()
    }

    func invitePeers(_ peerIDs: [UUID], toGroup groupID: UUID) {
        guard profile.joinedGroups.contains(where: { $0.id == groupID }) else { return }
        for peerID in peerIDs {
            let invite = PendingInvite(inviteeID: peerID, groupID: groupID)
            if !profile.pendingInvitesSent.contains(invite) {
                profile.pendingInvitesSent.append(invite)
            }
        }
        persistProfile()
        republishGroupsAndInvites()
    }

    func acceptInvite(_ invite: BroadcastInvite) {
        // Already in this group? No-op.
        if profile.joinedGroups.contains(where: { $0.id == invite.groupID }) { return }
        let group = CoffeeGroup(id: invite.groupID, name: invite.groupName)
        profile.joinedGroups.append(group)
        profile.declinedGroupInvites.remove(invite.groupID)
        persistProfile()
        republishGroupsAndInvites()
    }

    func declineInvite(_ invite: BroadcastInvite) {
        profile.declinedGroupInvites.insert(invite.groupID)
        persistProfile()
    }

    /// Invites currently visible on the network that target us and that
    /// we haven't joined or declined.
    var pendingIncomingInvites: [BroadcastInvite] {
        let joinedIDs = Set(profile.joinedGroups.map { $0.id })
        let declined = profile.declinedGroupInvites
        var seen = Set<String>()
        return peers.flatMap { $0.outgoingInvites }
            .filter { invite in
                invite.inviteeID == ownPeerID
                    && !joinedIDs.contains(invite.groupID)
                    && !declined.contains(invite.groupID)
            }
            .filter { invite in
                // Dedupe in case multiple inviters broadcast the same invite.
                seen.insert(invite.id).inserted
            }
    }

    /// Members of a group currently visible on the network (excluding us).
    func members(of groupID: UUID) -> [Peer] {
        peers.filter { $0.groupIDs.contains(groupID) }
    }

    func memberCount(of groupID: UUID) -> Int {
        var count = members(of: groupID).count
        if profile.joinedGroups.contains(where: { $0.id == groupID }) {
            count += 1 // count ourselves
        }
        return count
    }

    /// Add one to the local coffee counter for today, broadcast the new
    /// total, and (if currently in a run) wrap up that run for the user.
    func logCoffeeConsumed() {
        recordCoffeeIntoProfile()
        if ownStatus.isCoffeeSignal {
            leaveRun()
        }
    }

    private func recordCoffeeIntoProfile() {
        profile.recordCoffee()
        // If we're currently in a run *we organized*, this cup also counts
        // as one we sparked. Check before the caller potentially mutates
        // status (e.g. via leaveRun()).
        if ownStatus.isCoffeeSignal && ownRunID == ownPeerID {
            profile.recordSparkedCup()
        }
        persistProfile()
        network.updateCoffees(profile.coffeesToday)
    }

    func setNote(_ note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.ownNote = trimmed
        network.updateStatus(
            ownStatus,
            note: trimmed.isEmpty ? nil : trimmed,
            runID: ownRunID,
            startsAt: ownStartsAt,
            audienceGroupID: ownAudienceGroupID,
            timestamp: statusTimestamp
        )
    }

    private func scheduleExpiry() {
        expiryTimer?.invalidate()
        expiryTimer = nil
        guard ownStatus.isCoffeeSignal else { return }
        let interval = Double(expiryMinutes * 60)
        expiryTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleStatusExpiry()
            }
        }
    }

    /// Fired when an active coffee status reaches its expiry window without
    /// the user clearing it themselves. If they were heading for / joining
    /// a coffee, we count it as one consumed. Then we return to whichever
    /// passive state the user had picked (not always `.available`).
    private func handleStatusExpiry() {
        if ownStatus == .goingNow || ownStatus == .joining {
            autoLogCoffeeConsumed()
        }
        setStatus(prefs.lastPassiveStatus)
    }

    private func autoLogCoffeeConsumed() {
        recordCoffeeIntoProfile()
    }

    var ownStatusExpiresAt: Date? {
        guard ownStatus.isCoffeeSignal else { return nil }
        return statusTimestamp.addingTimeInterval(Double(expiryMinutes * 60))
    }

    // MARK: - Broadcasting

    private func startBroadcasting() {
        network.start(
            displayName: displayName,
            status: ownStatus,
            note: ownNote.isEmpty ? nil : ownNote,
            runID: ownRunID,
            coffees: profile.coffeesToday,
            startsAt: ownStartsAt,
            groupIDs: Set(profile.joinedGroups.map { $0.id }),
            invites: outgoingBroadcastInvites(),
            audienceGroupID: ownAudienceGroupID
        )
    }

    /// Convert our locally-stored `pendingInvitesSent` into the over-the-wire
    /// form (carries the group name + our identity so invitees can decide).
    private func outgoingBroadcastInvites() -> [BroadcastInvite] {
        profile.pendingInvitesSent.compactMap { invite in
            guard let group = profile.joinedGroups.first(where: { $0.id == invite.groupID }) else {
                return nil
            }
            return BroadcastInvite(
                inviteeID: invite.inviteeID,
                groupID: invite.groupID,
                groupName: group.name,
                inviterID: ownPeerID,
                inviterName: displayName
            )
        }
    }

    private func republishGroupsAndInvites() {
        network.updateGroupsAndInvites(
            groupIDs: Set(profile.joinedGroups.map { $0.id }),
            invites: outgoingBroadcastInvites()
        )
    }

    // MARK: - Peer updates & notifications

    private func handlePeersUpdate(_ newPeers: [Peer]) {
        self.peers = newPeers
        updatePeerCupsSnapshot(from: newPeers)

        // Record every peer we've ever seen in the lifetime profile.
        var profileChanged = false
        for peer in newPeers where !profile.peopleMet.contains(peer.id) {
            profile.noteSeen(peerID: peer.id)
            profileChanged = true
        }

        // Surface new group invites as system notifications. Once per
        // groupID per session — declining the invite implicitly suppresses
        // it for future sessions via `declinedGroupInvites`.
        if notificationsEnabled {
            for invite in pendingIncomingInvites
                where !notifiedGroupInvites.contains(invite.groupID) && canFireNotification() {
                notifications.notifyGroupInvite(invite, sound: soundEnabled)
                notifiedGroupInvites.insert(invite.groupID)
                recentNotificationTimes.append(Date())
            }
        }
        // Garbage-collect any pending invites whose recipient is now visibly
        // a member of the group (they accepted).
        let beforeCount = profile.pendingInvitesSent.count
        profile.pendingInvitesSent.removeAll { invite in
            newPeers.contains { $0.id == invite.inviteeID && $0.groupIDs.contains(invite.groupID) }
        }
        if profile.pendingInvitesSent.count != beforeCount {
            profileChanged = true
            republishGroupsAndInvites()
        }
        if profileChanged {
            persistProfile()
        }

        // Credit "sparked" cups: any time a joiner of *our* run logs a cup
        // (their coffeesToday goes up while they're joining us, or they leave
        // our run with a higher cup count than when they joined), it counts
        // as one we sparked.
        if ownStatus.isCoffeeSignal && ownRunID == ownPeerID {
            let currentJoinerIDs = Set(
                newPeers
                    .filter { $0.runID == ownPeerID && $0.id != ownPeerID }
                    .map { $0.id }
            )
            let peerCupsByID = Dictionary(
                uniqueKeysWithValues: newPeers.map { ($0.id, $0.coffeesToday) }
            )

            // Catch the "Got my coffee" case: peer was in our run, isn't now,
            // and has more cups than their baseline. Credit the delta.
            for (peerID, baseline) in sparkedRunJoinerBaseline where !currentJoinerIDs.contains(peerID) {
                if let currentCups = peerCupsByID[peerID], currentCups > baseline {
                    let delta = currentCups - baseline
                    for _ in 0..<delta { profile.recordSparkedCup() }
                    profileChanged = true
                }
            }
            // Drop baselines for joiners who left so we don't double-credit later.
            sparkedRunJoinerBaseline = sparkedRunJoinerBaseline.filter { currentJoinerIDs.contains($0.key) }

            // For joiners still in the run, credit any new cups since their
            // last baseline, then update the baseline.
            for peer in newPeers where peer.runID == ownPeerID && peer.id != ownPeerID {
                if let baseline = sparkedRunJoinerBaseline[peer.id],
                   peer.coffeesToday > baseline {
                    let delta = peer.coffeesToday - baseline
                    for _ in 0..<delta { profile.recordSparkedCup() }
                    profileChanged = true
                }
                sparkedRunJoinerBaseline[peer.id] = peer.coffeesToday
            }
        } else {
            // Not organizing — clear any stale baselines.
            sparkedRunJoinerBaseline.removeAll()
        }

        var hadNewIncomingSignal = false
        for peer in newPeers where peer.status.isCoffeeSignal {
            let previous = lastSeenSignalForPeer[peer.id]
            if previous == nil || peer.timestamp > previous! {
                lastSeenSignalForPeer[peer.id] = peer.timestamp
                // Avoid reacting to very old signals that show up because
                // we just joined the network.
                guard Date().timeIntervalSince(peer.timestamp) < Double(expiryMinutes * 60) else { continue }
                hadNewIncomingSignal = true
                // Fire the menu bar wiggle regardless of notification setting.
                incomingSignalTick &+= 1
                if notificationsEnabled && canFireNotification() {
                    notifications.notify(peer: peer, sound: soundEnabled)
                    recentNotificationTimes.append(Date())
                }
            }
        }

        // Tiered full-screen steam:
        //   • Always when someone joins YOUR run (social moment that matters).
        //   • Only on general incoming signals if the power-user toggle is on.
        //   • Always suppressed when Caffeinated (you said heads-down).
        if !isCaffeinated {
            let hadNewJoinerToMyRun = detectNewJoinersToOwnRun(in: newPeers)
            if hadNewJoinerToMyRun {
                steamOverlay.show()
            } else if showSteamForAllSignals && hadNewIncomingSignal {
                steamOverlay.show()
            }
        }

        // Forget peers that have dropped off so they re-notify next time.
        let activeIDs = Set(newPeers.map { $0.id })
        lastSeenSignalForPeer = lastSeenSignalForPeer.filter { activeIDs.contains($0.key) }
    }

    /// Returns true if any peer in `newPeers` is broadcasting our own
    /// `peerID` as their `runID` for the first time — i.e. someone just
    /// joined the run we organized.
    private func detectNewJoinersToOwnRun(in newPeers: [Peer]) -> Bool {
        guard ownStatus.isCoffeeSignal && ownRunID == ownPeerID else { return false }
        var foundNew = false
        for peer in newPeers
            where peer.runID == ownPeerID && peer.id != ownPeerID {
            if notedRunJoiners.insert(peer.id).inserted {
                foundNew = true
            }
        }
        return foundNew
    }

    private func canFireNotification() -> Bool {
        let cutoff = Date().addingTimeInterval(-notificationWindowSeconds)
        recentNotificationTimes = recentNotificationTimes.filter { $0 >= cutoff }
        return recentNotificationTimes.count < maxNotificationsPerWindow
    }

    private func pruneStalePeers() {
        // No-op: activePeers is computed. Triggering objectWillChange via
        // a published property would re-render views relying on freshness.
        objectWillChange.send()
    }

    /// Bump the per-peer max-cups-seen-today snapshot. Resets when the day
    /// rolls over. We exclude `.notAvailable` peers from the snapshot too —
    /// heads-down means "don't count me into the room".
    private func updatePeerCupsSnapshot(from newPeers: [Peer]) {
        let today = Calendar.current.startOfDay(for: Date())
        if Calendar.current.startOfDay(for: peerCupsSeenDate) != today {
            peerCupsSeenToday.removeAll()
            peerCupsSeenDate = today
        }
        for peer in newPeers where peer.status != .notAvailable {
            let existing = peerCupsSeenToday[peer.id] ?? 0
            if peer.coffeesToday > existing {
                peerCupsSeenToday[peer.id] = peer.coffeesToday
            }
        }
    }

    private func showMenuBarIfPossible() {
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Notification permissions

    func refreshNotificationAuthStatus() {
        notifications.getAuthorizationStatus { [weak self] status in
            self?.notificationAuthorizationStatus = status
        }
    }

    func requestNotificationPermission() {
        notifications.requestAuthorization { [weak self] _ in
            self?.refreshNotificationAuthStatus()
        }
    }

    func sendTestNotification() {
        notifications.sendTestNotification(sound: soundEnabled)
    }

    // MARK: - Caffeinated mode

    /// Toggle the "keep my screen awake" power assertion. Pure power feature
    /// — does not affect your coffee status or hide you from peers.
    func toggleCaffeinated() {
        isCaffeinated.toggle()
        if isCaffeinated {
            sleepBlocker.enable()
        } else {
            sleepBlocker.disable()
        }
    }

    func openSystemNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Global hotkey entry-point

    /// Triggered by the ⌃⌥C global hotkey. Starts an immediate open run
    /// and pops the menu so the user can confirm or adjust.
    func startCoffeeRunFromHotkey() {
        startCoffeeRun(inMinutes: 0, audience: nil)
        showMenuBarIfPossible()
    }

    // MARK: - Demo peers

    /// Generate a stable set of fake coworkers + a sample run. Stable UUIDs
    /// so repeated toggles don't shuffle avatar colors.
    private func refreshDemoPeers() {
        // Predetermined valid-hex UUIDs so toggling demo mode on/off doesn't
        // reshuffle the deterministic avatar colors.
        let mayaID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let devID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let saraID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let jordanID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let now = Date()

        demoPeers = [
            // Maya is organizing a run starting in 2 min
            Peer(
                id: mayaID,
                displayName: "Maya P.",
                status: .goingNow,
                timestamp: now.addingTimeInterval(-60),
                note: "Meet at kitchen",
                runID: mayaID,
                coffeesToday: 1,
                startsAt: now.addingTimeInterval(120),
                groupIDs: [],
                outgoingInvites: [],
                audienceGroupID: nil
            ),
            // Dev already joined Maya's run
            Peer(
                id: devID,
                displayName: "Dev R.",
                status: .joining,
                timestamp: now.addingTimeInterval(-30),
                note: nil,
                runID: mayaID,
                coffeesToday: 0,
                startsAt: nil,
                groupIDs: [],
                outgoingInvites: [],
                audienceGroupID: nil
            ),
            // Sara is around but not brewing
            Peer(
                id: saraID,
                displayName: "Sara K.",
                status: .available,
                timestamp: now.addingTimeInterval(-180),
                note: nil,
                runID: nil,
                coffeesToday: 2,
                startsAt: nil,
                groupIDs: [],
                outgoingInvites: [],
                audienceGroupID: nil
            ),
            // Jordan wants coffee but hasn't committed to a time
            Peer(
                id: jordanID,
                displayName: "Jordan L.",
                status: .wantCoffee,
                timestamp: now.addingTimeInterval(-90),
                note: "lobby?",
                runID: jordanID,
                coffeesToday: 0,
                startsAt: nil,
                groupIDs: [],
                outgoingInvites: [],
                audienceGroupID: nil
            )
        ]
    }
}
