//
//  SoundSettingsView.swift
//  ClaudeIsland
//
//  Settings view for the 8-bit sound system.
//  Provides global mute, volume, and per-event toggles with preview buttons.
//

import SwiftUI

struct SoundSettingsView: View {
    @ObservedObject private var soundManager = SoundManager.shared
    @EnvironmentObject private var themeStore: SettingsThemeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Header

            Text(L10n.soundSettings)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeStore.palette.detailText)

            // MARK: - Global Mute

            Toggle(isOn: $soundManager.globalMute) {
                Label(L10n.globalMute, systemImage: soundManager.globalMute ? "speaker.slash.fill" : "speaker.fill")
                    .font(.system(size: 12))
                    .foregroundColor(themeStore.palette.detailText)
            }
            .toggleStyle(.switch)
            .tint(themeStore.palette.accent)

            // MARK: - Volume Slider

            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10))
                    .foregroundColor(themeStore.palette.detailText.opacity(0.6))

                Slider(value: $soundManager.volume, in: 0.0...1.0)
                    .controlSize(.small)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10))
                    .foregroundColor(themeStore.palette.detailText.opacity(0.6))
            }
            .disabled(soundManager.globalMute)
            .opacity(soundManager.globalMute ? 0.4 : 1.0)

            Divider()
                .background(themeStore.palette.secondaryButtonBorder)

            // MARK: - Per-Event Toggles

            Text(L10n.eventSounds)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeStore.palette.detailText.opacity(0.6))

            VStack(spacing: 6) {
                ForEach(SoundEvent.allCases, id: \.rawValue) { event in
                    SoundEventRow(event: event, soundManager: soundManager)
                }
            }
            .disabled(soundManager.globalMute)
            .opacity(soundManager.globalMute ? 0.4 : 1.0)
        }
        .padding(12)
    }
}

// MARK: - Sound Event Row

/// A single row showing an event toggle and a preview button.
private struct SoundEventRow: View {
    let event: SoundEvent
    @ObservedObject var soundManager: SoundManager
    @EnvironmentObject private var themeStore: SettingsThemeStore

    @State private var isEnabled: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            Toggle(isOn: $isEnabled) {
                Text(event.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(themeStore.palette.detailText)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .tint(themeStore.palette.accent)
            .onChange(of: isEnabled) { _, newValue in
                soundManager.setEnabled(newValue, for: event)
            }

            Spacer()

            // Preview / test button
            Button {
                soundManager.play(event)
            } label: {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 11))
                    .foregroundColor(themeStore.palette.detailText.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help(L10n.previewSound(event.displayName))
        }
        .onAppear {
            isEnabled = soundManager.isEnabled(event)
        }
    }
}

// MARK: - Preview

#Preview {
    SoundSettingsView()
        .frame(width: 280)
        .background(SettingsThemePalette.default.detailFill)
        .environmentObject(SettingsThemeStore.shared)
}
