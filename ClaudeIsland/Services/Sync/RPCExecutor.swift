//
//  RPCExecutor.swift
//  ClaudeIsland
//
//  Handles RPC calls from the CodeLight iPhone app.
//  Executes bash commands, reads/writes files on the local Mac.
//

import Foundation
import os.log

/// Executes RPC calls received from the CodeLight phone app via server relay.
@MainActor
final class RPCExecutor {

    static let logger = Logger(subsystem: "com.codeisland", category: "RPCExecutor")

    /// Register RPC handlers on a server connection.
    func register(on connection: ServerConnection, sessionId: String) {
        // Register as the RPC handler for this session
        connection.registerRpc(method: sessionId)

        connection.onRpcCall = { [weak self] method, params, respond in
            Task { @MainActor in
                await self?.handleRpcCall(method: method, params: params, respond: respond)
            }
        }

        Self.logger.info("RPC executor registered for session \(sessionId)")
    }

    // MARK: - RPC Dispatch

    private func handleRpcCall(method: String, params: String, respond: @escaping (String) -> Void) async {
        // Method format: "{sessionId}:{command}"
        let parts = method.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else {
            respond(errorJson("Invalid method format"))
            return
        }

        let command = String(parts[1])

        guard let paramsData = Data(base64Encoded: params) ?? params.data(using: .utf8),
              let paramsDict = try? JSONSerialization.jsonObject(with: paramsData) as? [String: Any] else {
            respond(errorJson("Invalid params"))
            return
        }

        Self.logger.debug("RPC call: \(command)")

        switch command {
        case "bash":
            await handleBash(params: paramsDict, respond: respond)
        case "readFile":
            await handleReadFile(params: paramsDict, respond: respond)
        case "writeFile":
            await handleWriteFile(params: paramsDict, respond: respond)
        case "listDirectory":
            await handleListDirectory(params: paramsDict, respond: respond)
        default:
            respond(errorJson("Unknown command: \(command)"))
        }
    }

    // MARK: - Command Handlers

    private func handleBash(params: [String: Any], respond: @escaping (String) -> Void) async {
        guard let command = params["command"] as? String else {
            respond(errorJson("Missing 'command'"))
            return
        }

        let cwd = params["cwd"] as? String
        let timeout = (params["timeout"] as? Double) ?? 30.0

        do {
            let result = try await runShellCommand(command, cwd: cwd, timeout: timeout)
            let response: [String: Any] = [
                "success": true,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "exitCode": result.exitCode,
            ]
            respond(jsonString(response))
        } catch {
            respond(errorJson("Bash error: \(error.localizedDescription)"))
        }
    }

    private func handleReadFile(params: [String: Any], respond: @escaping (String) -> Void) async {
        guard let path = params["path"] as? String else {
            respond(errorJson("Missing 'path'"))
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let base64 = data.base64EncodedString()
            respond(jsonString(["success": true, "content": base64]))
        } catch {
            respond(errorJson("Read error: \(error.localizedDescription)"))
        }
    }

    private func handleWriteFile(params: [String: Any], respond: @escaping (String) -> Void) async {
        guard let path = params["path"] as? String,
              let content = params["content"] as? String,
              let data = Data(base64Encoded: content) else {
            respond(errorJson("Missing 'path' or 'content'"))
            return
        }

        do {
            let url = URL(fileURLWithPath: path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
            respond(jsonString(["success": true]))
        } catch {
            respond(errorJson("Write error: \(error.localizedDescription)"))
        }
    }

    private func handleListDirectory(params: [String: Any], respond: @escaping (String) -> Void) async {
        guard let path = params["path"] as? String else {
            respond(errorJson("Missing 'path'"))
            return
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            respond(jsonString(["success": true, "files": contents]))
        } catch {
            respond(errorJson("List error: \(error.localizedDescription)"))
        }
    }

    // MARK: - Shell Execution

    private struct ShellResult {
        let stdout: String
        let stderr: String
        let exitCode: Int
    }

    private func runShellCommand(_ command: String, cwd: String?, timeout: Double) async throws -> ShellResult {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]
            if let cwd { process.currentDirectoryURL = URL(fileURLWithPath: cwd) }

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }

            // Timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning { process.terminate() }
            }

            process.waitUntilExit()

            let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

            continuation.resume(returning: ShellResult(
                stdout: stdout,
                stderr: stderr,
                exitCode: Int(process.terminationStatus)
            ))
        }
    }

    // MARK: - Helpers

    private func errorJson(_ message: String) -> String {
        jsonString(["success": false, "error": message])
    }

    private func jsonString(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}
