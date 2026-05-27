import SwiftUI
import UserNotifications

/// Profile & Settings window — five-tab layout to keep each panel
/// focused and the window compact.
struct PreferencesView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            ProfileTab()
                .environmentObject(appState)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }

            NotificationsTab()
                .environmentObject(appState)
                .tabItem { Label("Buzz", systemImage: "bell.badge") }

            GroupsTab()
                .environmentObject(appState)
                .tabItem { Label("Crews", systemImage: "person.3.fill") }

            GeneralTab()
                .environmentObject(appState)
                .tabItem { Label("General", systemImage: "gearshape") }

            AboutHelpTab()
                .environmentObject(appState)
                .tabItem { Label("Help", systemImage: "info.circle") }
        }
        .frame(minWidth: 560, idealWidth: 600, maxWidth: 720,
               minHeight: 540, idealHeight: 560, maxHeight: 780)
    }
}

// MARK: - Profile tab

private struct ProfileTab: View {
    @EnvironmentObject var appState: AppState
    @State private var editingName: String = ""
    @State private var editingEmoji: String = ""

    var body: some View {
        Form {
            Section("Your profile") {
                let profile = appState.profile
                HStack(spacing: 12) {
                    Text(profile.avatarEmoji ?? "☕")
                        .font(.system(size: 36))
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.brown.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.displayName.isEmpty ? "—" : profile.displayName)
                            .font(.headline)
                        Text("On Coffee Run since \(memberSinceLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    statTile(value: profile.coffeesToday, label: "Today")
                    statTile(value: profile.coffeesThisWeek, label: "This week")
                    statTile(value: profile.lifetimeCoffees, label: "All time")
                }

                HStack {
                    Label("People in your coffee crew", systemImage: "person.2.fill")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(profile.peopleMet.count)")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }

                HStack {
                    Label("Days with at least one coffee", systemImage: "calendar")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(profile.daysActive)")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
            }

            Section("Identity") {
                TextField("Display name", text: $editingName)
                    .onSubmit { appState.updateDisplayName(editingName) }
                TextField("Avatar emoji", text: $editingEmoji, prompt: Text("e.g. ☕ or 🐱"))
                    .onSubmit { appState.updateAvatarEmoji(editingEmoji) }
                HStack {
                    Button("Save name") { appState.updateDisplayName(editingName) }
                        .disabled(editingName.trimmingCharacters(in: .whitespaces).isEmpty
                                  || editingName == appState.displayName)
                    Button("Save emoji") { appState.updateAvatarEmoji(editingEmoji) }
                        .disabled(editingEmoji == (appState.profile.avatarEmoji ?? ""))
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            editingName = appState.displayName
            editingEmoji = appState.profile.avatarEmoji ?? ""
        }
    }

    private func statTile(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
    }

    private var memberSinceLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: appState.profile.createdAt)
    }
}

// MARK: - Notifications tab

private struct NotificationsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var testSentAt: Date?

    var body: some View {
        Form {
            Section("Coffee buzzes") {
                Toggle("Buzz me when someone's brewing", isOn: $appState.notificationsEnabled)
                Toggle("Play sound", isOn: $appState.soundEnabled)
                    .disabled(!appState.notificationsEnabled)
                notificationStatusRow

                HStack(spacing: 8) {
                    if appState.notificationAuthorizationStatus == .authorized
                        || appState.notificationAuthorizationStatus == .provisional {
                        Button("Send test buzz") {
                            appState.sendTestNotification()
                            testSentAt = Date()
                        }
                        if let sentAt = testSentAt,
                           Date().timeIntervalSince(sentAt) < 5 {
                            Text("Sent — check Notification Center")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Open Notification Settings…") {
                        appState.openSystemNotificationSettings()
                    }
                }
            }

            Section("Full-screen steam") {
                Toggle("Show steam when anyone brews coffee",
                       isOn: $appState.showSteamForAllSignals)
                Text("By default, full-screen steam only fires for your own coffee runs and when someone joins a run you started. Turn this on to also see it for every brew nearby — fun in small crews, distracting in bigger ones.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            appState.refreshNotificationAuthStatus()
        }
    }

    @ViewBuilder
    private var notificationStatusRow: some View {
        switch appState.notificationAuthorizationStatus {
        case .authorized, .provisional:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("macOS buzzes are enabled").font(.caption)
                Spacer()
            }
        case .denied:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("macOS is blocking buzzes for Coffee Run").font(.caption)
                }
                Text("Open System Settings → Notifications → Coffee Run and turn “Allow Notifications” on.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .notDetermined:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill").foregroundStyle(.secondary)
                    Text("Coffee Run hasn’t asked to buzz you yet").font(.caption)
                }
                Button("Allow buzzes") {
                    appState.requestNotificationPermission()
                }
            }
        @unknown default:
            EmptyView()
        }
    }
}

// MARK: - Groups tab

private struct GroupsTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            GroupsSettingsView()
        }
        .formStyle(.grouped)
    }
}

// MARK: - General tab

private struct GeneralTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Coffee energy") {
                Picker("Runs expire after", selection: $appState.expiryMinutes) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("60 minutes").tag(60)
                }
                Text("How long your coffee energy (brewing / running / joining) stays visible to your crew before auto-clearing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Launch Coffee Run at login", isOn: $appState.startAtLogin)
            }

            Section("Quick coffee run") {
                HStack {
                    Label("Global shortcut", systemImage: "keyboard")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("⌃⌥C")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.08)))
                }
                Text("Press ⌃⌥C from anywhere on your Mac to start an immediate coffee run, open to everyone nearby. The menu opens so you can cancel or adjust.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Try it out") {
                Toggle("Show a demo crew in the menu", isOn: $appState.demoModeEnabled)
                Text("Adds a few fake coworkers and a sample run so you can see what Coffee Run looks like with an active crew. Doesn't broadcast anything or change your stats.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("iCloud sync") {
                Toggle("Sync stats across my Macs via iCloud", isOn: $appState.cloudSyncEnabled)
                    .disabled(!appState.iCloudAvailable)
                if !appState.iCloudAvailable {
                    Text("Sign in to iCloud in System Settings to enable sync.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Lifetime cups, people met, and other stats follow you to your other Macs signed into the same Apple ID. Nothing leaves your iCloud account.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - About & Help tab

private struct AboutHelpTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                helpHeader

                helpSection(title: "Day-to-day", items: [
                    ("cup.and.saucer", "Available / Not available",
                     "What you broadcast when you're idle. Click the menu bar cup → pick one. It sticks across launches."),
                    ("figure.walk", "Coffee Run",
                     "Start a run. Pick Now, In 5 min, or In 15 min. Everyone nearby sees your run and can tap Join."),
                    ("hand.wave.fill", "Join",
                     "Someone else started a run. Click Join on their card (or in the notification) → you're added. They see you joined."),
                    ("text.bubble.fill", "Add note",
                     "\"kitchen\", \"lobby\", \"leaving in 5\". Everyone in your run sees it under your name."),
                    ("bolt.fill", "Caffeinated",
                     "Keeps your Mac awake (no sleep). Doesn't change your coffee status.")
                ])

                helpSection(title: "Crews (for bigger offices)", items: [
                    ("person.3.fill", "Start a crew",
                     "Profile & Settings → Crews → Start crew. Invite specific coworkers by checking nearby names."),
                    ("line.3.horizontal.decrease.circle", "Filter the menu",
                     "Use the “Showing:” picker at the top of the menu to see only your crew's people and runs.")
                ])

                helpSection(title: "Coffee energy", items: [
                    ("☕", "Cups with your crew",
                     "Each completed Coffee Run adds 1 cup. The header shows your cups today and the crew total."),
                    ("👥", "People in your crew",
                     "Anyone you've ever brewed coffee with nearby. Carries across all your crews (home, office, cafés).")
                ])

                helpSection(title: "Privacy", items: [
                    ("lock.fill", "Local network only",
                     "Coffee Run uses Bonjour / mDNS to find your crew on the same Wi-Fi. Nothing leaves your local network."),
                    ("nosign", "No accounts, no cloud",
                     "No login, no analytics, no servers. Your name and profile live in macOS preferences on this Mac.")
                ])

                Divider().padding(.vertical, 4)

                aboutFooter
            }
            .padding(20)
        }
    }

    private var helpHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("How Coffee Run works")
                .font(.title2.weight(.bold))
            Text("A tiny menu bar app for spontaneous office coffee runs.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func helpSection(title: String, items: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.1) { icon, name, body in
                    HStack(alignment: .top, spacing: 10) {
                        helpIcon(icon)
                            .frame(width: 22, alignment: .center)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name).font(.system(size: 13, weight: .semibold))
                            Text(body).font(.system(size: 12)).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func helpIcon(_ name: String) -> some View {
        // If it's an SF Symbol name (no spaces, lowercase-ish), render as image.
        // Otherwise treat as an emoji / glyph.
        if name.contains(".") || name == "nosign" {
            Image(systemName: name).foregroundStyle(Color.brown)
        } else {
            Text(name).font(.system(size: 14))
        }
    }

    private var aboutFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Coffee Run")
                .font(.headline)
            Text("Version 1.1 (build 2)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("© 2026 — Only with your crew nearby.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }
}
