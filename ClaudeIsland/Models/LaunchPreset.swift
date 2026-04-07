//
//  LaunchPreset.swift
//  ClaudeIsland
//
//  A launch preset is a named cmux command template that the iPhone can
//  trigger remotely. Each Mac maintains its own set of presets, synced to
//  the server so paired iPhones can browse and pick one.
//

import Foundation

struct LaunchPreset: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var command: String
    var icon: String?       // SF Symbol name
    var sortOrder: Int

    init(id: String = UUID().uuidString,
         name: String,
         command: String,
         icon: String? = nil,
         sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.command = command
        self.icon = icon
        self.sortOrder = sortOrder
    }

    /// Default presets seeded on first launch.
    static let defaults: [LaunchPreset] = [
        LaunchPreset(
            name: "Claude (skip perms)",
            command: "claude --dangerously-skip-permissions",
            icon: "sparkles",
            sortOrder: 0
        ),
        LaunchPreset(
            name: "Claude + Chrome",
            command: "claude --dangerously-skip-permissions --chrome",
            icon: "globe",
            sortOrder: 1
        ),
    ]

    /// Server upload payload (matches PUT /v1/devices/me/presets schema).
    /// The `id` is the Mac's locally-generated UUID — server uses it as the
    /// row's primary key so session-launch events can round-trip back to
    /// PresetStore on this Mac.
    var serverPayload: [String: Any] {
        var p: [String: Any] = [
            "id": id,
            "name": name,
            "command": command,
            "sortOrder": sortOrder,
        ]
        if let icon { p["icon"] = icon }
        return p
    }
}
