import SwiftUI

struct PeerRow: View {
    let peer: Peer

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(peer.status.symbol)
                .frame(width: 18, alignment: .center)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(peer.displayName)
                        .font(.system(size: 13, weight: .medium))
                    Text(peer.status.shortText)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Text(peer.relativeTimeString())
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    if let note = peer.note, !note.isEmpty {
                        Text("· \(note)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
