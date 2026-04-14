//
//  SettingsThemeStore.swift
//  ClaudeIsland
//
//  Observable store for the active settings theme palette. Views access
//  this via @EnvironmentObject. When a theme plugin activates, the
//  plugin manager calls `activate(id:config:bundleResourcesURL:)` to
//  atomically swap the palette and persist the active id. `reset()`
//  reverts to the built-in default and clears persistence.
//
//  Spec: docs/superpowers/specs/2026-04-13-tempo-theme-rendering-design.md
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class SettingsThemeStore: ObservableObject {
    static let shared = SettingsThemeStore()

    @Published private(set) var palette: SettingsThemePalette = .default
    @Published private(set) var activeThemeId: String?

    private static let activeThemeIdKey = "SettingsTheme.activeThemeId"

    private init() {
        // Seed the persisted id so NativePluginManager can match against it
        // during bundle discovery at launch. The palette itself remains at
        // `.default` until the owning plugin actually loads and re-activates.
        self.activeThemeId = UserDefaults.standard.string(
            forKey: Self.activeThemeIdKey
        )
    }

    /// Activate a theme plugin's settings palette.
    /// - Parameters:
    ///   - id: The plugin id (used for the picker checkmark + persistence).
    ///   - config: The decoded `settings` block from the plugin's JSON.
    ///   - bundleResourcesURL: The plugin bundle's `Contents/Resources/`
    ///     directory. Passed through to the palette factory so relative
    ///     asset paths in the config resolve correctly.
    func activate(
        id: String,
        config: SettingsThemeConfig,
        bundleResourcesURL: URL
    ) {
        palette = .from(config: config, bundleResourcesURL: bundleResourcesURL)
        activeThemeId = id
        UserDefaults.standard.set(id, forKey: Self.activeThemeIdKey)
    }

    /// Revert to the built-in default palette and clear persistence.
    func reset() {
        palette = .default
        activeThemeId = nil
        UserDefaults.standard.removeObject(forKey: Self.activeThemeIdKey)
    }
}
