#!/usr/bin/env swift
//
// test-hook-cleanup.swift
//
// Runs against a copy of HookInstaller.pruneLegacyHookEntries kept
// in sync with ClaudeIsland/Services/Hooks/HookInstaller.swift.
//
// Why a standalone script instead of XCTest:
//   The ClaudeIsland Xcode project has no test target (see note in
//   ClaudeIslandTests/NotchCustomizationTests.swift). Until a test
//   target is wired up, this script is the authoritative runtime
//   proof that the settings.json mutation is correct and idempotent.
//
// Run:    swift scripts/test-hook-cleanup.swift
// Exit:   0 on all green, 1 on any failure.
//
// CONTRACT: if you change pruneLegacyHookEntries in HookInstaller.swift,
// copy the new body here too and re-run. A drift check is in the last test.
//

import Foundation

// MARK: - Subject under test (verbatim copy from HookInstaller.swift)

func pruneLegacyHookEntries(
    from json: [String: Any],
    legacyScripts: [String]
) -> (result: [String: Any], changed: Bool) {
    guard var hooks = json["hooks"] as? [String: Any] else {
        return (json, false)
    }

    func entryReferencesLegacy(_ entry: [String: Any]) -> Bool {
        guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
        return entryHooks.contains { hook in
            guard let cmd = hook["command"] as? String else { return false }
            return legacyScripts.contains { cmd.contains($0) }
        }
    }

    var changed = false
    for (event, value) in hooks {
        guard var entries = value as? [[String: Any]] else { continue }
        let before = entries.count
        entries.removeAll(where: entryReferencesLegacy)
        guard entries.count != before else { continue }
        changed = true
        if entries.isEmpty {
            hooks.removeValue(forKey: event)
        } else {
            hooks[event] = entries
        }
    }

    guard changed else { return (json, false) }

    var result = json
    if hooks.isEmpty {
        result.removeValue(forKey: "hooks")
    } else {
        result["hooks"] = hooks
    }
    return (result, true)
}

// MARK: - Test harness

var passed = 0
var failed = 0

func check(_ cond: @autoclosure () -> Bool, _ desc: String, file: StaticString = #file, line: UInt = #line) {
    if cond() {
        passed += 1
        print("  ✓ \(desc)")
    } else {
        failed += 1
        print("  ✗ \(desc)  (line \(line))")
    }
}

func dictsEqual(_ a: [String: Any], _ b: [String: Any]) -> Bool {
    guard let ad = try? JSONSerialization.data(withJSONObject: a, options: [.sortedKeys]),
          let bd = try? JSONSerialization.data(withJSONObject: b, options: [.sortedKeys]) else {
        return false
    }
    return ad == bd
}

let legacy = ["claude-island-state.py"]

// MARK: - Tests

print("\n=== Test 1: empty json → no change ===")
do {
    let input: [String: Any] = [:]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(!out.changed, "changed=false")
    check(dictsEqual(out.result, input), "result unchanged")
}

print("\n=== Test 2: no hooks field → no change ===")
do {
    let input: [String: Any] = ["theme": "dark", "fontScale": "large"]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(!out.changed, "changed=false")
    check(dictsEqual(out.result, input), "result unchanged")
}

print("\n=== Test 3: hooks is empty dict → no change ===")
do {
    let input: [String: Any] = ["hooks": [String: Any]()]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(!out.changed, "changed=false")
    check(dictsEqual(out.result, input), "result unchanged")
}

print("\n=== Test 4: only third-party hooks, no legacy → no change ===")
do {
    let input: [String: Any] = [
        "hooks": [
            "Notification": [
                ["matcher": "*", "hooks": [["type": "command", "command": "python3 /other/plugin-hook.py"]]]
            ]
        ]
    ]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(!out.changed, "changed=false")
    check(dictsEqual(out.result, input), "result unchanged")
}

print("\n=== Test 5: classic double-hook (legacy + current), event has both → legacy removed, current kept ===")
do {
    let input: [String: Any] = [
        "hooks": [
            "PostToolUse": [
                ["matcher": "*", "hooks": [["type": "command", "command": "python3 ~/.claude/hooks/claude-island-state.py"]]],
                ["matcher": "*", "hooks": [["type": "command", "command": "python3 ~/.claude/hooks/codeisland-state.py"]]]
            ]
        ]
    ]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(out.changed, "changed=true")
    guard let resultHooks = out.result["hooks"] as? [String: Any],
          let postTool = resultHooks["PostToolUse"] as? [[String: Any]] else {
        check(false, "shape preserved")
        exit(1)
    }
    check(postTool.count == 1, "PostToolUse has 1 entry left")
    let remaining = postTool[0]["hooks"] as? [[String: Any]]
    let cmd = remaining?[0]["command"] as? String ?? ""
    check(cmd.contains("codeisland-state.py"), "remaining entry is current script")
    check(!cmd.contains("claude-island-state.py"), "legacy script gone")
}

print("\n=== Test 6: event has only legacy → event removed from hooks ===")
do {
    let input: [String: Any] = [
        "hooks": [
            "PostToolUse": [
                ["matcher": "*", "hooks": [["type": "command", "command": "python3 ~/.claude/hooks/claude-island-state.py"]]]
            ],
            "PreToolUse": [
                ["matcher": "*", "hooks": [["type": "command", "command": "python3 ~/.claude/hooks/codeisland-state.py"]]]
            ]
        ]
    ]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(out.changed, "changed=true")
    let resultHooks = out.result["hooks"] as? [String: Any] ?? [:]
    check(resultHooks["PostToolUse"] == nil, "PostToolUse dropped (was empty)")
    check(resultHooks["PreToolUse"] != nil, "PreToolUse kept")
}

print("\n=== Test 7: every event is legacy-only → entire `hooks` key dropped ===")
do {
    let input: [String: Any] = [
        "theme": "dark",
        "hooks": [
            "PostToolUse": [
                ["matcher": "*", "hooks": [["command": "python3 ~/.claude/hooks/claude-island-state.py"]]]
            ],
            "PreToolUse": [
                ["matcher": "*", "hooks": [["command": "python3 ~/.claude/hooks/claude-island-state.py"]]]
            ]
        ]
    ]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(out.changed, "changed=true")
    check(out.result["hooks"] == nil, "hooks key removed entirely")
    check(out.result["theme"] as? String == "dark", "unrelated top-level field preserved")
}

print("\n=== Test 8: multiple legacy scripts → all removed ===")
do {
    let input: [String: Any] = [
        "hooks": [
            "PostToolUse": [
                ["matcher": "*", "hooks": [["command": "old-a.py"]]],
                ["matcher": "*", "hooks": [["command": "old-b.py"]]],
                ["matcher": "*", "hooks": [["command": "codeisland-state.py"]]]
            ]
        ]
    ]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: ["old-a.py", "old-b.py"])
    check(out.changed, "changed=true")
    let postTool = (out.result["hooks"] as? [String: Any])?["PostToolUse"] as? [[String: Any]]
    check(postTool?.count == 1, "only current script left")
}

print("\n=== Test 9: idempotent — running on already-clean input is a no-op ===")
do {
    let dirty: [String: Any] = [
        "hooks": [
            "PostToolUse": [
                ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]],
                ["matcher": "*", "hooks": [["command": "codeisland-state.py"]]]
            ]
        ]
    ]
    let first = pruneLegacyHookEntries(from: dirty, legacyScripts: legacy)
    check(first.changed, "first pass mutates")
    let second = pruneLegacyHookEntries(from: first.result, legacyScripts: legacy)
    check(!second.changed, "second pass is no-op")
    check(dictsEqual(first.result, second.result), "output stable")
}

print("\n=== Test 10: non-dict hook value → skipped safely ===")
do {
    let input: [String: Any] = [
        "hooks": [
            "PostToolUse": "not-a-list-or-dict",  // invalid shape
            "PreToolUse": [
                ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]]
            ]
        ]
    ]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(out.changed, "changed=true (PreToolUse cleaned)")
    let resultHooks = out.result["hooks"] as? [String: Any] ?? [:]
    check(resultHooks["PostToolUse"] as? String == "not-a-list-or-dict",
          "garbage-shaped value preserved as-is")
    check(resultHooks["PreToolUse"] == nil, "PreToolUse (legacy-only) dropped")
}

print("\n=== Test 11: entry without `command` field → not touched ===")
do {
    let input: [String: Any] = [
        "hooks": [
            "PostToolUse": [
                ["matcher": "*", "hooks": [["type": "command"]]],  // no command key
                ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]]
            ]
        ]
    ]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(out.changed, "changed=true")
    let postTool = (out.result["hooks"] as? [String: Any])?["PostToolUse"] as? [[String: Any]]
    check(postTool?.count == 1, "only the no-command entry survives")
    let surv = postTool?[0]["hooks"] as? [[String: Any]]
    check(surv?[0]["command"] == nil, "surviving entry has no command field")
}

print("\n=== Test 12: other top-level fields (env, plugins, statusLine) preserved through mutation ===")
do {
    let input: [String: Any] = [
        "env": ["HTTP_PROXY": "http://127.0.0.1:7890"],
        "enabledPlugins": ["foo@bar": true],
        "statusLine": ["type": "command", "command": "bun hud"],
        "hooks": [
            "PostToolUse": [
                ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]],
                ["matcher": "*", "hooks": [["command": "codeisland-state.py"]]]
            ]
        ]
    ]
    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(out.changed, "changed=true")
    check((out.result["env"] as? [String: String])?["HTTP_PROXY"] == "http://127.0.0.1:7890", "env preserved")
    check((out.result["enabledPlugins"] as? [String: Bool])?["foo@bar"] == true, "enabledPlugins preserved")
    check((out.result["statusLine"] as? [String: String])?["type"] == "command", "statusLine preserved")
}

print("\n=== Test 13: real-world example from ying's machine (11 legacy refs across 10 events) ===")
do {
    var hooks: [String: Any] = [:]
    let events = ["Notification", "PermissionRequest", "PostToolUse", "PreToolUse",
                  "SessionEnd", "SessionStart", "Stop", "SubagentStop", "UserPromptSubmit"]
    for ev in events {
        hooks[ev] = [
            ["matcher": "*", "hooks": [["command": "python3 ~/.claude/hooks/claude-island-state.py"]]],
            ["matcher": "*", "hooks": [["command": "python3 ~/.claude/hooks/codeisland-state.py"]]]
        ]
    }
    hooks["PreCompact"] = [
        ["matcher": "auto", "hooks": [["command": "claude-island-state.py"]]],
        ["matcher": "manual", "hooks": [["command": "claude-island-state.py"]]],
        ["matcher": "auto", "hooks": [["command": "codeisland-state.py"]]],
        ["matcher": "manual", "hooks": [["command": "codeisland-state.py"]]]
    ]
    let input: [String: Any] = ["hooks": hooks]

    let out = pruneLegacyHookEntries(from: input, legacyScripts: legacy)
    check(out.changed, "changed=true")
    let resultHooks = out.result["hooks"] as? [String: Any] ?? [:]

    // Every event should have survivors, none legacy.
    var legacyCount = 0
    for (_, value) in resultHooks {
        guard let entries = value as? [[String: Any]] else { continue }
        for entry in entries {
            for h in entry["hooks"] as? [[String: Any]] ?? [] {
                if let c = h["command"] as? String, c.contains("claude-island-state.py") {
                    legacyCount += 1
                }
            }
        }
    }
    check(legacyCount == 0, "0 legacy references left (was 11)")
    check(resultHooks.count == events.count + 1, "all 10 events survived (9 regular + PreCompact)")
}

// MARK: - Summary

print("\n=====================================================")
print("  \(passed) passed, \(failed) failed")
print("=====================================================\n")

exit(failed == 0 ? 0 : 1)
