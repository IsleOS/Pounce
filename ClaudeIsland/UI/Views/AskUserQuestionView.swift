//
//  AskUserQuestionView.swift
//  ClaudeIsland
//
//  Interactive UI for answering AskUserQuestion prompts from Claude Code.
//  Sends the selected option index to the terminal via AppleScript / cmux.
//

import SwiftUI

struct AskUserQuestionView: View {
    let session: SessionState
    let context: QuestionContext
    @ObservedObject var sessionMonitor: ClaudeSessionMonitor
    /// Called when the user taps the header X. Hides this view in the
    /// parent (back to the regular instances list); does NOT send any
    /// keystrokes to the CLI — the underlying Claude session keeps
    /// waiting until the user answers via terminal or another device.
    var onDismiss: (() -> Void)? = nil
    @ObservedObject private var notchStore: NotchCustomizationStore = .shared
    @State private var customTexts: [Int: String] = [:]  // per-question custom text
    @State private var hoveredKey: String? = nil
    @State private var isSending: Bool = false
    private var theme: ThemeResolver { ThemeResolver(theme: notchStore.customization.theme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(session.projectName)
                    .notchFont(11, weight: .semibold)
                    .notchSecondaryForeground()
                Spacer()
                if let onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(theme.secondaryText.opacity(0.5))
                            .frame(width: 18, height: 18)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Hide this question — CLI still waits for your reply")
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)

            // Questions + options
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(context.questions.enumerated()), id: \.offset) { qIdx, question in
                        questionBlock(questionIndex: qIdx, question: question)
                    }
                }
                .padding(.horizontal, 12)
            }

            Spacer(minLength: 4)


            // Bottom bar: multi-question gets Submit/Cancel, single gets Jump to Terminal
            if context.questions.count > 1 {
                HStack(spacing: 8) {
                    // Submit Answers — sends Enter (option 1 in CLI)
                    Button { confirmSubmit() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .notchFont(9)
                            Text("Submit")
                                .notchFont(10, weight: .medium)
                        }
                        .foregroundColor(theme.needsYouColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.needsYouColor.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(theme.needsYouColor.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    // Cancel — sends ↓ + Enter (option 2 in CLI)
                    Button { cancelSubmit() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .notchFont(9)
                            Text("Cancel")
                                .notchFont(10, weight: .medium)
                        }
                        .foregroundColor(theme.secondaryText.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.primaryText.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(theme.primaryText.opacity(0.08), lineWidth: 0.5)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }

            // Jump to terminal — always at bottom
            jumpToTerminalButton
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        // Reset state when a new question arrives (different toolUseId)
        .onChange(of: context.toolUseId) { _ in
            isSending = false
            customTexts = [:]
            hoveredKey = nil
        }
    }

    // MARK: - Question Block

    @ViewBuilder
    private func questionBlock(questionIndex: Int, question: QuestionItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question.question)
                .notchFont(12, weight: .semibold)
                .foregroundColor(theme.primaryText.opacity(0.9))
                .padding(.bottom, 2)

            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                optionRow(questionIndex: questionIndex, optionIndex: index + 1, option: option, optionCount: question.options.count)
            }

            // Inline "Other" input — only for single-question calls.
            // Multi-question + Other is unreliable due to terminal interaction timing.
            if context.questions.count == 1 {
                inlineOtherInput(questionIndex: questionIndex, optionCount: question.options.count)
            }
        }
    }

    private func optionRow(questionIndex: Int, optionIndex: Int, option: QuestionOption, optionCount: Int) -> some View {
        let hoverKey = "\(questionIndex)-\(optionIndex)"
        let isHovered = hoveredKey == hoverKey

        return Button {
            guard !isSending else { return }
            isSending = true
            DebugLogger.log("AskUser", "Option \(optionIndex) tapped: \(option.label)")
            Task { await approveAndSendOption(index: optionIndex) }
        } label: {
            HStack(spacing: 8) {
                Text("\(optionIndex)")
                    .notchFont(10, weight: .bold)
                    .foregroundColor(theme.needsYouColor)
                    .frame(width: 18, height: 18)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.needsYouColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(option.label)
                        .notchFont(11, weight: .medium)
                        .foregroundColor(theme.primaryText.opacity(0.85))

                    if let desc = option.description, !desc.isEmpty {
                        Text(desc)
                            .notchFont(9, weight: .regular)
                            .foregroundColor(theme.secondaryText.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .notchFont(8)
                    .foregroundColor(theme.secondaryText.opacity(isHovered ? 0.7 : 0.25))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? theme.needsYouColor.opacity(0.08) : theme.primaryText.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(
                                isHovered ? theme.needsYouColor.opacity(0.2) : theme.primaryText.opacity(0.06),
                                lineWidth: 0.5
                            )
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredKey = hovering ? hoverKey : nil
        }
    }

    // MARK: - Custom Input

    /// Inline "Other" input at the end of a question's options
    @ViewBuilder
    private func inlineOtherInput(questionIndex: Int, optionCount: Int) -> some View {
        HStack(spacing: 6) {
            TextField("Other...", text: Binding(
                get: { customTexts[questionIndex] ?? "" },
                set: { customTexts[questionIndex] = $0 }
            ))
            .textFieldStyle(.plain)
            .notchFont(11)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.primaryText.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(theme.primaryText.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .onSubmit { submitOtherForQuestion(questionIndex: questionIndex, optionCount: optionCount) }

            Button {
                submitOtherForQuestion(questionIndex: questionIndex, optionCount: optionCount)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(
                        (customTexts[questionIndex] ?? "").isEmpty || isSending
                            ? theme.secondaryText.opacity(0.2)
                            : theme.needsYouColor
                    )
            }
            .buttonStyle(.plain)
            .disabled((customTexts[questionIndex] ?? "").isEmpty || isSending)
        }
    }

    // MARK: - Jump to Terminal

    private var jumpToTerminalButton: some View {
        Button {
            Task { await TerminalJumper.shared.jump(to: session) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .notchFont(10)
                Text("Jump to Terminal")
                    .notchFont(10, weight: .medium)
            }
            .foregroundColor(theme.secondaryText.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.primaryText.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(theme.primaryText.opacity(0.08), lineWidth: 0.5)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Terminal Sending

    /// Navigate to the option using arrow keys and press Enter.
    /// Claude Code's AskUserQuestion uses an arrow-key navigation UI
    /// (↑/↓ to navigate, Enter to select), not numbered input.
    /// Default cursor position is on option 1 (index=1).
    private func approveAndSendOption(index: Int) async {
        let cwd = session.cwd
        let downPresses = index - 1

        for _ in 0..<downPresses {
            performGhosttyAction("csi:B", cwd: cwd) // Arrow Down
        }
        if downPresses > 0 {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        performGhosttyAction("text:\\r", cwd: cwd) // Enter

        DebugLogger.log("AskUser", "Sent \(downPresses) arrows + Enter")

        // Reset after delay to allow next question click
        try? await Task.sleep(nanoseconds: 800_000_000)
        isSending = false
    }

    /// Send Enter to confirm "Submit answers" (option 1 in CLI).
    private func confirmSubmit() {
        let cwd = session.cwd
        performGhosttyAction("text:\\r", cwd: cwd) // Enter selects default (Submit)
        DebugLogger.log("AskUser", "Confirmed submit")
    }

    /// Send ↓ + Enter to select "Cancel" (option 2 in CLI).
    private func cancelSubmit() {
        let cwd = session.cwd
        performGhosttyAction("csi:B", cwd: cwd) // Arrow Down to Cancel
        performGhosttyAction("text:\\r", cwd: cwd) // Enter
        DebugLogger.log("AskUser", "Cancelled submit")
    }

    /// Submit custom text for a specific question.
    /// "Type something" is option (optionCount + 1) in the CLI.
    private func submitOtherForQuestion(questionIndex: Int, optionCount: Int) {
        let text = customTexts[questionIndex] ?? ""
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        DebugLogger.log("AskUser", "Q\(questionIndex) custom text: \(text)")
        Task {
            let cwd = session.cwd
            // Navigate to "Type something" option (after all regular options)
            for _ in 0..<optionCount {
                performGhosttyAction("csi:B", cwd: cwd)
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
            performGhosttyAction("text:\\r", cwd: cwd) // Select "Type something"
            // Wait for text input prompt
            try? await Task.sleep(nanoseconds: 500_000_000)
            // Type the custom text + Enter
            let escaped = text.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            performGhosttyAction("text:\(escaped)\\r", cwd: cwd)

            // Reset for next question
            try? await Task.sleep(nanoseconds: 800_000_000)
            isSending = false
        }
    }

    /// Execute a Ghostty action on the cmux terminal via AppleScript.
    /// cmux's `perform action` sends real keyboard events through
    /// Ghostty's input system — works with Claude Code's raw terminal mode.
    @discardableResult
    private func performGhosttyAction(_ action: String, cwd: String) -> Bool {
        let escapedCwd = cwd.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "cmux"
            set targetTerm to (first terminal whose working directory is "\(escapedCwd)")
            perform action "\(action)" on targetTerm
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func runAppleScript(_ script: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
