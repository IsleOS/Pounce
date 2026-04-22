//
//  PixelCardBackground.swift
//  ClaudeIsland
//
//  Faithful SwiftUI port of reactbits.dev/components/pixel-card.
//
//  Each pixel starts at size 0. On hover, pixels "appear" — size grows
//  from 0 to a random maxSize, but after a per-pixel delay proportional
//  to its distance from the card center. Once a pixel reaches maxSize,
//  it "shimmers" (size oscillates min↔max at the variant speed). On
//  hover-exit, pixels "disappear" — size shrinks back to 0. When all
//  are idle (size 0) the animation loop stops.
//
//  Plus a radial dark-center overlay (::before in the CSS source) that
//  fades in 0→1 over ~800ms on hover.
//

import SwiftUI
import Combine
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Variant

struct PixelCardVariant {
    var gap: CGFloat = 10
    var speedParam: Int = 25          // maps through throttle (×0.001)
    var colors: [Color] = [
        Color(hex: 0xE0F2FE),         // sky-100
        Color(hex: 0x7DD3FC),         // sky-300
        Color(hex: 0x0EA5E9)          // sky-500
    ]
    var radialDarkColor: Color = Color(hex: 0x09090B)
    var maxSizeInteger: CGFloat = 2   // upper bound for pixel maxSize

    static let blue    = PixelCardVariant()
    static let `default` = PixelCardVariant(
        gap: 5, speedParam: 35,
        colors: [Color(hex: 0xF8FAFC), Color(hex: 0xF1F5F9), Color(hex: 0xCBD5E1)]
    )
    static let yellow  = PixelCardVariant(
        gap: 3, speedParam: 20,
        colors: [Color(hex: 0xFEF08A), Color(hex: 0xFDE047), Color(hex: 0xEAB308)]
    )
    static let pink    = PixelCardVariant(
        gap: 6, speedParam: 80,
        colors: [Color(hex: 0xFECDD3), Color(hex: 0xFDA4AF), Color(hex: 0xE11D48)]
    )
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double((hex >>  0) & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Pixel

private struct Pixel {
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let speed: CGFloat
    let sizeStep: CGFloat
    let minSize: CGFloat = 0.5
    let maxSizeInteger: CGFloat
    let maxSize: CGFloat
    let delay: CGFloat
    let counterStep: CGFloat

    var size: CGFloat = 0
    var counter: CGFloat = 0
    var isIdle: Bool = false
    var isReverse: Bool = false
    var isShimmer: Bool = false

    mutating func appear() {
        isIdle = false
        if counter <= delay {
            counter += counterStep
            return
        }
        if size >= maxSize { isShimmer = true }
        if isShimmer {
            shimmer()
        } else {
            size += sizeStep
        }
    }

    mutating func disappear() {
        isShimmer = false
        counter = 0
        if size <= 0 {
            isIdle = true
            return
        }
        size -= 0.1
    }

    private mutating func shimmer() {
        if size >= maxSize { isReverse = true }
        else if size <= minSize { isReverse = false }
        if isReverse { size -= speed } else { size += speed }
    }
}

// MARK: - Model (reference type — mutates in place, publishes a tick)

@MainActor
private final class PixelGridModel: ObservableObject {
    @Published private(set) var tick: Int = 0

    fileprivate var pixels: [Pixel] = []
    private var mode: Mode = .idle
    private var frameTimer: Timer?

    private enum Mode { case idle, appearing, disappearing }

    func rebuild(size: CGSize, variant: PixelCardVariant, reducedMotion: Bool) {
        let w = size.width, h = size.height
        guard w > 0, h > 0 else { pixels = []; return }

        let gap = variant.gap
        let cols = stride(from: 0.0, to: w, by: gap)
        let rows = stride(from: 0.0, to: h, by: gap)
        let cx = w / 2, cy = h / 2
        let effectiveSpeed = Self.effectiveSpeed(variant.speedParam, reducedMotion: reducedMotion)

        var next: [Pixel] = []
        next.reserveCapacity(Int(w / gap) * Int(h / gap))

        for x in cols {
            for y in rows {
                let color = variant.colors.randomElement() ?? .white
                let dx = x - cx, dy = y - cy
                let distance = sqrt(dx * dx + dy * dy)
                let delay = reducedMotion ? 0 : distance
                let speed = CGFloat.random(in: 0.1...0.9) * effectiveSpeed
                let sizeStep = CGFloat.random(in: 0..<0.4)
                let maxSize = CGFloat.random(in: 0.5...variant.maxSizeInteger)
                let counterStep = CGFloat.random(in: 0..<4) + (w + h) * 0.01

                next.append(Pixel(
                    x: x, y: y, color: color,
                    speed: speed, sizeStep: sizeStep,
                    maxSizeInteger: variant.maxSizeInteger, maxSize: maxSize,
                    delay: delay, counterStep: counterStep
                ))
            }
        }
        pixels = next
        // Force redraw of empty state
        tick &+= 1
    }

    func startAppear() {
        mode = .appearing
        startLoop()
    }

    func startDisappear() {
        mode = .disappearing
        startLoop()
    }

    private func startLoop() {
        if frameTimer != nil { return }
        // 60fps timer. NSWindow vsync coupling isn't critical for dot
        // animation — 16.67ms is smooth enough.
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.advance() }
        }
    }

    private func stopLoop() {
        frameTimer?.invalidate()
        frameTimer = nil
    }

    private func advance() {
        switch mode {
        case .idle:
            stopLoop(); return
        case .appearing:
            for i in 0..<pixels.count { pixels[i].appear() }
        case .disappearing:
            var allIdle = true
            for i in 0..<pixels.count {
                pixels[i].disappear()
                if !pixels[i].isIdle { allIdle = false }
            }
            if allIdle { mode = .idle; stopLoop() }
        }
        tick &+= 1
    }

    private static func effectiveSpeed(_ v: Int, reducedMotion: Bool) -> CGFloat {
        let throttle: CGFloat = 0.001
        if v <= 0 || reducedMotion { return 0 }
        if v >= 100 { return 100 * throttle }
        return CGFloat(v) * throttle
    }
}


// MARK: - View

struct PixelCardBackground: View {
    var variant: PixelCardVariant = .blue
    var cornerRadius: CGFloat = 14
    var baseFill: Color = Color(red: 0.06, green: 0.07, blue: 0.10)
    /// Whether to honor macOS reduced-motion setting. (Currently always true.)
    var respectsReducedMotion: Bool = true

    @StateObject private var grid = PixelGridModel()
    @State private var isHovering: Bool = false

    var body: some View {
        // NOTE: do NOT wrap the whole body in a GeometryReader. GeometryReader
        // reports its proposed size and also forces maxWidth/maxHeight to
        // infinity on its child, which — when used as `.background(...)` —
        // can push the parent's frame to expand past its intended bounds.
        // Instead, each sized component uses `.containerRelativeFrame` /
        // implicit parent-sizing, and we capture the actual rendered size
        // via `.onGeometryChange` on the top-level ZStack.
        ZStack {
            // 1. Solid base fill
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [baseFill, baseFill.opacity(0.92)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            // 2. Pixel canvas
            Canvas { ctx, _ in
                _ = grid.tick   // observe redraw trigger
                let max = variant.maxSizeInteger
                for pixel in grid.pixels {
                    guard pixel.size > 0 else { continue }
                    let offset = max * 0.5 - pixel.size * 0.5
                    let rect = CGRect(
                        x: pixel.x + offset,
                        y: pixel.y + offset,
                        width: pixel.size,
                        height: pixel.size
                    )
                    ctx.fill(Path(rect), with: .color(pixel.color))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // 3. Radial dark-center overlay (reactbits ::before)
            RadialGradient(
                colors: [variant.radialDarkColor, variant.radialDarkColor.opacity(0)],
                center: .center,
                startRadius: 0,
                endRadius: 220
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(isHovering ? 1 : 0)
            .animation(.easeOut(duration: 0.8), value: isHovering)
            .allowsHitTesting(false)

            // 4. Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    isHovering
                        ? Color(hex: 0x7DD3FC).opacity(0.35)
                        : Color.white.opacity(0.10),
                    lineWidth: isHovering ? 0.9 : 0.6
                )
                .animation(.easeOut(duration: 0.25), value: isHovering)
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            guard newSize.width > 0, newSize.height > 0 else { return }
            let reduced = respectsReducedMotion && NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            grid.rebuild(size: newSize, variant: variant, reducedMotion: reduced)
        }
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                grid.startAppear()
            } else {
                grid.startDisappear()
            }
        }
    }
}
