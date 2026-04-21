//
//  HookInstallerTests.swift
//  ClaudeIslandTests
//
//  Reference tests for HookInstaller.pruneLegacyHookEntries.
//
//  Note (2026-04-22): the ClaudeIsland Xcode project does not currently
//  define a dedicated test target — this file is a reference and compiles
//  only when a test target is added. Until then, the runtime-executable
//  equivalent lives at `scripts/test-hook-cleanup.swift` and is the source
//  of truth for "did the JSON mutation pass".
//
//  If you add a test target: the 13 cases below should pass as-is.
//

import XCTest
@testable import ClaudeIsland

final class HookInstallerTests: XCTestCase {

    private let legacy = ["claude-island-state.py"]

    // MARK: - No-op cases

    func test_emptyJSON_returnsUnchanged() {
        let input: [String: Any] = [:]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertFalse(out.changed)
    }

    func test_noHooksField_returnsUnchanged() {
        let input: [String: Any] = ["theme": "dark", "fontScale": "large"]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertFalse(out.changed)
        XCTAssertEqual(out.result["theme"] as? String, "dark")
    }

    func test_emptyHooksDict_returnsUnchanged() {
        let input: [String: Any] = ["hooks": [String: Any]()]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertFalse(out.changed)
    }

    func test_onlyThirdPartyHooks_returnsUnchanged() {
        let input: [String: Any] = [
            "hooks": [
                "Notification": [
                    ["matcher": "*", "hooks": [["type": "command", "command": "python3 /other/plugin-hook.py"]]]
                ]
            ]
        ]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertFalse(out.changed)
    }

    // MARK: - Cleanup cases

    func test_classicDoubleHook_removesLegacyKeepsCurrent() throws {
        let input: [String: Any] = [
            "hooks": [
                "PostToolUse": [
                    ["matcher": "*", "hooks": [["command": "python3 ~/.claude/hooks/claude-island-state.py"]]],
                    ["matcher": "*", "hooks": [["command": "python3 ~/.claude/hooks/codeisland-state.py"]]]
                ]
            ]
        ]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertTrue(out.changed)

        let postTool = try XCTUnwrap((out.result["hooks"] as? [String: Any])?["PostToolUse"] as? [[String: Any]])
        XCTAssertEqual(postTool.count, 1)
        let cmd = (postTool[0]["hooks"] as? [[String: Any]])?[0]["command"] as? String ?? ""
        XCTAssertTrue(cmd.contains("codeisland-state.py"))
        XCTAssertFalse(cmd.contains("claude-island-state.py"))
    }

    func test_eventWithOnlyLegacy_isRemoved() {
        let input: [String: Any] = [
            "hooks": [
                "PostToolUse": [
                    ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]]
                ],
                "PreToolUse": [
                    ["matcher": "*", "hooks": [["command": "codeisland-state.py"]]]
                ]
            ]
        ]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertTrue(out.changed)

        let resultHooks = out.result["hooks"] as? [String: Any] ?? [:]
        XCTAssertNil(resultHooks["PostToolUse"])
        XCTAssertNotNil(resultHooks["PreToolUse"])
    }

    func test_allEventsLegacyOnly_dropsHooksKeyEntirely() {
        let input: [String: Any] = [
            "theme": "dark",
            "hooks": [
                "PostToolUse": [
                    ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]]
                ],
                "PreToolUse": [
                    ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]]
                ]
            ]
        ]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertTrue(out.changed)
        XCTAssertNil(out.result["hooks"])
        XCTAssertEqual(out.result["theme"] as? String, "dark")
    }

    func test_multipleLegacyScripts_allRemoved() throws {
        let input: [String: Any] = [
            "hooks": [
                "PostToolUse": [
                    ["matcher": "*", "hooks": [["command": "old-a.py"]]],
                    ["matcher": "*", "hooks": [["command": "old-b.py"]]],
                    ["matcher": "*", "hooks": [["command": "codeisland-state.py"]]]
                ]
            ]
        ]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: ["old-a.py", "old-b.py"])
        XCTAssertTrue(out.changed)

        let postTool = try XCTUnwrap((out.result["hooks"] as? [String: Any])?["PostToolUse"] as? [[String: Any]])
        XCTAssertEqual(postTool.count, 1)
    }

    // MARK: - Safety

    func test_idempotent_secondPassIsNoOp() {
        let dirty: [String: Any] = [
            "hooks": [
                "PostToolUse": [
                    ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]],
                    ["matcher": "*", "hooks": [["command": "codeisland-state.py"]]]
                ]
            ]
        ]
        let first = HookInstaller.pruneLegacyHookEntries(from: dirty, legacyScripts: legacy)
        XCTAssertTrue(first.changed)
        let second = HookInstaller.pruneLegacyHookEntries(from: first.result, legacyScripts: legacy)
        XCTAssertFalse(second.changed)
    }

    func test_garbageShapedValue_preservedAsIs() throws {
        let input: [String: Any] = [
            "hooks": [
                "PostToolUse": "not-a-list-or-dict",  // malformed entry
                "PreToolUse": [
                    ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]]
                ]
            ]
        ]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertTrue(out.changed)

        let resultHooks = out.result["hooks"] as? [String: Any] ?? [:]
        XCTAssertEqual(resultHooks["PostToolUse"] as? String, "not-a-list-or-dict")
        XCTAssertNil(resultHooks["PreToolUse"])
    }

    func test_entryWithoutCommandField_notTouched() throws {
        let input: [String: Any] = [
            "hooks": [
                "PostToolUse": [
                    ["matcher": "*", "hooks": [["type": "command"]]],  // no command key
                    ["matcher": "*", "hooks": [["command": "claude-island-state.py"]]]
                ]
            ]
        ]
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertTrue(out.changed)

        let postTool = try XCTUnwrap((out.result["hooks"] as? [String: Any])?["PostToolUse"] as? [[String: Any]])
        XCTAssertEqual(postTool.count, 1)
        let surv = postTool[0]["hooks"] as? [[String: Any]]
        XCTAssertNil(surv?[0]["command"])
    }

    func test_otherTopLevelFieldsPreserved() {
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
        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertTrue(out.changed)
        XCTAssertEqual((out.result["env"] as? [String: String])?["HTTP_PROXY"], "http://127.0.0.1:7890")
        XCTAssertEqual((out.result["enabledPlugins"] as? [String: Bool])?["foo@bar"], true)
        XCTAssertEqual((out.result["statusLine"] as? [String: String])?["type"], "command")
    }

    func test_realWorldSnapshot_11LegacyRefsAcross10Events_allCleaned() {
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
            ["matcher": "auto",   "hooks": [["command": "claude-island-state.py"]]],
            ["matcher": "manual", "hooks": [["command": "claude-island-state.py"]]],
            ["matcher": "auto",   "hooks": [["command": "codeisland-state.py"]]],
            ["matcher": "manual", "hooks": [["command": "codeisland-state.py"]]]
        ]
        let input: [String: Any] = ["hooks": hooks]

        let out = HookInstaller.pruneLegacyHookEntries(from: input, legacyScripts: legacy)
        XCTAssertTrue(out.changed)

        let resultHooks = out.result["hooks"] as? [String: Any] ?? [:]
        var legacyCount = 0
        for (_, value) in resultHooks {
            for entry in value as? [[String: Any]] ?? [] {
                for h in entry["hooks"] as? [[String: Any]] ?? [] {
                    if let c = h["command"] as? String, c.contains("claude-island-state.py") {
                        legacyCount += 1
                    }
                }
            }
        }
        XCTAssertEqual(legacyCount, 0)
        XCTAssertEqual(resultHooks.count, events.count + 1)  // 9 regular + PreCompact
    }
}
