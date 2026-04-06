//
//  SessionFilterTests.swift
//  ClaudeIslandTests
//
//  Tests for session display filtering logic.
//

import XCTest
@testable import ClaudeIsland

final class SessionFilterTests: XCTestCase {

    /// Ended session that ran >= 30s should be kept (shown as "Ended" state)
    func test_endedLongSession_kept() {
        let session = makeSession(phase: .ended, createdSecondsAgo: 60)
        let result = SessionFilter.filterForDisplay([session])
        XCTAssertEqual(result.count, 1)
    }

    /// Ended session that ran < 30s should be hidden (rate-limit noise)
    func test_endedShortSession_hidden() {
        let session = makeSession(phase: .ended, createdSecondsAgo: 5)
        let result = SessionFilter.filterForDisplay([session])
        XCTAssertEqual(result.count, 0)
    }

    /// Active session should always be kept
    func test_activeSession_kept() {
        let session = makeSession(phase: .processing, createdSecondsAgo: 10)
        let result = SessionFilter.filterForDisplay([session])
        XCTAssertEqual(result.count, 1)
    }

    /// Idle session should always be kept
    func test_idleSession_kept() {
        let session = makeSession(phase: .idle, createdSecondsAgo: 120)
        let result = SessionFilter.filterForDisplay([session])
        XCTAssertEqual(result.count, 1)
    }

    /// Mixed sessions: filters only short-lived ended ones
    func test_mixedSessions_correctFiltering() {
        let sessions = [
            makeSession(phase: .processing, createdSecondsAgo: 10),
            makeSession(phase: .ended, createdSecondsAgo: 5),   // noise — filtered
            makeSession(phase: .ended, createdSecondsAgo: 120), // kept
            makeSession(phase: .idle, createdSecondsAgo: 300),
        ]
        let result = SessionFilter.filterForDisplay(sessions)
        XCTAssertEqual(result.count, 3)
    }

    // MARK: - Helpers

    private func makeSession(phase: SessionPhase, createdSecondsAgo: TimeInterval) -> SessionState {
        SessionState(
            sessionId: UUID().uuidString,
            cwd: "/tmp/test",
            projectName: "test",
            phase: phase,
            createdAt: Date().addingTimeInterval(-createdSecondsAgo)
        )
    }
}
