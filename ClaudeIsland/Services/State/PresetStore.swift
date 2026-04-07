//
//  PresetStore.swift
//  ClaudeIsland
//
//  Local storage + server sync for launch presets. Persists to UserDefaults
//  and pushes the full list to the server on every mutation.
//

import Combine
import Foundation
import os.log
import SwiftUI  // for IndexSet.move(fromOffsets:toOffset:)

@MainActor
final class PresetStore: ObservableObject {
    static let shared = PresetStore()
    static let logger = Logger(subsystem: "com.codeisland", category: "PresetStore")

    private let storageKey = "launchPresets.v1"
    private let seededFlagKey = "launchPresets.seeded.v1"

    @Published private(set) var presets: [LaunchPreset] = []

    private init() {
        load()
        if !UserDefaults.standard.bool(forKey: seededFlagKey) {
            // First launch on this machine — seed the defaults.
            presets = LaunchPreset.defaults
            persist()
            UserDefaults.standard.set(true, forKey: seededFlagKey)
            Self.logger.info("Seeded \(LaunchPreset.defaults.count) default presets")
            // Push to server in the background once SyncManager is up.
            Task { await SyncManager.shared.uploadPresets() }
        }
    }

    // MARK: - CRUD

    func add(_ preset: LaunchPreset) {
        var copy = preset
        copy.sortOrder = (presets.map(\.sortOrder).max() ?? -1) + 1
        presets.append(copy)
        persist()
        Task { await SyncManager.shared.uploadPresets() }
    }

    func update(_ preset: LaunchPreset) {
        guard let idx = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[idx] = preset
        persist()
        Task { await SyncManager.shared.uploadPresets() }
    }

    func delete(id: String) {
        presets.removeAll { $0.id == id }
        persist()
        Task { await SyncManager.shared.uploadPresets() }
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        presets.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, _) in presets.enumerated() {
            presets[i].sortOrder = i
        }
        persist()
        Task { await SyncManager.shared.uploadPresets() }
    }

    func preset(id: String) -> LaunchPreset? {
        presets.first { $0.id == id }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([LaunchPreset].self, from: data) else {
            return
        }
        presets = decoded.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
