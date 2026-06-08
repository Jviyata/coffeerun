import Foundation
import Network
import Combine

/// Discovers and broadcasts Brwup peers on the local network via Bonjour.
///
/// Each instance publishes its current status as TXT-record metadata on a
/// `_coffeerun._tcp` service, and browses for other instances doing the same.
/// No data ever leaves the LAN.
@MainActor
final class NetworkService: ObservableObject {
    @Published private(set) var peers: [Peer] = []

    private let serviceType = "_coffeerun._tcp"
    private let peerID: UUID

    private var listener: NWListener?
    private var browser: NWBrowser?

    private var currentName: String = ""
    private var currentStatus: CoffeeStatus = .available
    private var currentNote: String? = nil
    private var currentTimestamp: Date = Date()
    private var currentRunID: UUID? = nil
    private var currentCoffees: Int = 0
    private var currentStartsAt: Date? = nil
    private var currentGroupIDs: Set<UUID> = []
    private var currentInvites: [BroadcastInvite] = []
    private var currentAudienceGroupID: UUID? = nil

    init(peerID: UUID) {
        self.peerID = peerID
    }

    // MARK: - Public API

    func start(displayName: String, status: CoffeeStatus, note: String?, runID: UUID?, coffees: Int, startsAt: Date?, groupIDs: Set<UUID> = [], invites: [BroadcastInvite] = [], audienceGroupID: UUID? = nil) {
        stop()
        self.currentName = displayName
        self.currentStatus = status
        self.currentNote = note
        self.currentTimestamp = Date()
        self.currentRunID = runID
        self.currentCoffees = coffees
        self.currentStartsAt = startsAt
        self.currentGroupIDs = groupIDs
        self.currentInvites = invites
        self.currentAudienceGroupID = audienceGroupID
        startListener()
        startBrowser()
    }

    func updateGroupsAndInvites(groupIDs: Set<UUID>, invites: [BroadcastInvite]) {
        self.currentGroupIDs = groupIDs
        self.currentInvites = invites
        republish()
    }

    func stop() {
        listener?.cancel()
        listener = nil
        browser?.cancel()
        browser = nil
        peers = []
    }

    func updateStatus(
        _ status: CoffeeStatus,
        note: String?,
        runID: UUID?,
        startsAt: Date?,
        audienceGroupID: UUID?,
        timestamp: Date = Date()
    ) {
        self.currentStatus = status
        self.currentNote = note
        self.currentRunID = runID
        self.currentStartsAt = startsAt
        self.currentAudienceGroupID = audienceGroupID
        self.currentTimestamp = timestamp
        republish()
    }

    func updateCoffees(_ count: Int) {
        self.currentCoffees = count
        republish()
    }

    func updateDisplayName(_ name: String) {
        self.currentName = name
        republish()
    }

    // MARK: - Listener (advertise self)

    private func startListener() {
        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            let listener = try NWListener(using: parameters)
            listener.service = makeService()
            listener.newConnectionHandler = { connection in
                // We don't transfer data over the TCP channel — discovery
                // happens entirely through the Bonjour TXT record.
                connection.cancel()
            }
            listener.stateUpdateHandler = { state in
                if case .failed(let error) = state {
                    print("CoffeeRun listener failed: \(error)")
                }
            }
            listener.start(queue: .main)
            self.listener = listener
        } catch {
            print("CoffeeRun listener could not start: \(error)")
        }
    }

    private func republish() {
        guard listener != nil else { return }
        listener?.service = makeService()
    }

    private func makeService() -> NWListener.Service {
        var txt = NWTXTRecord()
        txt["id"] = peerID.uuidString
        txt["name"] = currentName
        txt["status"] = currentStatus.rawValue
        txt["ts"] = Self.isoFormatter.string(from: currentTimestamp)
        if let note = currentNote, !note.isEmpty {
            txt["note"] = String(note.prefix(80))
        }
        if let runID = currentRunID {
            txt["run"] = runID.uuidString
        }
        if currentCoffees > 0 {
            txt["cups"] = String(currentCoffees)
        }
        if let startsAt = currentStartsAt {
            txt["startsAt"] = Self.isoFormatter.string(from: startsAt)
        }
        if !currentGroupIDs.isEmpty {
            txt["groups"] = currentGroupIDs.map { $0.uuidString }.joined(separator: ",")
        }
        if let aud = currentAudienceGroupID {
            txt["aud"] = aud.uuidString
        }
        if !currentInvites.isEmpty {
            // Format per invite: inviteeID|groupID|groupName (newline-separated).
            // Group names get sanitised so the delimiter chars never appear.
            let encoded = currentInvites.prefix(8).map { inv in
                let safeName = inv.groupName
                    .replacingOccurrences(of: "|", with: "_")
                    .replacingOccurrences(of: "\n", with: " ")
                return "\(inv.inviteeID.uuidString)|\(inv.groupID.uuidString)|\(safeName.prefix(40))"
            }.joined(separator: "\n")
            txt["invs"] = String(encoded.prefix(240))
        }
        // Use the peerID as the service instance name so we can
        // reliably filter out our own advertisement when browsing.
        return NWListener.Service(
            name: peerID.uuidString,
            type: serviceType,
            domain: nil,
            txtRecord: txt
        )
    }

    // MARK: - Browser (discover others)

    private func startBrowser() {
        let descriptor = NWBrowser.Descriptor.bonjourWithTXTRecord(type: serviceType, domain: nil)
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: descriptor, using: parameters)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            // Browser was started on .main, so this callback fires on the main queue.
            MainActor.assumeIsolated {
                self?.processResults(results)
            }
        }
        browser.stateUpdateHandler = { state in
            if case .failed(let error) = state {
                print("CoffeeRun browser failed: \(error)")
            }
        }
        browser.start(queue: .main)
        self.browser = browser
    }

    private func processResults(_ results: Set<NWBrowser.Result>) {
        var collected: [UUID: Peer] = [:]
        for result in results {
            guard case let .bonjour(txt) = result.metadata,
                  let idStr = txt["id"],
                  let id = UUID(uuidString: idStr),
                  id != peerID,
                  let name = txt["name"],
                  let statusRaw = txt["status"],
                  let status = CoffeeStatus(rawValue: statusRaw),
                  let tsStr = txt["ts"],
                  let ts = Self.isoFormatter.date(from: tsStr)
            else { continue }

            let note = txt["note"]
            let runID: UUID? = {
                guard let raw = txt["run"], let id = UUID(uuidString: raw) else { return nil }
                return id
            }()
            let coffeesToday = max(0, min(999, Int(txt["cups"] ?? "0") ?? 0))
            let startsAt = txt["startsAt"].flatMap { Self.isoFormatter.date(from: $0) }
            let groupIDs: Set<UUID> = {
                guard let raw = txt["groups"], !raw.isEmpty else { return [] }
                return Set(raw.split(separator: ",").compactMap { UUID(uuidString: String($0)) })
            }()
            let invites: [BroadcastInvite] = {
                guard let raw = txt["invs"], !raw.isEmpty else { return [] }
                return raw.split(separator: "\n").compactMap { line -> BroadcastInvite? in
                    let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
                    guard parts.count == 3,
                          let invitee = UUID(uuidString: String(parts[0])),
                          let groupID = UUID(uuidString: String(parts[1])) else { return nil }
                    return BroadcastInvite(
                        inviteeID: invitee,
                        groupID: groupID,
                        groupName: String(parts[2]),
                        inviterID: id,
                        inviterName: name
                    )
                }
            }()
            let audienceGroupID: UUID? = {
                guard let raw = txt["aud"], let id = UUID(uuidString: raw) else { return nil }
                return id
            }()
            let peer = Peer(
                id: id,
                displayName: name,
                status: status,
                timestamp: ts,
                note: (note?.isEmpty == false) ? note : nil,
                runID: runID,
                coffeesToday: coffeesToday,
                startsAt: startsAt,
                groupIDs: groupIDs,
                outgoingInvites: invites,
                audienceGroupID: audienceGroupID
            )
            // Keep the most recently timestamped record per peer in case
            // duplicates appear on multi-homed networks.
            if let existing = collected[id], existing.timestamp > peer.timestamp {
                continue
            }
            collected[id] = peer
        }
        let sorted = collected.values.sorted { lhs, rhs in
            if lhs.status.isCoffeeSignal != rhs.status.isCoffeeSignal {
                return lhs.status.isCoffeeSignal
            }
            return lhs.timestamp > rhs.timestamp
        }
        self.peers = sorted
    }

    // MARK: - Helpers

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
