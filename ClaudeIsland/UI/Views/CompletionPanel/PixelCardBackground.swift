//
//  PixelCardBackground.swift
//  ClaudeIsland
//
//  Reactbits-style PixelCard effect, reimplemented as a pure
//  time-driven Canvas. Inspired by reactbits.dev/components/pixel-card
//  but uses stateless time math (not per-pixel mutable state +
//  Timer.publish → @Published tick) to avoid the SwiftUI layout
//  feedback that broke panel sizing in earlier attempts.
//
//  Design:
//  - No GeometryReader, no @ObservedObject, no Timer, no .background().
//  - Canvas reads `timeline.date` from TimelineView; per-pixel render is
//    a pure function of (time, hoverState, seed).
//  - Intended to sit as a ZStack sibling UNDERNEATH the panel content,
//    sized by the ZStack's other children. No layout side effects.
//

import SwiftUI

struct PixelCardVariant {
    var gap: CGFloat
    var maxDotSize: CGFloat
    var colors: [Color]
    var radialDarkColor: Color

    static let blue = PixelCardVariant(
        gap: 10, maxDotSize: 2,
        colors: [
            Color(hex: 0xE0F2FE), Color(hex: 0x7DD3FC), Color(hex: 0x0EA5E9)
        ],
        radialDarkColor: Color(hex: 0x09090B)
    )
    static let lime = PixelCardVariant(
        gap: 10, maxDotSize: 2,
        colors: [
            Color(hex: 0xEAFFB5), Color(hex: 0xCAFF00), Color(hex: 0x7DD3FC)
        ],
        radialDarkColor: Color(hex: 0x09090B)
    )
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double((hex >>  0) & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// Deterministic 0..1 hash for a grid cell.
@inline(__always)
private func cellRand(_ c: Int, _ r: Int, _ salt: UInt32) -> CGFloat {
    var h = UInt32(bitPattern: Int32(c &* 73)) ^ UInt32(bitPattern: Int32(r &* 151)) ^ salt
    h ^= h >> 13; h &*= 0x9E3779B1; h ^= h >> 16
    return CGFloat(h & 0xFFFF) / 65535.0
}

struct PixelCardBackground: View {
    var variant: PixelCardVariant = .blue
    var cornerRadius: CGFloat = 14
    var baseFill: Color = Color(red: 0.06, green: 0.07, blue: 0.10)

    /// Fade-in duration at the furthest pixel (center pixels fade in near-instantly).
    var fadeInSeconds: Double = 0.9
    /// Fade-out duration (uniform across pixels).
    var fadeOutSeconds: Double = 0.5
    /// Shimmer oscillation frequency (Hz) once fully appeared.
    var shimmerHz: Double = 2.2

    @State private var hoverStart: Date? = nil
    @State private var hoverEnd: Date? = nil

    var body: some View {
        ZStack {
            // 1. Base solid fill
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [baseFill, baseFill.opacity(0.92)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            // 2. Pixel Canvas — TimelineView only runs while an animation is active.
            TimelineView(.animation(minimumInterval: 1.0/60.0, paused: hoverStart == nil && hoverEnd == nil)) { timeline in
                Canvas { ctx, size in
                    renderPixels(ctx: ctx, size: size, now: timeline.date)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .allowsHitTesting(false)

            // 3. Radial dark-center overlay (reactbits ::before)
            RadialGradient(
                colors: [variant.radialDarkColor, variant.radialDarkColor.opacity(0)],
                center: .center, startRadius: 0, endRadius: 200
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(hoverProgress() * 0.6)
            .animation(.easeOut(duration: 0.6), value: hoverStart)
            .allowsHitTesting(false)

            // 4. Border — brightens on hover
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    hoverStart != nil
                        ? Color(hex: 0x7DD3FC).opacity(0.35)
                        : Color.white.opacity(0.10),
                    lineWidth: hoverStart != nil ? 0.9 : 0.6
                )
                .animation(.easeOut(duration: 0.25), value: hoverStart)
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onHover { hovering in
            let now = Date()
            if hovering {
                hoverStart = now
                hoverEnd = nil
            } else {
                hoverStart = nil
                hoverEnd = now
            }
        }
    }

    // MARK: - Rendering

    private func hoverProgress(at now: Date = Date()) -> Double {
        if let start = hoverStart {
            return min(1, now.timeIntervalSince(start) / fadeInSeconds)
        }
        if let end = hoverEnd {
            return max(0, 1 - now.timeIntervalSince(end) / fadeOutSeconds)
        }
        return 0
    }

    private func renderPixels(ctx: GraphicsContext, size: CGSize, now: Date) {
        let gap = variant.gap
        let cols = Int(size.width / gap)
        let rows = Int(size.height / gap)
        let cx = size.width / 2
        let cy = size.height / 2
        let maxDist = sqrt(cx * cx + cy * cy)
        let t = now.timeIntervalSinceReferenceDate
        let progress = hoverProgress(at: now)
        guard progress > 0.001 else { return }

        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * gap + gap / 2
                let y = CGFloat(r) * gap + gap / 2

                // Per-pixel stable random params
                let rnd1 = cellRand(c, r, 0xA5A5A5A5)   // max dot size
                let rnd2 = cellRand(c, r, 0x5A5A5A5A)   // shimmer phase offset
                let rnd3 = cellRand(c, r, 0xC3C3C3C3)   // color choice

                let pixelMaxSize = (0.5 + rnd1 * 0.5) * variant.maxDotSize  // 0.5 * max to 1.0 * max
                let color = variant.colors[Int(rnd3 * CGFloat(variant.colors.count)) % variant.colors.count]

                // Per-pixel delay based on distance from center — furthest last
                let dx = x - cx, dy = y - cy
                let distance = sqrt(dx * dx + dy * dy)
                let normalizedDelay = distance / maxDist       // 0..1
                let delaySec = normalizedDelay * fadeInSeconds * 0.85

                // Local per-pixel progress incorporates delay
                let localProgress: Double
                if let start = hoverStart {
                    let elapsed = now.timeIntervalSince(start) - delaySec
                    localProgress = max(0, min(1, elapsed / (fadeInSeconds * 0.15 + 0.0001)))
                } else {
                    // Fade out uniformly with no delay
                    localProgress = progress
                }
                guard localProgress > 0.001 else { continue }

                // Shimmer oscillation once appeared
                let shimmer = (sin(t * shimmerHz * 2 * .pi + Double(rnd2) * 6.28) + 1) * 0.5
                let shimmerFactor = 0.7 + shimmer * 0.3   // 0.7..1.0

                let currentSize = pixelMaxSize * CGFloat(localProgress) * CGFloat(shimmerFactor)
                guard currentSize > 0.15 else { continue }

                let offset = (variant.maxDotSize - currentSize) * 0.5
                let rect = CGRect(x: x + offset, y: y + offset, width: currentSize, height: currentSize)
                ctx.fill(Path(rect), with: .color(color))
            }
        }
    }
}
