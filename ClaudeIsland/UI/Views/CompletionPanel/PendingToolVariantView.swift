//
//  PendingToolVariantView.swift
//  ClaudeIsland
//
//  Variant C — pending tool. Low-risk: 3-button inject 1/2/3\n via
//  TerminalWriter. High-risk: display-only + "Go to terminal". Spec §5.6/§6.
//

import SwiftUI

struct PendingToolVariantView: View {
    let entry: CompletionEntry
    let request: ToolApprovalRequest
    @ObservedObject private var controller = CompletionPanelController.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            toolLine
            if let err = controller.state.sendError, err.stableId == entry.stableId {
                errorRow(err.message)
            }
            if request.riskLevel == .low { actionRow } else { highRiskHintRow }
            terminalButtonRow
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { controller.setPanelVisible(true) }
        .onDisappear { controller.setPanelVisible(false) }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange).font(.system(size: 11))
            Text(entry.projectName).font(.system(size: 12, weight: .semibold))
            Text(L10n.pendingToolNeedsApproval)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Capsule().fill(Color.orange.opacity(0.2)))
                .foregroundColor(.orange)
            Spacer()
            Button { controller.dismissFront(stableId: entry.stableId) } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.qrClose)
        }
    }

    private var toolLine: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(request.toolName) 想执行：")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.85))
            Text(request.argumentsSummary)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.95))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                .lineLimit(2).truncationMode(.tail)
        }
    }

    private func errorRow(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
            Text(message).font(.system(size: 10))
            Spacer()
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.yellow.opacity(0.14)))
    }

    private var actionRow: some View {
        HStack(spacing: 6) {
            Button(L10n.pendingToolAllow) { inject("1\n") }
                .buttonStyle(.plain).font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0xCA/255, green: 0xFF/255, blue: 0x00/255)))
                .foregroundColor(.black)
            Button(L10n.pendingToolDeny) { inject("2\n") }
                .buttonStyle(.plain).font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.25)))
                .foregroundColor(Color.red.opacity(0.9))
            Button(L10n.pendingToolAlwaysAllow(request.toolName)) { inject("3\n") }
                .buttonStyle(.plain).font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)))
            Spacer()
        }
    }

    private var highRiskHintRow: some View {
        HStack {
            Text(L10n.pendingToolHighRiskHint)
                .font(.system(size: 10))
                .foregroundColor(.orange.opacity(0.9))
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

    private func inject(_ text: String) {
        let stableId = entry.stableId
        Task {
            DebugLogger.log("CP/injection", "toolName=\(request.toolName) sent=\(text.trimmingCharacters(in: .newlines)) session=\(stableId.prefix(8))")
            guard let session = await SessionStore.shared.session(withStableId: stableId) else {
                await MainActor.run {
                    controller.recordSendFailure(stableId: stableId, message: L10n.qrSendFailed)
                }
                return
            }
            DebugLogger.log("CP/injection", "attempt termApp=\(session.terminalApp ?? "nil") pid=\(session.pid) cwd=\(session.cwd)")
            // Use sendTextDirect for pid-based cmux target resolution (see ClaudeStopVariantView).
            let ok = await TerminalWriter.shared.sendTextDirect(
                text,
                claudeUuid: session.sessionId,
                cwd: session.cwd,
                livePid: session.pid,
                cmuxWorkspaceId: nil,
                cmuxSurfaceId: nil,
                terminalApp: session.terminalApp
            )
            DebugLogger.log("CP/injection", "result session=\(stableId.prefix(8)) ok=\(ok)")
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
