import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject var appState: AppState

    @State private var showingRunOptions = false
    @State private var selectedRunAudience: UUID? = nil
    @State private var showingNoteField = false
    @State private var noteDraft = ""
    @State private var toastMessage: String?
    @State private var toastDismissWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 0) {
            if !appState.hasCompletedSetup {
                WelcomeView()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        headerBar
                        notificationPermissionBanner
                        heroStatusCard
                        statsRow
                        groupFilterRow
                        actionButtons
                        if showingRunOptions { runOptionsPanel }
                        incomingInvitesSection
                        whatsHappeningSection
                        utilitySection
                        bottomSection
                        footerText
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .overlay(alignment: .top) {
                    if let toast = toastMessage {
                        toastView(toast)
                            .padding(.horizontal, 10)
                            .padding(.top, 6)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
        .frame(width: 360)
        .frame(minHeight: 720, idealHeight: 1000, maxHeight: 1200)
        .onChange(of: appState.ownStatus) { newStatus in
            showSuccessToast(for: newStatus)
        }
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack(spacing: 6) {
            Text("Coffee Run")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                appState.openSettings?()
                dismissMenuBarPopover()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Hero status card

    private var heroStatusCard: some View {
        HStack(spacing: 14) {
            heroCupGraphic
                .frame(width: 80, height: 56)   // letterbox the cup so the card stays short
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(heroHeadline)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 6)
                    BreathingStatusDot(color: heroStatusDotColor)
                }
                Text(heroSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var heroCupGraphic: some View {
        // Beautiful illustrated cup PNG bundled with the app, with a
        // subtle animated steam overlay extending the drawn steam.
        Group {
            if let nsImage = NSImage(named: "coffeerun_herobig") {
                ZStack(alignment: .top) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .interpolation(Image.Interpolation.high)   // sharper downscale
                        .antialiased(true)                          // smoother edges
                        .scaledToFit()
                    // Hybrid steam: slow expanding cloud body + fast small
                    // wisps for turbulence detail. Reads as natural rising
                    // steam, layered above the cup's existing drawn steam.
                    SteamHybrid(color: Color(white: 0.96), maxOpacity: 0.32)
                        .frame(width: 32, height: 32)
                        .offset(y: -14)
                        .allowsHitTesting(false)
                        .blendMode(.plusLighter)
                }
            } else {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.brown)
            }
        }
    }

    private var heroHeadline: String {
        switch appState.ownStatus {
        case .available: return "Open for a quick break"
        case .notAvailable: return "Heads down right now"
        case .wantCoffee: return "Looking for coffee company"
        case .goingNow:
            // Lead with joiner names when someone's actually in — that's
            // the moment that matters and what the organizer wants to see.
            let joiners = appState.ownRun?.joiners ?? []
            if let first = joiners.first {
                if joiners.count == 1 {
                    return "Brewing with \(first.displayName)"
                } else if joiners.count == 2 {
                    return "Brewing with \(first.displayName) and 1 other"
                } else {
                    return "Brewing with \(first.displayName) and \(joiners.count - 1) others"
                }
            }
            if let audience = ownAudienceName() {
                return "Brewing with the \(audience) crew"
            }
            return "Brewing a coffee run"
        case .joining:
            // Past-tense + possessive reads as "this is done" not "in progress"
            if let run = appState.ownRun { return "Joined \(run.organizer.displayName)'s run" }
            return "Joined a coffee run"
        }
    }

    private var heroSubtitle: String {
        switch appState.ownStatus {
        case .available: return "Let nearby people know you're up for it."
        case .notAvailable: return "You won't show up to your crew."
        case .wantCoffee: return "Waiting for someone to start a run."
        case .goingNow:
            // If someone joined, that's the headline news — keep the
            // subtitle focused on inviting more / start time.
            let joiners = appState.ownRun?.joiners ?? []
            if !joiners.isEmpty {
                if let mins = appState.ownStartsAt.map({ Int(ceil($0.timeIntervalSinceNow / 60.0)) }), mins > 0 {
                    return "Leaving in \(mins) min. Anyone else?"
                }
                return joiners.count == 1
                    ? "They're in. Anyone else?"
                    : "\(joiners.count) in. Anyone else?"
            }
            if let mins = appState.ownStartsAt.map({ Int(ceil($0.timeIntervalSinceNow / 60.0)) }), mins > 0 {
                return "Starting in \(mins) min — your crew can join."
            }
            return "Your crew can join for the next \(appState.expiryMinutes) minutes."
        case .joining:
            // If the organizer wrote a meet point, surface it. That's the
            // single thing a joiner actually needs to know.
            if let run = appState.ownRun, let note = run.organizer.note, !note.isEmpty {
                return "Meet at \(note)"
            }
            if let run = appState.ownRun,
               let mins = run.organizer.minutesUntilStart, mins > 0 {
                return "Leaving in \(mins) min."
            }
            return "You'll get the next coffee buzz."
        }
    }

    private var heroStatusDotColor: Color {
        switch appState.ownStatus {
        case .available: return .green
        case .wantCoffee, .goingNow, .joining: return Color.orange
        case .notAvailable: return Color.gray
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 10) {
            networkStatTile
            personalStatTile
        }
    }

    private var networkStatTile: some View {
        let total = appState.totalCoffeesOnNetwork
        let drinkers = appState.coffeeDrinkerCount
        let footer: String
        if total == 0 {
            footer = "Quiet so far today"
        } else if drinkers <= 1 {
            footer = "Just you brewing so far"
        } else {
            footer = "\(drinkers) in your crew today"
        }
        return StatTile(
            icon: .networkCups,
            value: total,
            label: "Coffees today\nnearby",
            footerText: footer,
            footerColor: total > 0 ? .green : .secondary
        )
    }

    private var personalStatTile: some View {
        // "Sparked" = cups consumed in runs you organized (your own cup
        // during your own run + each joiner's cup while they're in it).
        // Now actually means what it says.
        let sparkedWeek = appState.profile.sparkedThisWeek
        let sparkedStreak = appState.profile.sparkedStreak
        let footer: String
        let footerColor: Color
        if sparkedStreak > 0 {
            footer = "🔥 \(sparkedStreak) day streak"
            footerColor = .orange
        } else if sparkedWeek > 0 {
            footer = "Spark a run today to keep going"
            footerColor = .secondary
        } else {
            footer = "Start a run to spark some"
            footerColor = .secondary
        }
        return StatTile(
            icon: .personalCup,
            value: sparkedWeek,
            label: "Coffees sparked\nby you this week",
            footerText: footer,
            footerColor: footerColor
        )
    }

    // MARK: - Group filter row

    @ViewBuilder
    private var groupFilterRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text("Showing")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Picker("", selection: $appState.activeGroupFilter) {
                Text("Everyone nearby").tag(UUID?.none)
                ForEach(appState.profile.joinedGroups) { group in
                    Text("\(group.name) crew").tag(Optional(group.id))
                }
            }
            .labelsHidden()
            .controlSize(.small)
            Spacer()
            // Stacked mini avatars of who's in view + count
            HStack(spacing: -6) {
                ForEach(Array(appState.activePeers.prefix(3).enumerated()), id: \.element.id) { idx, peer in
                    InitialAvatar(
                        name: peer.displayName,
                        online: peer.status.isCoffeeSignal,
                        size: 20
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.2)
                    )
                    .zIndex(Double(3 - idx))
                }
            }
            Text("\(appState.activePeers.count + 1)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Three big action buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            BigActionButton(
                title: "Coffee Run",
                subtitle: "Start a run",
                iconName: "cup.and.saucer.fill",
                background: Color(red: 0.83, green: 0.65, blue: 0.45),
                foreground: Color(red: 0.18, green: 0.13, blue: 0.08),
                isSelected: appState.ownStatus == .goingNow
            ) {
                withAnimation(.easeOut(duration: 0.18)) {
                    showingRunOptions.toggle()
                    showingNoteField = false
                }
            }
            BigActionButton(
                title: "Available",
                subtitle: "Open for coffee",
                iconName: "face.smiling.inverse",
                background: Color(red: 0.32, green: 0.48, blue: 0.28),
                foreground: Color.white,
                isSelected: appState.ownStatus == .available
            ) {
                appState.setStatus(.available)
                withAnimation(.easeOut(duration: 0.18)) {
                    showingRunOptions = false
                }
            }
            BigActionButton(
                title: "Heads Down",
                subtitle: "Not available",
                iconName: "face.dashed",
                background: Color(red: 0.22, green: 0.22, blue: 0.22),
                foreground: Color(white: 0.85),
                isSelected: appState.ownStatus == .notAvailable
            ) {
                appState.setStatus(.notAvailable)
                withAnimation(.easeOut(duration: 0.18)) {
                    showingRunOptions = false
                }
            }
        }
    }

    // MARK: - Run options panel (audience + timing)

    private var runOptionsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !appState.profile.joinedGroups.isEmpty {
                Text("Who can see this run")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                ChipFlowLayout(spacing: 4) {
                    audienceChip(label: "Everyone", id: nil, icon: "globe")
                    ForEach(appState.profile.joinedGroups) { group in
                        audienceChip(label: group.name, id: group.id, icon: "lock.fill")
                    }
                }
            }
            Text("When")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.top, 4)
            HStack(spacing: 6) {
                runTimingChip(label: "Now", minutes: 0)
                runTimingChip(label: "In 5 min", minutes: 5)
                runTimingChip(label: "In 15 min", minutes: 15)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }

    private func audienceChip(label: String, id: UUID?, icon: String) -> some View {
        let isSelected = selectedRunAudience == id
        return Button {
            selectedRunAudience = id
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 9, weight: .semibold))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(isSelected ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }

    private func runTimingChip(label: String, minutes: Int) -> some View {
        Button {
            appState.startCoffeeRun(inMinutes: minutes, audience: selectedRunAudience)
            withAnimation(.easeOut(duration: 0.18)) {
                showingRunOptions = false
            }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.83, green: 0.65, blue: 0.45).opacity(0.25))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.83, green: 0.65, blue: 0.45).opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Note editor (inline)

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Add a quick note")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack {
                TextField("e.g. Meet at kitchen", text: $noteDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveNote() }
                Button("Save", action: saveNote)
                    .disabled(noteDraft == appState.ownNote)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
    }

    private func saveNote() {
        appState.setNote(noteDraft)
        withAnimation(.easeOut(duration: 0.18)) {
            showingNoteField = false
        }
    }

    // MARK: - Notification permission banner

    @ViewBuilder
    private var notificationPermissionBanner: some View {
        if appState.notificationAuthorizationStatus == .denied {
            permissionBanner(
                icon: "bell.slash.fill",
                tint: .orange,
                title: "Buzzes are blocked",
                subtitle: "Turn them on in System Settings to hear when someone's brewing.",
                actionTitle: "Open Settings",
                action: { appState.openSystemNotificationSettings() }
            )
        } else if appState.notificationAuthorizationStatus == .notDetermined {
            permissionBanner(
                icon: "bell.badge",
                tint: .accentColor,
                title: "Allow buzzes?",
                subtitle: "So you know when someone nearby is brewing.",
                actionTitle: "Allow",
                action: { appState.requestNotificationPermission() }
            )
        }
    }

    private func permissionBanner(icon: String, tint: Color, title: String, subtitle: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(actionTitle, action: action)
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.borderless)
                    .padding(.top, 1)
            }
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.12)))
    }

    // MARK: - Incoming group invites

    @ViewBuilder
    private var incomingInvitesSection: some View {
        let invites = appState.pendingIncomingInvites
        if !invites.isEmpty {
            VStack(spacing: 6) {
                ForEach(invites) { invite in
                    inviteCard(invite)
                }
            }
        }
    }

    private func inviteCard(_ invite: BroadcastInvite) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.badge.plus").foregroundStyle(Color.accentColor)
                Text("\(invite.inviterName) invited you to the")
                    .font(.system(size: 12))
                Text("\(invite.groupName) crew")
                    .font(.system(size: 12, weight: .semibold))
            }
            HStack {
                Button("Join") { appState.acceptInvite(invite) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Button("Decline") { appState.declineInvite(invite) }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                    .controlSize(.small)
                Spacer()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor.opacity(0.35), lineWidth: 1))
        )
    }

    // MARK: - What's happening nearby

    @ViewBuilder
    private var whatsHappeningSection: some View {
        let runs = appState.activeRuns
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("What's happening nearby")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                if runs.count > 1 {
                    Text("\(runs.count) runs")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            if runs.isEmpty {
                emptyActivityRow
            } else {
                VStack(spacing: 6) {
                    ForEach(runs) { run in
                        activityRow(for: run)
                    }
                }
            }
        }
    }

    /// Empty state — says *why* the menu is quiet. The actual actions
    /// (Coffee Run button up top, "Invite a coworker" row below) already
    /// live in the menu, so we don't duplicate them here.
    private var emptyActivityRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 20))
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text("Nobody's brewing yet")
                    .font(.system(size: 12, weight: .semibold))
                Text("Be the first to start a run — or invite a coworker so you've got crew to brew with.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.04)))
    }

    private func activityRow(for run: CoffeeRun) -> some View {
        let isOwn = run.organizer.id == appState.ownPeerID
        let isParticipant = appState.isInRun(run)
        return VStack(alignment: .leading, spacing: 8) {
            // Top row: who + when + joiner avatars
            HStack(alignment: .top, spacing: 10) {
                InitialAvatar(name: run.organizer.displayName, online: true, size: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(activityHeadline(for: run, isOwn: isOwn))
                        .font(.system(size: 12, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 4) {
                        if let note = run.organizer.note, !note.isEmpty {
                            Image(systemName: "mappin").font(.system(size: 9))
                            Text(note).font(.system(size: 11))
                        }
                        if (run.organizer.note?.isEmpty ?? true) == false { Text("·").foregroundStyle(.tertiary) }
                        Text(timingPhrase(for: run))
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                if !run.joiners.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(run.joiners.prefix(3)) { joiner in
                            InitialAvatar(name: joiner.displayName, online: false, size: 22)
                                .overlay(Circle().stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5))
                        }
                    }
                    if run.joiners.count > 3 {
                        Text("+\(run.joiners.count - 3)")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.leading, 2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Action row: primary positive action + secondary destructive.
            // If you forget, the 30-min auto-expiry still logs the cup for you.
            HStack(spacing: 10) {
                if isParticipant {
                    Button("Got my coffee ☕") { appState.logCoffeeConsumed() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.83, green: 0.65, blue: 0.45))
                        .controlSize(.small)
                    Button(isOwn ? "Cancel run" : "Leave") { appState.leaveRun() }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.red)
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Text("Auto-logs in \(appState.expiryMinutes) min")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                } else {
                    Button("Join") { appState.joinRun(run) }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.83, green: 0.65, blue: 0.45))
                        .controlSize(.small)
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isParticipant ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        )
    }

    private func activityHeadline(for run: CoffeeRun, isOwn: Bool) -> String {
        let audience = run.organizer.audienceGroupID.flatMap { audID in
            appState.profile.joinedGroups.first(where: { $0.id == audID })?.name
        }

        if isOwn {
            // On the organizer's own card, lead with who joined — that's
            // the news. Fall back to crew/scope when nobody's joined yet.
            if let first = run.joiners.first {
                let suffix: String
                if run.joiners.count == 1 {
                    suffix = "\(first.displayName) joined"
                } else {
                    suffix = "\(first.displayName) + \(run.joiners.count - 1) joined"
                }
                return "Your coffee run · \(suffix)"
            }
            if let a = audience {
                return "Your coffee run · \(a) crew only · waiting for someone to join"
            }
            return "Your coffee run · waiting for someone to join"
        }

        // Other people's runs — flag explicitly when we ourselves are in it.
        let amIIn = appState.isInRun(run)
        let who = run.organizer.displayName
        if amIIn {
            return "You joined \(who)'s coffee run"
        }
        if let a = audience {
            return "\(who) is brewing with the \(a) crew"
        }
        return "\(who) is brewing a coffee run"
    }

    private func timingPhrase(for run: CoffeeRun) -> String {
        if let mins = run.organizer.minutesUntilStart, mins > 0 {
            return "Leaving in \(mins) min"
        }
        return run.organizer.relativeTimeString()
    }

    // MARK: - Utility row section (Caffeinated Mode, Add note, Invite, Stats)

    private var utilitySection: some View {
        VStack(spacing: 6) {
            utilityRow(
                icon: "bolt.fill",
                iconColor: .yellow,
                title: "Caffeinated Mode",
                subtitle: appState.isCaffeinated ? "Screen stays awake" : "Keep your screen awake",
                trailing: AnyView(
                    // Visual indicator only — the row's tap-action toggles it.
                    // (Putting an interactive Toggle inside a Button gets eaten
                    // by the Button's tap handler.)
                    Toggle("", isOn: .constant(appState.isCaffeinated))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                        .allowsHitTesting(false)
                ),
                action: { appState.toggleCaffeinated() }
            )
            utilityRow(
                icon: "note.text",
                iconColor: Color(red: 0.83, green: 0.65, blue: 0.45),
                title: "Add note",
                subtitle: appState.ownNote.isEmpty ? "Share a quick note" : appState.ownNote,
                trailing: AnyView(
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(showingNoteField ? 90 : 0))
                ),
                action: {
                    if !showingNoteField { noteDraft = appState.ownNote }
                    withAnimation(.easeOut(duration: 0.18)) {
                        showingNoteField.toggle()
                        showingRunOptions = false
                    }
                }
            )
            if showingNoteField {
                noteEditorInline
            }
            utilityRow(
                icon: "person.crop.circle.badge.plus",
                iconColor: Color.accentColor,
                title: "Invite a coworker",
                subtitle: "Share a QR or link to download Coffee Run",
                trailing: AnyView(Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(.tertiary)),
                action: {
                    appState.openInvite?()
                    dismissMenuBarPopover()
                }
            )
            utilityRow(
                icon: "chart.bar.fill",
                iconColor: Color(red: 0.83, green: 0.65, blue: 0.45),
                title: "My coffee energy",
                subtitle: "See your impact",
                trailing: AnyView(Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(.tertiary)),
                action: {
                    appState.openSettings?()
                    dismissMenuBarPopover()
                }
            )
        }
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.03)))
    }

    /// Inline version of the note editor that lives directly under the
    /// "Add note" row when expanded.
    private var noteEditorInline: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Add a quick note")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack(spacing: 6) {
                TextField("e.g. Meet at kitchen", text: $noteDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveNote() }
                Button("Save", action: saveNote)
                    .disabled(noteDraft == appState.ownNote)
                if !appState.ownNote.isEmpty {
                    Button("Clear") {
                        noteDraft = ""
                        saveNote()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 44)   // line up with the row's title text
        .padding(.trailing, 12)
        .padding(.bottom, 4)
    }

    private func utilityRow(icon: String, iconColor: Color, title: String, subtitle: String, trailing: AnyView, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(iconColor)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 12, weight: .semibold))
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                trailing
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    // MARK: - Bottom section (Settings, Profile, Quit)

    private var bottomSection: some View {
        VStack(spacing: 2) {
            bottomRow(icon: "gearshape", title: "Settings", color: nil) {
                appState.openSettings?()
                dismissMenuBarPopover()
            }
            bottomRow(icon: "person.crop.circle", title: "Profile", color: nil) {
                appState.openSettings?()
                dismissMenuBarPopover()
            }
            bottomRow(icon: "power", title: "Quit Coffee Run", color: .red) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.03)))
    }

    private func bottomRow(icon: String, title: String, color: Color?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color ?? .secondary)
                    .frame(width: 22)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color ?? .primary)
                Spacer()
                if color == nil {
                    Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footerText: some View {
        HStack(spacing: 4) {
            Text("Only visible to your crew nearby.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 2)
    }

    // MARK: - Toast

    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor)
                    .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
            )
    }

    private func showSuccessToast(for status: CoffeeStatus) {
        let message: String?
        switch status {
        case .wantCoffee:
            message = "You're looking for coffee company — visible for \(appState.expiryMinutes) min ✓"
        case .goingNow:
            let scopeSuffix = ownAudienceName().map { " · \($0) crew only" } ?? " · open to everyone"
            if let mins = appState.ownStartsAt.map({ Int(ceil($0.timeIntervalSinceNow / 60.0)) }), mins > 0 {
                message = "Coffee run scheduled in \(mins) min\(scopeSuffix) ✓"
            } else {
                message = "Coffee run started\(scopeSuffix) — visible for \(appState.expiryMinutes) min ✓"
            }
        case .joining:
            message = "Joined the coffee run ✓"
        case .available, .notAvailable:
            message = nil   // status itself is visible in hero card, no toast spam
        }
        guard let message = message else { return }
        toastDismissWorkItem?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            toastMessage = message
        }
        let work = DispatchWorkItem {
            withAnimation(.easeIn(duration: 0.2)) { toastMessage = nil }
        }
        toastDismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }

    // MARK: - Helpers

    private func ownAudienceName() -> String? {
        guard let audID = appState.ownAudienceGroupID else { return nil }
        return appState.profile.joinedGroups.first(where: { $0.id == audID })?.name
    }

    private func dismissMenuBarPopover() {
        DispatchQueue.main.async {
            appState.dismissMenuBar?()
        }
    }
}

// MARK: - Stat tile component

private struct StatTile: View {
    enum Icon {
        case networkCups
        case personalCup
    }

    let icon: Icon
    let value: Int
    let label: String
    let footerText: String
    let footerColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 8) {
                graphic
                    .frame(width: 60, height: 44)
                Text("\(value)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .frame(height: 44, alignment: .center)   // match graphic height for true v-center
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
            }
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(footerText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(footerColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var graphic: some View {
        switch icon {
        case .networkCups:
            // Reuse the hero cup illustration + small people icon on the
            // upper-left so it reads as "shared with the network."
            if let nsImage = NSImage(named: "coffeerun_herobig") {
                ZStack(alignment: .topLeading) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .interpolation(Image.Interpolation.high)
                        .antialiased(true)
                        .scaledToFit()
                    // Animated S-curve steam ribbons above the cup
                    SteamRibbons(ribbonCount: 2, color: Color(white: 0.95), maxOpacity: 0.40, lineWidth: 1.0)
                        .frame(width: 22, height: 18)
                        .offset(x: 16, y: -8)
                        .allowsHitTesting(false)
                        .blendMode(.plusLighter)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(white: 0.55))
                        .padding(3)
                        .background(
                            Circle()
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 1.5, y: 0.5)
                        )
                        .offset(x: -4, y: -2)
                }
            } else {
                ZStack(alignment: .topLeading) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(white: 0.65))
                        .offset(x: -2, y: -2)
                    cupSymbol
                }
            }
        case .personalCup:
            // Reuse the hero cup illustration; add an SF Symbol sparkles
            // overlay to the upper-right so it reads as "your" cup.
            if let nsImage = NSImage(named: "coffeerun_herobig") {
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .top) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .interpolation(Image.Interpolation.high)
                            .antialiased(true)
                            .scaledToFit()
                        SteamRibbons(ribbonCount: 2, color: Color(white: 0.95), maxOpacity: 0.40, lineWidth: 1.0)
                            .frame(width: 22, height: 18)
                            .offset(y: -8)
                            .allowsHitTesting(false)
                            .blendMode(.plusLighter)
                    }
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.orange)
                        .shadow(color: .orange.opacity(0.55), radius: 3, y: 0)
                        .offset(x: 4, y: -3)
                }
            } else {
                // SF Symbol fallback if asset is missing
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.orange)
                        .offset(x: 4, y: -4)
                    cupSymbol
                }
            }
        }
    }

    private var cupSymbol: some View {
        ZStack {
            SteamWisps(wispCount: 2, speed: 0.4, color: Color(white: 0.5), maxOpacity: 0.45)
                .frame(width: 14, height: 8)
                .offset(y: -12)
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.85, green: 0.65, blue: 0.42), Color(red: 0.6, green: 0.40, blue: 0.22)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: Color.brown.opacity(0.3), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - Big action button

private struct BigActionButton: View {
    let title: String
    let subtitle: String
    let iconName: String
    let background: Color
    let foreground: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(foreground)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(foreground.opacity(0.75))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? Color.white.opacity(0.6) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Initial avatar (auto-colored circle with initials)

/// 8pt colored dot with a breathing halo behind it. Conveys "presence —
/// this is live state" without being noisy.
struct BreathingStatusDot: View {
    let color: Color
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.40))
                .frame(width: 18, height: 18)
                .scaleEffect(pulse ? 1.0 : 0.6)
                .opacity(pulse ? 0.0 : 0.55)
                .animation(
                    .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                    value: pulse
                )
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .onAppear { pulse = true }
    }
}

struct InitialAvatar: View {
    let name: String
    var online: Bool = false
    var size: CGFloat = 32
    @State private var pulse = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size)
                .overlay(
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                )
            if online {
                ZStack {
                    // Breathing halo behind the dot — subtle "pulse of life"
                    Circle()
                        .fill(Color.green.opacity(0.35))
                        .frame(width: size * 0.42, height: size * 0.42)
                        .scaleEffect(pulse ? 1.25 : 0.85)
                        .opacity(pulse ? 0.0 : 0.6)
                        .animation(
                            .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                            value: pulse
                        )
                    Circle()
                        .fill(Color.green)
                        .frame(width: size * 0.28, height: size * 0.28)
                        .overlay(Circle().stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5))
                }
                .offset(x: 2, y: 2)
                .onAppear { pulse = true }
            }
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ", maxSplits: 1)
        if parts.count >= 2 {
            return "\(parts[0].first.map(String.init) ?? "")\(parts[1].first.map(String.init) ?? "")".uppercased()
        }
        return name.prefix(2).uppercased()
    }

    private var color: Color {
        // Deterministic color from the name hash so the same name always
        // gets the same color.
        var hash: UInt = 5381
        for ch in name.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ UInt(ch.value)
        }
        let palette: [Color] = [
            Color(red: 0.85, green: 0.55, blue: 0.40),
            Color(red: 0.45, green: 0.65, blue: 0.42),
            Color(red: 0.42, green: 0.55, blue: 0.85),
            Color(red: 0.75, green: 0.45, blue: 0.65),
            Color(red: 0.85, green: 0.70, blue: 0.30),
            Color(red: 0.42, green: 0.70, blue: 0.75),
            Color(red: 0.65, green: 0.50, blue: 0.80),
            Color(red: 0.80, green: 0.42, blue: 0.45)
        ]
        return palette[Int(hash) % palette.count]
    }
}
