//
//  ClaudeStopVariantView.swift
//  ClaudeIsland
//
//  Variant A — Claude Stop. 3-line summary + phrase buttons + "Go to
//  terminal". 15s auto-dismiss + autoCollapseOnMouseLeave. Spec §5.6.
//

import SwiftUI

struct ClaudeStopVariantView: View {
    let entry: CompletionEntry
    let summary: String
    @ObservedObject private var controller = CompletionPanelController.shared
    @State private var isCodex: Bool = false

    private var phrases: [QuickReplyPhrase] { QuickReplyPhrases.current }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            summaryView
            if let err = controller.state.sendError, err.stableId == entry.stableId {
                errorRow(err.message)
            }
            if !isCodex { phraseRow }
            terminalButtonRow
        }
        .task(id: entry.stableId) {
            isCodex = (await SessionStore.shared.session(withStableId: entry.stableId)?.codexTranscriptPath != nil)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { controller.setPanelVisible(true) }
        .onDisappear { controller.setPanelVisible(false) }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(entry.projectName).font(.system(size: 12, weight: .semibold))
            Spacer()
            if controller.state.pendingCount > 0 {
                Text("+\(controller.state.pendingCount)")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            Button { controller.dismissFront(stableId: entry.stableId) } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.qrClose)
        }
    }

    private var summaryView: some View {
        Text(summary.isEmpty ? "…" : summary)
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(3)
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
    }

    private func errorRow(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
            Text(message).font(.system(size: 10))
            Spacer()
            Button(L10n.qrGoToTerminal) { jumpToTerminal() }
                .buttonStyle(.plain).font(.system(size: 10, weight: .semibold))
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.yellow.opacity(0.14)))
    }

    private var phraseRow: some View {
        HStack(spacing: 6) {
            ForEach(phrases) { phrase in
                Button(phrase.text) { send(phrase.text) }
                    .buttonStyle(.plain).font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)))
            }
            Spacer()
        }
    }

    private var terminalButtonRow: some View {
        HStack {
            Spacer()
            Button(L10n.qrGoToTerminal) { jumpToTerminal() }
                .buttonStyle(.plain).font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 7)
                    .fill(Color(red: 0xCA/255, green: 0xFF/255, blue: 0x00/255)))
                .foregroundColor(.black)
        }
    }

    private func send(_ text: String) {
        let stableId = entry.stableId
        Task {
            guard let session = await SessionStore.shared.session(withStableId: stableId) else {
                DebugLogger.log("CP/send", "no session for stableId=\(stableId.prefix(8))")
                await MainActor.run {
                    controller.recordSendFailure(stableId: stableId, message: L10n.qrSendFailed)
                }
                return
            }
            DebugLogger.log("CP/send", "attempt session=\(stableId.prefix(8)) termApp=\(session.terminalApp ?? "nil") pid=\(session.pid) cwd=\(session.cwd) text=\(text)")
            // Use sendTextDirect — it resolves the cmux target via livePid
            // (CMUX_*_ID env vars in /proc), which works regardless of the
            // user's cmux workspace title. `sendText(_:to:)` falls back to
            // string-matching cwd dirName against workspace title, which
            // breaks when the user has renamed their workspace (e.g. "ISLAND"
            // instead of "CodeIsland").
            let ok = await TerminalWriter.shared.sendTextDirect(
                text + "\n",
                claudeUuid: session.sessionId,
                cwd: session.cwd,
                livePid: session.pid,
                cmuxWorkspaceId: nil,
                cmuxSurfaceId: nil,
                terminalApp: session.terminalApp
            )
            DebugLogger.log("CP/send", "result session=\(stableId.prefix(8)) ok=\(ok)")
            await MainActor.run {
                if ok { controller.dismissFront(stableId: stableId) }
                else  { controller.recordSendFailure(stableId: stableId, message: L10n.qrSendFailed) }
            }
        }
    }

    private func jumpToTerminal() {
        let stableId = entry.stableId
        Task {
            guard let session = await SessionStore.shared.session(withStableId: stableId) else { return }
            _ = await TerminalJumper.shared.jump(to: session)
            await MainActor.run { controller.dismissFront(stableId: stableId) }
        }
    }
}
