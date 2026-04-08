//
//  NotchLiveEditSimulator.swift
//  ClaudeIsland
//
//  Rotating fake Claude messages used to preview notch sizing
//  behavior during live edit mode. Driven by TimelineView with a
//  2-second period and paused for 0.8s after any active gesture.
//
//  Spec: docs/superpowers/specs/2026-04-08-notch-customization-design.md
//  section 4.2 "Simulated content rotation".
//

import SwiftUI

enum NotchLiveEditSimulator {
    static let fixtures: [String] = [
        "",
        "Ready",
        "Reading package.json…",
        "Refactoring auth middleware and tests",
        "Analyzing 147-line diff to determine whether the new header comment is safe"
    ]
}

struct NotchLiveEditSimulatorView: View {
    @State private var index: Int = 0
    @State private var lastGestureEnd: Date = .distantPast
    /// External flag set by whatever overlay hosts the active
    /// gesture so we pause advancing while the user is dragging.
    var isInteracting: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 2)) { context in
            let text = NotchLiveEditSimulator.fixtures[index]
            Text(text.isEmpty ? " " : text)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .onChange(of: context.date) { _, newDate in
                    // 0.8s debounce after last gesture end.
                    guard !isInteracting else { return }
                    guard newDate.timeIntervalSince(lastGestureEnd) > 0.8 else { return }
                    index = (index + 1) % NotchLiveEditSimulator.fixtures.count
                }
                .onChange(of: isInteracting) { _, interacting in
                    if !interacting { lastGestureEnd = Date() }
                }
        }
    }
}
