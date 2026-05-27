import SwiftUI

/// A small composite icon: a steaming brown cup with an optional status
/// badge in the lower-right corner. Used in the menu's action rows.
struct CoffeeStatusIcon: View {
    enum Kind {
        case wantCoffee
        case goingNow
        case available
        case notAvailable
        case joining
        case addNote
        case caffeinated
    }

    let kind: Kind
    var size: CGFloat = 18

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Cup with steam rising above.
            ZStack(alignment: .top) {
                SteamWisps(
                    wispCount: 2,
                    speed: 0.35,
                    color: .brown,
                    maxOpacity: 0.55
                )
                .frame(width: size * 0.5, height: size * 0.4)
                .offset(y: -size * 0.4)

                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: size))
                    .foregroundStyle(Color.brown)
            }
            .frame(width: size * 1.25, height: size, alignment: .center)

            if let badge = badgeSpec {
                Image(systemName: badge.symbol)
                    .font(.system(size: size * 0.6, weight: .bold))
                    .foregroundStyle(badge.color)
                    .background(
                        Circle()
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .padding(1)
                    )
                    .offset(x: size * 0.05, y: size * 0.15)
            }
        }
        .frame(width: size * 1.5, height: size * 1.55, alignment: .center)
    }

    private var badgeSpec: (symbol: String, color: Color)? {
        switch kind {
        case .wantCoffee:
            return nil
        case .goingNow:
            return ("arrow.forward.circle.fill", Color.brown.opacity(0.85))
        case .available:
            return ("checkmark.circle.fill", .green)
        case .notAvailable:
            return ("xmark.circle.fill", .red)
        case .joining:
            return ("hand.wave.fill", .blue)
        case .addNote:
            return ("text.bubble.fill", .blue)
        case .caffeinated:
            return ("bolt.fill", .yellow)
        }
    }
}
