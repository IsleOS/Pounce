//
//  NotchLiveEditOverlay.swift
//  ClaudeIsland
//
//  SwiftUI content for the NotchLiveEditPanel. Hosts the arrow
//  (◀ ▶) resize controls, the Notch Preset button, the Drag Mode
//  toggle, and the Save / Cancel buttons. The edit sub-mode
//  (.resize / .drag) is transient @State owned by this view and
//  dies with the overlay — Save and Cancel are valid from either
//  sub-mode.
//
//  Spec: docs/superpowers/specs/2026-04-08-notch-customization-design.md
//  section 4.2.
//

import AppKit
import SwiftUI

enum NotchEditSubMode {
    case resize
    case drag
}

struct NotchLiveEditOverlay: View {
    @ObservedObject private var store: NotchCustomizationStore = .shared
    @State private var subMode: NotchEditSubMode = .resize
    @State private var isInteracting: Bool = false
    @State private var presetMarkerVisible: Bool = false
    /// Callback fired when the user commits or cancels the edit
    /// session, so the controller that created the panel can tear
    /// down the window.
    var onExit: () -> Void = {}

    private let neonGreen = Color(hex: "CAFF00")
    private let neonPink  = Color(hex: "FB7185")

    private var hasHardwareNotch: Bool {
        NotchHardwareDetector.hasHardwareNotch(
            on: NSScreen.main,
            mode: store.customization.hardwareNotchMode
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            // Top band: simulated notch preview. The main NotchView
            // is still rendering the live app state — the overlay
            // here sits above it and shows placeholder text so the
            // user can see how resize affects typical content.
            NotchLiveEditSimulatorView(isInteracting: isInteracting)
                .frame(height: 32)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundStyle(neonGreen.opacity(0.8))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.85))
                        )
                )
                .accessibilityHidden(true)

            // Arrow buttons (◀ ▶) for symmetric resize.
            HStack(spacing: 28) {
                arrowButton(direction: -1, label: "Shrink notch")
                arrowButton(direction: +1, label: "Grow notch")
            }

            // Action row: Notch Preset + Drag Mode toggle.
            HStack(spacing: 10) {
                actionButton(
                    title: L10n.notchEditNotchPreset,
                    icon: "scope",
                    enabled: hasHardwareNotch,
                    tooltip: hasHardwareNotch ? nil : L10n.notchEditPresetDisabledTooltip
                ) {
                    applyNotchPreset()
                }
                .accessibilityLabel("Reset to hardware notch width")

                actionButton(
                    title: L10n.notchEditDragMode,
                    icon: "hand.draw",
                    enabled: true,
                    highlight: subMode == .drag
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        subMode = (subMode == .resize) ? .drag : .resize
                    }
                }
                .accessibilityLabel("Toggle drag mode")
                .accessibilityValue(subMode == .drag ? "On" : "Off")
            }

            // Save / Cancel.
            HStack(spacing: 12) {
                Button {
                    store.commitEdit()
                    onExit()
                } label: {
                    Text(L10n.notchEditSave)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(neonGreen))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Save notch customization")

                Button {
                    store.cancelEdit()
                    onExit()
                } label: {
                    Text(L10n.notchEditCancel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(neonPink))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel notch customization")
            }
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Controls

    private func arrowButton(direction: Int, label: String) -> some View {
        Button {
            applyArrowStep(direction: direction)
        } label: {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 36, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(neonGreen))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint("Hold Command for a larger step, hold Option for a finer step.")
    }

    private func applyArrowStep(direction: Int) {
        let flags = NSEvent.modifierFlags
        let step: CGFloat
        if flags.contains(.command) {
            step = 10
        } else if flags.contains(.option) {
            step = 1
        } else {
            step = 2
        }
        store.update { c in
            c.maxWidth = max(
                NotchHardwareDetector.minIdleWidth,
                c.maxWidth + CGFloat(direction) * step
            )
        }
    }

    private func applyNotchPreset() {
        let width = NotchHardwareDetector.hardwareNotchWidth(
            on: NSScreen.main,
            mode: store.customization.hardwareNotchMode
        )
        guard width > 0 else { return }
        store.update { c in
            c.maxWidth = width + 20
        }
        // Flash the dashed marker for ~2s.
        withAnimation(.easeIn(duration: 0.2)) {
            presetMarkerVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                presetMarkerVisible = false
            }
        }
    }

    private func actionButton(
        title: String,
        icon: String,
        enabled: Bool,
        highlight: Bool = false,
        tooltip: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(enabled ? (highlight ? .black : .white) : .white.opacity(0.35))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(highlight ? neonGreen : Color.black.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(neonGreen.opacity(highlight ? 0 : 0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(tooltip ?? "")
    }
}
