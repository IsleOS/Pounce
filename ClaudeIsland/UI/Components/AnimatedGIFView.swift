//
//  AnimatedGIFView.swift
//  ClaudeIsland
//
//  SwiftUI renderer for plugin-provided sidebar illustrations. Wraps an
//  NSImageView (AppKit handles animated GIF playback out of the box) and
//  cycles through the palette's pre-loaded GIF data at `cycleDuration`.
//
//  Pattern ported from feature/theme-plugin branch: GIF bytes are loaded
//  eagerly into the palette on theme activation, so the view just reads
//  already-populated Data — no view-side async load race.
//

import AppKit
import Combine
import SwiftUI

/// NSImageView-backed renderer that plays animated GIFs natively.
struct AnimatedGIFView: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.masksToBounds = true

        let imageView = NSImageView()
        imageView.animates = true
        imageView.imageScaling = .scaleProportionallyDown
        imageView.imageAlignment = .alignCenter
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let imageView = nsView.subviews.first as? NSImageView else { return }
        imageView.image = NSImage(data: data)
    }
}

/// Cycles through pre-loaded illustration data. Renders nothing when
/// illustrations is nil or its data array is empty.
struct GIFCyclerView: View {
    let illustrations: SettingsThemeIllustrations?

    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack {
            if let illustrations, !illustrations.data.isEmpty {
                let safeIndex = currentIndex % illustrations.data.count
                AnimatedGIFView(data: illustrations.data[safeIndex])
                    .id(currentIndex)
                    .transition(transition(for: illustrations.transition))
            }
        }
        .animation(cycleAnimation, value: currentIndex)
        .onReceive(timer) { _ in
            guard let count = illustrations?.data.count, count > 1 else { return }
            currentIndex = (currentIndex + 1) % count
        }
        .onChange(of: illustrations?.data.count ?? 0) { _, count in
            currentIndex = count == 0 ? 0 : min(currentIndex, count - 1)
        }
    }

    private var cycleAnimation: Animation? {
        guard let t = illustrations?.transition, t != .none else { return nil }
        return .easeInOut(duration: 0.6)
    }

    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(
            every: illustrations?.cycleDuration ?? 3600,
            on: .main,
            in: .common
        ).autoconnect()
    }

    private func transition(
        for value: SettingsThemeIllustrations.Transition
    ) -> AnyTransition {
        switch value {
        case .crossfade:
            return .opacity
        case .slide:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .none:
            return .identity
        }
    }
}
