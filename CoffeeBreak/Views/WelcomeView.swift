import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    SteamWisps(wispCount: 2, speed: 0.35, color: .brown, maxOpacity: 0.45)
                        .frame(width: 18, height: 14)
                        .offset(y: -14)
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.brown)
                }
                .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to Coffee Run ☕")
                        .font(.headline)
                    Text("See who nearby is brewing coffee — only with your crew.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("What should we call you?")
                    .font(.subheadline)
                TextField("Your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .focused($nameFocused)
                    .onSubmit(submit)
            }

            HStack {
                Spacer()
                Button("Get Started", action: submit)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text("Coffee Run only chats with people right around you.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
        .onAppear { nameFocused = true }
    }

    private func submit() {
        appState.completeSetup(displayName: name)
    }
}
