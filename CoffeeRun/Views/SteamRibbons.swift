import SwiftUI

/// Stylized S-curve "steam ribbons" — bezier paths that wave and shift
/// over time, stroked with a vertical opacity gradient so they fade out
/// at the top. Matches the illustrated style of drawn-in steam in the
/// cup images. Used by the small stat tiles.
struct SteamRibbons: View {
    var ribbonCount: Int = 2
    var color: Color = .white
    var maxOpacity: Double = 0.55
    var lineWidth: CGFloat = 1.6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let w = size.width
                let h = size.height

                for i in 0..<ribbonCount {
                    drawRibbon(in: ctx, w: w, h: h, t: t, index: i)
                }
            }
        }
    }

    private func drawRibbon(in ctx: GraphicsContext, w: CGFloat, h: CGFloat, t: Double, index i: Int) {
        let offset = Double(i) * 0.6
        // Distribute ribbons across the width (centered if just one).
        let xCenter: CGFloat = ribbonCount == 1
            ? w * 0.5
            : w * (0.35 + CGFloat(i) * 0.3 / CGFloat(max(1, ribbonCount - 1)))

        // Slowly drifting endpoints — ~3x slower than before so the
        // ribbons feel like real rising steam waving in air, not bouncing.
        let bottomX = xCenter + CGFloat(sin(t * 0.12 + offset) * Double(w) * 0.04)
        let topX = xCenter + CGFloat(sin(t * 0.18 + offset + 1.7) * Double(w) * 0.18)

        // Control points wave to create the S-curve, varying with time
        let waveA = sin(t * 0.24 + offset) * Double(w) * 0.20
        let waveB = sin(t * 0.24 + offset + .pi) * Double(w) * 0.20

        let cp1 = CGPoint(x: xCenter + CGFloat(waveA), y: h * 0.65)
        let cp2 = CGPoint(x: xCenter + CGFloat(waveB), y: h * 0.30)

        var path = Path()
        path.move(to: CGPoint(x: bottomX, y: h))
        path.addCurve(
            to: CGPoint(x: topX, y: 0),
            control1: cp1,
            control2: cp2
        )

        // Stroke with vertical gradient — opaque at the bottom (near the
        // cup), fading to transparent at the top (dissipating into air).
        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: color.opacity(maxOpacity), location: 0.0),
                .init(color: color.opacity(maxOpacity * 0.55), location: 0.55),
                .init(color: color.opacity(0), location: 1.0)
            ]),
            startPoint: CGPoint(x: w / 2, y: h),
            endPoint: CGPoint(x: w / 2, y: 0)
        )

        ctx.stroke(
            path,
            with: shading,
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }
}
