//
//  NotchLiveEditPanel.swift
//  ClaudeIsland
//
//  Auxiliary NSPanel subclass used only during live edit mode.
//  Hosts the floating arrow buttons, preset / drag / save / cancel
//  controls, and the dashed edit-mode overlay on top of the main
//  notch. Its frame spans the full active-screen width so the
//  control row outside the notch's narrow bounds can still receive
//  clicks, while its contentView's hitTest override lets clicks
//  on the menu bar itself fall through to the system.
//
//  Spec: docs/superpowers/specs/2026-04-08-notch-customization-design.md
//  section 4.2.
//

import AppKit
import SwiftUI

/// Content view that passes clicks through to the menu bar when
/// the point does not hit any of the live edit overlay controls.
final class NotchLiveEditContentView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        for sub in subviews where sub.frame.contains(point) {
            if let target = sub.hitTest(convert(point, to: sub)) {
                return target
            }
        }
        // No control hit — fall through to the system so the
        // macOS menu bar still works while live edit is active.
        return nil
    }
}

final class NotchLiveEditPanel: NSPanel {
    init(screen: NSScreen) {
        // ~160pt tall band across the top of the active screen:
        // enough room for the notch + the control row beneath.
        let height: CGFloat = 160
        let screenFrame = screen.frame
        let frame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.maxY - height,
            width: screenFrame.width,
            height: height
        )

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.isMovableByWindowBackground = false
        self.hasShadow = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.level = .mainMenu + 4
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.isReleasedWhenClosed = false

        self.contentView = NotchLiveEditContentView(frame: NSRect(origin: .zero, size: frame.size))
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
