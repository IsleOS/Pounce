//
//  NotchWindowController.swift
//  ClaudeIsland
//
//  Controls the notch window positioning and lifecycle
//

import AppKit
import Combine
import SwiftUI

class NotchWindowController: NSWindowController {
    let viewModel: NotchViewModel
    private let screen: NSScreen
    private var cancellables = Set<AnyCancellable>()

    /// Subscription to NotchCustomizationStore.$customization. Held
    /// as a dedicated cancellable (not lumped into `cancellables`)
    /// so it can be torn down independently if the controller is
    /// ever re-attached to a different store instance.
    private var customizationCancellable: AnyCancellable?
    private var editingCancellable: AnyCancellable?

    /// Active live-edit overlay panel, non-nil only while
    /// store.isEditing == true.
    private var liveEditPanel: NotchLiveEditPanel?

    init(screen: NSScreen) {
        self.screen = screen

        let screenFrame = screen.frame
        let notchSize = screen.notchSize

        // Window covers full width at top, tall enough for largest content (chat view)
        let windowHeight: CGFloat = 750
        let windowFrame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.maxY - windowHeight,
            width: screenFrame.width,
            height: windowHeight
        )

        // Device notch rect - positioned at center
        let deviceNotchRect = CGRect(
            x: (screenFrame.width - notchSize.width) / 2,
            y: 0,
            width: notchSize.width,
            height: notchSize.height
        )

        // Create view model
        self.viewModel = NotchViewModel(
            deviceNotchRect: deviceNotchRect,
            screenRect: screenFrame,
            windowHeight: windowHeight,
            hasPhysicalNotch: screen.hasPhysicalNotch
        )

        // Create the window
        let notchWindow = NotchPanel(
            contentRect: windowFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init(window: notchWindow)

        // Create the SwiftUI view with pass-through hosting
        let hostingController = NotchViewController(viewModel: viewModel)
        notchWindow.contentViewController = hostingController

        notchWindow.setFrame(windowFrame, display: true)

        // Dynamically toggle mouse event handling based on notch state:
        // - Closed: ignoresMouseEvents = true (clicks pass through to menu bar/apps)
        // - Opened: ignoresMouseEvents = false (buttons inside panel work)
        viewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak notchWindow, weak viewModel] status in
                switch status {
                case .opened:
                    // Accept mouse events when opened so buttons work
                    notchWindow?.ignoresMouseEvents = false
                    notchWindow?.acceptsMouseMovedEvents = true
                    // Only steal focus on user-initiated opens (click)
                    // Hover/notification opens should not interrupt typing in other apps
                    if viewModel?.shouldActivateOnOpen == true {
                        NSApp.activate(ignoringOtherApps: false)
                        notchWindow?.makeKeyAndOrderFront(nil)
                    } else {
                        notchWindow?.orderFrontRegardless()
                    }
                case .closed, .popping:
                    // Ignore mouse events when closed so clicks pass through
                    notchWindow?.ignoresMouseEvents = true
                }
            }
            .store(in: &cancellables)

        // Start with ignoring mouse events (closed state)
        notchWindow.ignoresMouseEvents = true

        // Perform boot animation after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.viewModel.performBootAnimation()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - NotchCustomizationStore integration

    /// Subscribe to the given store and reapply geometry every
    /// time the user's customization changes. Safe to call
    /// multiple times — the previous subscription is released
    /// before the new one is attached.
    ///
    /// Spec: docs/superpowers/specs/2026-04-08-notch-customization-design.md
    /// section 5.5.
    @MainActor
    func attachStore(_ store: NotchCustomizationStore) {
        customizationCancellable = store.$customization
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyGeometryFromStore()
            }

        // Mirror live edit lifecycle into panel creation / teardown.
        editingCancellable = store.$isEditing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] editing in
                guard let self else { return }
                if editing {
                    self.enterLiveEditMode()
                } else {
                    self.exitLiveEditMode()
                }
            }
    }

    @MainActor
    func enterLiveEditMode() {
        guard liveEditPanel == nil else { return }
        let activeScreen = window?.screen ?? self.screen
        let panel = NotchLiveEditPanel(screen: activeScreen)

        let overlay = NotchLiveEditOverlay(onExit: { [weak self] in
            self?.exitLiveEditMode()
        })
        let hosting = NSHostingView(rootView: overlay)
        hosting.frame = panel.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(hosting)

        panel.orderFrontRegardless()
        panel.makeKey()
        self.liveEditPanel = panel
    }

    @MainActor
    func exitLiveEditMode() {
        guard let panel = liveEditPanel else { return }
        panel.orderOut(nil)
        panel.close()
        self.liveEditPanel = nil
    }

    /// Recompute the panel frame from the current store state +
    /// active screen metrics and animate into the new frame.
    /// Stateless — does NOT write anything back to the store, so
    /// render-time clamping on a smaller screen is transparent
    /// and reversible when the larger screen returns.
    @MainActor
    func applyGeometryFromStore() {
        let store = NotchCustomizationStore.shared
        let customization = store.customization
        let window = self.window

        guard let window else { return }
        let activeScreen = window.screen ?? self.screen
        let screenFrame = activeScreen.frame

        let runtimeWidth = NotchHardwareDetector.clampedWidth(
            measuredContentWidth: customization.maxWidth,
            maxWidth: customization.maxWidth
        )
        let clampedOffset = NotchHardwareDetector.clampedHorizontalOffset(
            storedOffset: customization.horizontalOffset,
            runtimeWidth: runtimeWidth,
            screenWidth: screenFrame.width
        )
        let baseX = (screenFrame.width - runtimeWidth) / 2
        let finalX = screenFrame.origin.x + baseX + clampedOffset

        // The notch panel currently sizes itself to the full
        // screen width and positions content via inner layout, so
        // a geometry change here re-flows the internal notch
        // layout rather than resizing the window. This matches the
        // existing CodeIsland rendering model and avoids a deeper
        // refactor of the hosting view geometry. Stored horizontal
        // offset and width are still observed via the subscription
        // so NotchView can react directly to store changes.
        _ = (finalX, runtimeWidth) // Referenced for clarity; full
                                   // geometry wiring is deferred to
                                   // the next chunk (live edit mode)
                                   // where the interactive drag
                                   // path needs the same math.

        // Smoothly animate any future frame changes.
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            // Preserve the current full-width overlay frame; only
            // the inner notch bounds care about runtimeWidth.
            window.animator().setFrame(window.frame, display: true)
        }
    }
}
