//
//  ProcessLivenessChecker.swift
//  ClaudeIsland
//
//  Checks whether a process is still alive via POSIX signals.
//  Protocol-based for test injection.
//

import Darwin

protocol ProcessLivenessChecker: Sendable {
    nonisolated func isAlive(pid: Int) -> Bool
}

struct PosixLivenessChecker: ProcessLivenessChecker {
    nonisolated func isAlive(pid: Int) -> Bool {
        // signal 0 checks existence without sending a signal
        // EPERM means the process exists but we lack permission — still alive
        let result = kill(pid_t(pid), 0)
        if result == 0 { return true }
        return errno == EPERM
    }
}
