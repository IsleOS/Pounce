//
//  PixelCardBackground.swift
//  ClaudeIsland
//
//  Always-on pixel grid with subtle breathing/shimmer. No hover
//  interaction. Pure function of (time, seed). Intended to sit as a
//  ZStack sibling behind the panel content.
//

import SwiftUI

struct PixelCardVariant {
    var gap: CGFloat
    var maxDotSize: CGFloat
    var colors: [Color]
    var baseFill: Color

    static let blue = PixelCardVariant(
        gap: 10,
        maxDotSize: 2,
        colors: [
            Color(hex: 0xE0F2FE),
            Color(hex: 0x7DD3FC),
            Color(hex: 0x0EA5E9)
        ],
        baseFill: Color(red: 0.05, green: 0.06, blue: 0.09)
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

@inline(__always)
private func cellRand(_ c: Int, _ r: Int, _ salt: UInt32) -> CGFloat {
    var h = UInt32(bitPattern: Int32(c &* 73)) ^ UInt32(bitPattern: Int32(r &* 151)) ^ salt
    h ^= h >> 13; h &*= 0x9E3779B1; h ^= h >> 16
    return CGFloat(h & 0xFFFF) / 65535.0
}

struct PixelCardBackground: View {
    var variant: PixelCardVariant = .blue
    var cornerRadius: CGFloat = 14
    /// Breathing cycle frequency (Hz). Lower = slower.
    var breatheHz: Double = 0.4
    /// Per-pixel shimmer frequency (Hz). Slightly faster than breathe.
    var shimmerHz: Double = 1.8
    /// Minimum alpha multiplier for a dot (0..1). Higher = always-visible.
    var baseAlpha: Double = 0.25

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(variant.baseFill)

            TimelineView(.animation(minimumInterval: 1.0/30.0, paused: false)) { timeline in
                Canvas { ctx, size in
                    renderPixels(ctx: ctx, size: size, now: timeline.date)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.6)
        }
    }

    private func renderPixels(ctx: GraphicsContext, size: CGSize, now: Date) {
        let gap = variant.gap
        let cols = Int(size.width / gap)
        let rows = Int(size.height / gap)
        let t = now.timeIntervalSinceReferenceDate
        // Global breathing envelope — all dots fade together
        let breathe = (sin(t * breatheHz * 2 * .pi) * 0.5 + 0.5) * 0.35 + 0.65  // 0.65..1.0

        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * gap + gap / 2
                let y = CGFloat(r) * gap + gap / 2

                let rnd1 = cellRand(c, r, 0xA5A5A5A5)  // size variation
                let rnd2 = cellRand(c, r, 0x5A5A5A5A)  // phase offset
                let rnd3 = cellRand(c, r, 0xC3C3C3C3)  // color pick

                let pixelMaxSize = (0.4 + rnd1 * 0.6) * variant.maxDotSize
                let color = variant.colors[Int(rnd3 * CGFloat(variant.colors.count)) % variant.colors.count]

                // Per-pixel shimmer with random phase offset
                let shimmer = (sin(t * shimmerHz * 2 * .pi + Double(rnd2) * 6.28) + 1) * 0.5
                let shimmerMul = 0.5 + shimmer * 0.5   // 0.5..1.0

                let alphaMul = baseAlpha + (1 - baseAlpha) * breathe * shimmerMul
                let currentSize = pixelMaxSize * CGFloat(alphaMul)
                guard currentSize > 0.15 else { continue }

                let offset = (variant.maxDotSize - currentSize) * 0.5
                let rect = CGRect(x: x + offset, y: y + offset, width: currentSize, height: currentSize)
                ctx.fill(Path(rect), with: .color(color.opacity(alphaMul)))
            }
        }
    }
}
