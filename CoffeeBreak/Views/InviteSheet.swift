import SwiftUI
import AppKit

/// Standalone "Invite a coworker" panel — opened from the menu's utility
/// row or its empty state. Shows a QR + a copyable link to the Coffee Run
/// download page, with a system share button as the fast path.
///
/// V1 points at the GitHub repo. Once we cut a Release, switch to the
/// /releases/latest URL so the QR resolves directly to the DMG.
struct InviteSheet: View {
    @EnvironmentObject var appState: AppState

    /// Where the QR + copyable link point.
    private let inviteURL = "https://coffee-run-landing-page.vercel.app"
    private let qrPixelSize: CGFloat = 180

    @State private var copied = false

    var body: some View {
        VStack(spacing: 16) {
            header
            qrCode
            linkRow
            shareRow
            footerTip
        }
        .padding(20)
        .frame(width: 340)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .foregroundStyle(Color.accentColor)
                Text("Bring a coworker to Coffee Run")
                    .font(.system(size: 15, weight: .bold))
            }
            Text("They install, open the app, and they'll show up next to you in your crew.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var qrCode: some View {
        if let qr = QRCodeGenerator.image(from: inviteURL) {
            Image(nsImage: qr)
                .interpolation(.none)   // keep the QR pixels crisp
                .resizable()
                .frame(width: qrPixelSize, height: qrPixelSize)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.06))
                .frame(width: qrPixelSize, height: qrPixelSize)
                .overlay(
                    Text("QR unavailable")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                )
        }
    }

    private var linkRow: some View {
        VStack(spacing: 6) {
            Text(inviteURL)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
        }
    }

    private var shareRow: some View {
        HStack(spacing: 8) {
            Button(action: copyLink) {
                HStack(spacing: 4) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    Text(copied ? "Copied" : "Copy link")
                }
                .frame(minWidth: 90)
            }
            .buttonStyle(.bordered)

            Button(action: shareLink) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share…")
                }
                .frame(minWidth: 90)
            }
            .buttonStyle(.bordered)
        }
    }

    private var footerTip: some View {
        Text("Tip: hand them your phone to scan the QR, or AirDrop the link from another device.")
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6)
    }

    // MARK: - Actions

    private func copyLink() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(inviteURL, forType: .string)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { copied = false }
        }
    }

    private func shareLink() {
        guard let url = URL(string: inviteURL) else { return }
        let picker = NSSharingServicePicker(items: [url])
        // Anchor to the share button's window content so AppKit knows
        // where to draw the popover.
        if let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }),
           let view = window.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
}
