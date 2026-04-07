//
//  PresetSettingsView.swift
//  ClaudeIsland
//
//  Manage launch presets — the named cmux command templates that paired
//  iPhones can trigger remotely. Floating window opened from the notch menu.
//

import SwiftUI

// MARK: - Menu Row (inside NotchMenuView)

struct PresetSettingsRow: View {
    @State private var isHovered = false

    var body: some View {
        Button {
            PresetSettingsWindow.shared.show()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(isHovered ? 1 : 0.6))
                    .frame(width: 16)

                Text("Launch Presets")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(isHovered ? 1 : 0.7))

                Spacer()

                Text("\(PresetStore.shared.presets.count)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Floating Window

@MainActor
final class PresetSettingsWindow {
    static let shared = PresetSettingsWindow()

    private var window: NSWindow?

    func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = PresetSettingsContentView { self.close() }
        let hostingView = NSHostingView(rootView: contentView)
        let windowWidth: CGFloat = 460
        let windowHeight: CGFloat = 520
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.backgroundColor = .clear
        w.isOpaque = false
        w.hasShadow = true
        w.isMovableByWindowBackground = true
        w.contentView = hostingView

        if let screen = NSScreen.main {
            let f = screen.frame
            w.setFrameOrigin(NSPoint(x: f.midX - windowWidth / 2, y: f.midY - windowHeight / 2))
        }

        w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        w.makeKeyAndOrderFront(nil)
        w.isReleasedWhenClosed = false
        self.window = w
    }

    func close() {
        window?.close()
        window = nil
    }
}

// MARK: - Content View

private struct PresetSettingsContentView: View {
    let onClose: () -> Void
    @ObservedObject private var store = PresetStore.shared
    @State private var editing: LaunchPreset?
    @State private var showingNew = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Launch Presets")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Button {
                    showingNew = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Text("Paired iPhones can launch these as new cmux sessions")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            Divider().background(Color.white.opacity(0.1))

            // Preset list
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(store.presets) { preset in
                        PresetRow(
                            preset: preset,
                            onEdit: { editing = preset },
                            onDelete: { store.delete(id: preset.id) }
                        )
                    }
                    if store.presets.isEmpty {
                        Text("No presets — tap + to add one")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.top, 40)
                    }
                }
                .padding(12)
            }
        }
        .frame(width: 460, height: 520)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
        )
        .sheet(item: $editing) { preset in
            PresetEditorSheet(preset: preset, isNew: false) { updated in
                store.update(updated)
                editing = nil
            } onCancel: {
                editing = nil
            }
        }
        .sheet(isPresented: $showingNew) {
            PresetEditorSheet(
                preset: LaunchPreset(name: "", command: "", icon: "sparkles"),
                isNew: true
            ) { created in
                store.add(created)
                showingNew = false
            } onCancel: {
                showingNew = false
            }
        }
    }
}

private struct PresetRow: View {
    let preset: LaunchPreset
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: preset.icon ?? "terminal")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Text(preset.command)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.04))
        )
    }
}

private struct PresetEditorSheet: View {
    @State var preset: LaunchPreset
    let isNew: Bool
    let onSave: (LaunchPreset) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isNew ? "New Preset" : "Edit Preset")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Name").font(.system(size: 11)).foregroundColor(.secondary)
                TextField("Claude (skip perms)", text: $preset.name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Command").font(.system(size: 11)).foregroundColor(.secondary)
                TextField("claude --dangerously-skip-permissions", text: $preset.command)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Icon (SF Symbol name)").font(.system(size: 11)).foregroundColor(.secondary)
                TextField("sparkles", text: Binding(
                    get: { preset.icon ?? "" },
                    set: { preset.icon = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                Button(isNew ? "Add" : "Save") {
                    onSave(preset)
                }
                .keyboardShortcut(.return)
                .disabled(preset.name.isEmpty || preset.command.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
