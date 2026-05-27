import SwiftUI

/// Two-layer hybrid steam — a slow expanding cloud body underneath, with
/// faster small wisps for turbulence detail on top. Each particle has
/// per-instance randomization (speed, sway, phase) so they don't cycle
/// in sync, which is what makes procedural steam look mechanical.
struct SteamHybrid: View {
    var color: Color = .white
    var maxOpacity: Double = 0.40

    /// Overall time multiplier — lower = slower / more languid.
    /// Default is intentionally slow because real steam rises gradually.
    var timeScale: Double = 1.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate * timeScale
                drawBody(in: ctx, size: size, t: t)
                drawDetail(in: ctx, size: size, t: t)
            }
        }
        .blur(radius: 0.7)   // gentle atmospheric haze
    }

    // MARK: - Body cloud (slow, large, expanding)

    private func drawBody(in ctx: GraphicsContext, size: CGSize, t: Double) {
        let count = 5
        // Each body particle takes ~12-15s to fully rise & fade —
        // visually feels like a continuous stream of steam, not loops.
        let baseSpeed = 0.075
        for i in 0..<count {
            let seed = Double(i + 1)
            let phaseOffset = Self.pseudoRandom(seed * 12.9898)
            let speedMult = 0.7 + Self.pseudoRandom(seed * 78.233) * 0.6   // 0.7–1.3
            let swayAmp = 0.06 + Self.pseudoRandom(seed * 5.91) * 0.09
            let swayFreq = 0.4 + Self.pseudoRandom(seed * 9.27) * 0.5
            let basePos = Self.pseudoRandom(seed * 13.45)                  // 0–1 of width
            let sizeJitter = 0.85 + Self.pseudoRandom(seed * 17.42) * 0.4

            let phase = ((t * baseSpeed * speedMult) + phaseOffset)
                .truncatingRemainder(dividingBy: 1)

            // Y rises from below the bottom to above the top
            let y = size.height * (1.15 - phase * 1.3)
            // Lateral drift around centerline
            let sway = sin(phase * .pi * 2 * swayFreq + seed) * size.width * swayAmp
            let x = size.width * (0.35 + basePos * 0.30) + sway

            // Expand as it rises (steam grows as it cools/disperses)
            let baseRadius = size.width * 0.15 * sizeJitter
            let radius = baseRadius * (1.0 + phase * 1.6)
            let alpha = sin(phase * .pi) * maxOpacity * 0.65

            let shading = GraphicsContext.Shading.radialGradient(
                Gradient(stops: [
                    .init(color: color.opacity(alpha), location: 0),
                    .init(color: color.opacity(alpha * 0.32), location: 0.55),
                    .init(color: color.opacity(0), location: 1.0)
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: radius
            )
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: rect), with: shading)
        }
    }

    // MARK: - Detail wisps (small, faster, chaotic)

    private func drawDetail(in ctx: GraphicsContext, size: CGSize, t: Double) {
        let count = 7
        let baseSpeed = 0.16   // still slow — ~6s per cycle
        for i in 0..<count {
            let seed = Double(i + 1) + 100
            let phaseOffset = Self.pseudoRandom(seed * 12.9898)
            let speedMult = 0.7 + Self.pseudoRandom(seed * 78.233) * 0.8   // 0.7–1.5
            let swayAmp = 0.08 + Self.pseudoRandom(seed * 5.91) * 0.12
            let swayFreq = 1.5 + Self.pseudoRandom(seed * 9.27) * 1.0
            let basePos = Self.pseudoRandom(seed * 13.45)
            let sizeJitter = 0.7 + Self.pseudoRandom(seed * 17.42) * 0.6

            let phase = ((t * baseSpeed * speedMult) + phaseOffset)
                .truncatingRemainder(dividingBy: 1)
            let y = size.height * (1.1 - phase * 1.2)
            let sway = sin(phase * .pi * 2 * swayFreq + seed) * size.width * swayAmp
            let x = size.width * (0.3 + basePos * 0.4) + sway

            let radius = size.width * 0.05 * sizeJitter * (1.0 + phase * 0.6)
            let alpha = sin(phase * .pi) * maxOpacity * 0.45

            let shading = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [
                    color.opacity(alpha),
                    color.opacity(0)
                ]),
                center: CGPoint(x: x, y: y),
                startRadius: 0,
                endRadius: radius
            )
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: rect), with: shading)
        }
    }

    // MARK: - Pseudo-random (deterministic per-particle)

    private static func pseudoRandom(_ x: Double) -> Double {
        let s = sin(x) * 43758.5453
        return s - floor(s)
    }
}
