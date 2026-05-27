import SwiftUI

/// Compact stat card: small illustrated cup graphic with a count badge
/// overlapping it, plus a tight label underneath.
struct CoffeeStatsCard: View {
    enum Style {
        case network
        case personal

        var badgeColor: Color {
            switch self {
            case .network: return Color(white: 0.12)
            case .personal: return Color.orange
            }
        }
    }

    let count: Int
    let label: String
    let style: Style

    var body: some View {
        VStack(spacing: 3) {
            graphicWithBadge
                .frame(height: 44)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 28, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
        )
    }

    // MARK: - Graphic + badge

    private var graphicWithBadge: some View {
        ZStack(alignment: .bottomTrailing) {
            cupGraphic
                .frame(width: 80, height: 44)
            countBadge
                .offset(x: 2, y: 0)
        }
    }

    @ViewBuilder
    private var cupGraphic: some View {
        switch style {
        case .network: networkCups
        case .personal: personalCup
        }
    }

    private var networkCups: some View {
        // Three cups in a row: small · big · small. No overlap — reads
        // cleanly as "a few cups together" instead of a stack.
        HStack(alignment: .bottom, spacing: 5) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color.brown.opacity(0.85))

            ZStack(alignment: .top) {
                SteamWisps(wispCount: 3, speed: 0.4, color: Color(white: 0.25), maxOpacity: 0.55)
                    .frame(width: 22, height: 10)
                    .offset(y: -10)

                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.brown)
            }

            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color.brown.opacity(0.85))
        }
    }

    private var personalCup: some View {
        ZStack {
            SteamWisps(wispCount: 2, speed: 0.4, color: Color(white: 0.25), maxOpacity: 0.55)
                .frame(width: 16, height: 10)
                .offset(x: -3, y: -14)

            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.brown)

            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(Color.orange)
                .offset(x: 19, y: -11)

            Image(systemName: "sparkle")
                .font(.system(size: 7, weight: .heavy))
                .foregroundStyle(Color.orange)
                .offset(x: 24, y: -3)
        }
    }

    private var countBadge: some View {
        Text("\(count)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(style.badgeColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5)
                    )
            )
            .contentTransition(.numericText())
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: count)
    }
}
