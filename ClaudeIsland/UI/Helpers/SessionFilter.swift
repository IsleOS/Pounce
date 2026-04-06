//
//  SessionFilter.swift
//  ClaudeIsland
//
//  Extracted filtering logic for session display list.
//  Separated for testability.
//

import Foundation

enum SessionFilter {
    /// Filter sessions for display: hide rate-limit noise (ended sessions that ran < 30s).
    /// Ended sessions that ran >= 30s are kept and shown with "Ended" visual state.
    static func filterForDisplay(_ sessions: [SessionState]) -> [SessionState] {
        sessions.filter { session in
            if session.phase == .ended {
                // Rate-limit noise: short-lived sessions that ended quickly
                let duration = Date().timeIntervalSince(session.createdAt)
                return duration >= 30
            }
            return true
        }
    }
}
