//
//  ZombieScanTests.swift
//  ClaudeIslandTests
//
//  Tests for zombie session detection via process liveness checking.
//

import XCTest
@testable import ClaudeIsland

// MARK: - Mock Liveness Checker

struct MockLivenessChecker: ProcessLivenessChecker {
    let aliveSet: Set<Int>

    nonisolated func isAlive(pid: Int) -> Bool {
        aliveSet.contains(pid)
    }
}

// MARK: - Tests

final class ZombieScanTests: XCTestCase {

    /// Dead process should be marked as ended
    func test_deadProcess_markedEnded() async {
        let checker = MockLivenessChecker(aliveSet: [])
        let store = SessionStore(livenessChecker: checker)

        // Create a session with a "dead" PID
        let event = makeHookEvent(sessionId: "test-1", cwd: "/tmp", pid: 99999, status: nil)
        await store.process(.hookReceived(event))

        // Verify session exists and is not ended
        let before = await store.session(for: "test-1")
        XCTAssertNotNil(before)
        XCTAssertNotEqual(before?.phase, .ended)

        // Run zombie scan
        await store.scanForZombies()

        // Session should now be ended
        let after = await store.session(for: "test-1")
        XCTAssertEqual(after?.phase, .ended)
    }

    /// Live process should not be affected
    func test_liveProcess_notAffected() async {
        let checker = MockLivenessChecker(aliveSet: [42])
        let store = SessionStore(livenessChecker: checker)

        let event = makeHookEvent(sessionId: "test-2", cwd: "/tmp", pid: 42, status: nil)
        await store.process(.hookReceived(event))

        await store.scanForZombies()

        let session = await store.session(for: "test-2")
        XCTAssertNotNil(session)
        XCTAssertNotEqual(session?.phase, .ended)
    }

    /// Session with no PID should be ignored by zombie scan
    func test_noPid_ignored() async {
        let checker = MockLivenessChecker(aliveSet: [])
        let store = SessionStore(livenessChecker: checker)

        let event = makeHookEvent(sessionId: "test-3", cwd: "/tmp", pid: nil, status: nil)
        await store.process(.hookReceived(event))

        await store.scanForZombies()

        let session = await store.session(for: "test-3")
        XCTAssertNotNil(session)
        XCTAssertNotEqual(session?.phase, .ended)
    }

    /// Already ended session should not be reprocessed
    func test_alreadyEnded_skipped() async {
        let checker = MockLivenessChecker(aliveSet: [])
        let store = SessionStore(livenessChecker: checker)

        let event = makeHookEvent(sessionId: "test-4", cwd: "/tmp", pid: 100, status: "ended")
        await store.process(.hookReceived(event))

        let before = await store.session(for: "test-4")
        XCTAssertEqual(before?.phase, .ended)

        // Should not crash or cause issues
        await store.scanForZombies()

        let after = await store.session(for: "test-4")
        XCTAssertEqual(after?.phase, .ended)
    }

    /// clearEndedSessions should remove only ended sessions
    func test_clearEndedSessions() async {
        let checker = MockLivenessChecker(aliveSet: [10, 20])
        let store = SessionStore(livenessChecker: checker)

        // Create 3 sessions: one will be ended, two active
        let e1 = makeHookEvent(sessionId: "ended-1", cwd: "/tmp", pid: 1, status: "ended")
        let e2 = makeHookEvent(sessionId: "active-1", cwd: "/tmp", pid: 10, status: nil)
        let e3 = makeHookEvent(sessionId: "active-2", cwd: "/tmp", pid: 20, status: nil)
        await store.process(.hookReceived(e1))
        await store.process(.hookReceived(e2))
        await store.process(.hookReceived(e3))

        // Verify ended session exists
        let endedBefore = await store.session(for: "ended-1")
        XCTAssertEqual(endedBefore?.phase, .ended)

        // Clear ended sessions
        await store.process(.clearEndedSessions)

        // Ended session should be gone
        let endedAfter = await store.session(for: "ended-1")
        XCTAssertNil(endedAfter)

        // Active sessions should remain
        let active1 = await store.session(for: "active-1")
        XCTAssertNotNil(active1)
        let active2 = await store.session(for: "active-2")
        XCTAssertNotNil(active2)
    }

    // MARK: - Helpers

    private func makeHookEvent(sessionId: String, cwd: String, pid: Int?, status: String?) -> HookEvent {
        HookEvent(
            sessionId: sessionId,
            cwd: cwd,
            event: status == "ended" ? "Stop" : "UserPromptSubmit",
            status: status ?? "active",
            pid: pid,
            tty: nil,
            tool: nil,
            toolInput: nil,
            toolUseId: nil,
            notificationType: nil,
            message: nil
        )
    }
}
