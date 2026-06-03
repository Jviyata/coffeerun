import SwiftUI

/// Procedural rising-steam animation. Two soft wisps drift upward and fade.
/// Designed to be size-agnostic so it can render at 8pt in the menu bar
/// or 100pt in the welcome illustration.
struct SteamWisps: View {
    var wispCount: Int = 2
    /// Cycles per second per wisp.
    var speed: Double = 0.4
    var color: Color = .primary
    var maxOpacity: Double = 0.55

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate * speed
                for i in 0..<wispCount {
                    let offset = Double(i) / Double(wispCount)
                    let phase = (t + offset).truncatingRemainder(dividingBy: 1)
                    let y = size.height * (1 - phase)
                    let sway = CGFloat(sin(phase * .pi * 2)) * size.width * 0.18
                    let x = size.width / 2 + sway
                    let opacity = sin(phase * .pi) * maxOpacity
                    let radius = size.width * 0.18
                    let rect = CGRect(
                        x: x - radius,
                        y: y - radius * 1.4,
                        width: radius * 2,
                        height: radius * 2.6
                    )
                    ctx.fill(
                        Path(ellipseIn: rect),
                        with: .color(color.opacity(opacity))
                    )
                }
            }
        }
    }
}
