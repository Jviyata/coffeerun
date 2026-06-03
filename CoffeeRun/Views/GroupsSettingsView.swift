import SwiftUI

/// Embeddable "Coffee Groups" section for Profile & Settings. Lets the
/// user create a group, invite nearby peers, see members, and leave.
struct GroupsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var newGroupName: String = ""
    @State private var inviteSheetGroupID: UUID?

    var body: some View {
        Section("Coffee Crews") {
            if appState.profile.joinedGroups.isEmpty {
                Text("Start a crew to coffee with a specific set of people. Only crew members see each other's runs when the crew is selected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(appState.profile.joinedGroups) { group in
                groupRow(group)
            }

            HStack {
                TextField("New crew name", text: $newGroupName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { createGroup() }
                Button("Start crew", action: createGroup)
                    .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(item: Binding(
            get: { inviteSheetGroupID.map { IDWrapper(id: $0) } },
            set: { inviteSheetGroupID = $0?.id }
        )) { wrapper in
            InvitePeersSheet(groupID: wrapper.id)
                .environmentObject(appState)
        }
    }

    private func groupRow(_ group: CoffeeGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(group.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text("\(appState.memberCount(of: group.id)) in this crew · join code \(group.joinCode)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Invite") {
                    inviteSheetGroupID = group.id
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Button("Leave") {
                    appState.leaveGroup(group.id)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
                .controlSize(.small)
            }
            let pendingForThisGroup = appState.profile.pendingInvitesSent.filter { $0.groupID == group.id }
            if !pendingForThisGroup.isEmpty {
                Text("Waiting on \(pendingForThisGroup.count) invite\(pendingForThisGroup.count == 1 ? "" : "s") to be accepted")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private func createGroup() {
        appState.createGroup(name: newGroupName)
        newGroupName = ""
    }
}

private struct IDWrapper: Identifiable {
    let id: UUID
}

/// Sheet for picking nearby peers to invite into a group.
struct InvitePeersSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let groupID: UUID

    @State private var selected: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Invite to \(groupName) crew")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }

            if invitableCandidates.isEmpty {
                Text("No nearby people to invite right now.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(invitableCandidates) { peer in
                            HStack {
                                Image(systemName: selected.contains(peer.id)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected.contains(peer.id) ? Color.accentColor : .secondary)
                                Text(peer.displayName)
                                    .font(.system(size: 13))
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selected.contains(peer.id) {
                                    selected.remove(peer.id)
                                } else {
                                    selected.insert(peer.id)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }

            HStack {
                Spacer()
                Button("Send invites") {
                    appState.invitePeers(Array(selected), toGroup: groupID)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private var groupName: String {
        appState.profile.joinedGroups.first(where: { $0.id == groupID })?.name ?? "group"
    }

    /// Peers we can invite — currently visible and not already members.
    private var invitableCandidates: [Peer] {
        let existingMemberIDs = Set(appState.members(of: groupID).map { $0.id })
        let alreadyInvitedIDs = Set(appState.profile.pendingInvitesSent
            .filter { $0.groupID == groupID }
            .map { $0.inviteeID })
        return appState.allRecentPeers.filter { peer in
            !existingMemberIDs.contains(peer.id) && !alreadyInvitedIDs.contains(peer.id)
        }
    }
}
