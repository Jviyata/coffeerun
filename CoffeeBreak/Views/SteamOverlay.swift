import SwiftUI
import AppKit

// MARK: - The visual

/// One-shot full-screen steam: ~80 soft particles spawn from the bottom over
/// ~1.5s, rise the full height of the screen, sway horizontally, and fade.
/// The whole effect lasts about 6 seconds.
struct FullScreenSteam: View {
    private static let particleCount = 80
    private static let spawnWindow: TimeInterval = 1.5
    static let totalDuration: TimeInterval = 6.0

    private let startTime = Date()
    private let particles: [Particle]

    init() {
        // Generate once so the look is stable across redraws.
        self.particles = (0..<Self.particleCount).map { i in
            let seed = Double(i + 1)
            return Particle(
                birthDelay: Self.pseudoRandom(seed * 1.234) * Self.spawnWindow,
                lifetime: 3.4 + Self.pseudoRandom(seed * 5.678) * 1.0,
                xFraction: Self.pseudoRandom(seed * 7.891),
                radius: 70 + Self.pseudoRandom(seed * 9.012) * 110,
                swayAmp: 30 + Self.pseudoRandom(seed * 11.345) * 70,
                swayFreq: 0.5 + Self.pseudoRandom(seed * 13.678) * 0.9,
                swayPhase: Self.pseudoRandom(seed * 15.901) * .pi * 2,
                maxOpacity: 0.45 + Self.pseudoRandom(seed * 17.234) * 0.4,
                warmth: Self.pseudoRandom(seed * 19.567)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                Canvas { ctx, size in
                    let elapsed = context.date.timeIntervalSince(startTime)
                    for p in particles {
                        let t = elapsed - p.birthDelay
                        if t < 0 || t > p.lifetime { continue }

                        let progress = t / p.lifetime

                        // Travel from below the bottom to above the top.
                        // Use an ease-out curve so wisps slow as they rise —
                        // mimics real steam losing momentum.
                        let eased = 1 - pow(1 - progress, 1.7)
                        let startY = size.height + p.radius * 0.6
                        let endY = -p.radius * 0.6
                        let y = startY + (endY - startY) * eased

                        // Horizontal sway.
                        let sway = sin(t * p.swayFreq + p.swayPhase) * p.swayAmp
                        let x = size.width * p.xFraction + sway

                        // Opacity envelope:
                        //   0–12%  fade in
                        //   12–65% full
                        //   65–100% fade out
                        let envelope: Double
                        if progress < 0.12 {
                            envelope = progress / 0.12
                        } else if progress < 0.65 {
                            envelope = 1.0
                        } else {
                            envelope = max(0, (1.0 - progress) / 0.35)
                        }
                        let alpha = envelope * p.maxOpacity

                        // Slight warm-white tint to feel like coffee steam.
                        let coreColor = Color(
                            red: 1.0,
                            green: 0.97 - p.warmth * 0.05,
                            blue: 0.92 - p.warmth * 0.07
                        )

                        let shading = GraphicsContext.Shading.radialGradient(
                            Gradient(stops: [
                                .init(color: coreColor.opacity(alpha), location: 0),
                                .init(color: coreColor.opacity(alpha * 0.35), location: 0.55),
                                .init(color: coreColor.opacity(0), location: 1.0)
                            ]),
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: p.radius
                        )
                        let rect = CGRect(
                            x: x - p.radius,
                            y: y - p.radius,
                            width: p.radius * 2,
                            height: p.radius * 2
                        )
                        ctx.fill(Path(ellipseIn: rect), with: shading)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private struct Particle {
        let birthDelay: TimeInterval
        let lifetime: TimeInterval
        let xFraction: Double
        let radius: Double
        let swayAmp: Double
        let swayFreq: Double
        let swayPhase: Double
        let maxOpacity: Double
        let warmth: Double
    }

    private static func pseudoRandom(_ x: Double) -> Double {
        let s = sin(x) * 43758.5453
        return s - floor(s)
    }
}

// MARK: - The overlay window

@MainActor
final class SteamOverlayController {
    private var windows: [NSWindow] = []
    private var dismissWorkItem: DispatchWorkItem?
    private var lastShownAt: Date?

    /// Don't replay the overlay if it was triggered very recently — prevents
    /// the screen from being saturated when many peers signal in succession.
    private let cooldown: TimeInterval = 60

    /// Show full-screen steam on every connected display, then auto-dismiss
    /// once the last particle finishes.
    /// - Parameter respectCooldown: When true (default), suppress if a show
    ///   has fired within the past minute. Pass `false` for actions the user
    ///   triggered themselves so they always see the celebration.
    func show(respectCooldown: Bool = true) {
        if respectCooldown, let last = lastShownAt, Date().timeIntervalSince(last) < cooldown {
            return
        }
        lastShownAt = Date()
        dismiss()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .stationary,
                .ignoresCycle,
                .fullScreenAuxiliary
            ]
            window.contentView = NSHostingView(rootView: FullScreenSteam())
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()
            windows.append(window)
        }

        let work = DispatchWorkItem { [weak self] in
            self?.dismiss()
        }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + FullScreenSteam.totalDuration,
            execute: work
        )
    }

    func dismiss() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        for w in windows {
            w.orderOut(nil)
        }
        windows.removeAll()
    }
}
