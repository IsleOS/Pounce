//
//  NotchMenuView.swift
//  ClaudeIsland
//
//  Minimal menu matching Dynamic Island aesthetic
//

import ApplicationServices
import Combine
import SwiftUI
import ServiceManagement

// MARK: - NotchMenuView

struct NotchMenuView: View {
    @ObservedObject var viewModel: NotchViewModel
    @ObservedObject private var screenSelector = ScreenSelector.shared
    @ObservedObject private var soundSelector = SoundSelector.shared
    @AppStorage("showGroupedSessions") private var showGrouped: Bool = false
    @AppStorage("usePixelCat") private var usePixelCat: Bool = false
    @AppStorage("smartSuppression") private var smartSuppression: Bool = true
    @AppStorage("autoCollapseOnMouseLeave") private var autoCollapseOnMouseLeave: Bool = true
    @AppStorage("usageWarningThreshold") private var usageWarningThreshold: Int = 90
    @State private var hooksInstalled: Bool = false
    @State private var launchAtLogin: Bool = false

    // MARK: - Compact Toggle
    private func compactToggle(icon: String, label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 12)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Circle()
                    .fill(isOn ? TerminalColors.green : Color.white.opacity(0.2))
                    .frame(width: 5, height: 5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.25))
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: back + quit
            HStack {
                Button {
                    viewModel.toggleMenu()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10))
                        Text(L10n.back)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text(L10n.quit)
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Scrollable settings
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    // Appearance
                    sectionHeader(L10n.tr("Appearance", "外观"))
                    ScreenPickerRow(screenSelector: screenSelector)
                    SoundPickerRow(soundSelector: soundSelector)
                    LanguageRow()
                    ThresholdPickerRow(threshold: $usageWarningThreshold)

                    // Toggle grid — 2 columns
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        compactToggle(icon: "cat", label: "Pixel Cat", isOn: usePixelCat) { usePixelCat.toggle() }
                        compactToggle(icon: "folder", label: L10n.groupByProject, isOn: showGrouped) { showGrouped.toggle() }
                        compactToggle(icon: "eye.slash", label: L10n.smartSuppression, isOn: smartSuppression) { smartSuppression.toggle() }
                        compactToggle(icon: "rectangle.compress.vertical", label: L10n.autoCollapseOnMouseLeave, isOn: autoCollapseOnMouseLeave) { autoCollapseOnMouseLeave.toggle() }
                    }
                    .padding(.horizontal, 4)

                    // System
                    sectionHeader(L10n.tr("System", "系统"))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        compactToggle(icon: "power", label: L10n.launchAtLogin, isOn: launchAtLogin) {
                            do {
                                if launchAtLogin {
                                    try SMAppService.mainApp.unregister()
                                    launchAtLogin = false
                                } else {
                                    try SMAppService.mainApp.register()
                                    launchAtLogin = true
                                }
                            } catch {}
                        }
                        compactToggle(icon: "arrow.triangle.2.circlepath", label: L10n.hooks, isOn: hooksInstalled) {
                            if hooksInstalled {
                                HookInstaller.uninstall()
                                hooksInstalled = false
                            } else {
                                HookInstaller.installIfNeeded()
                                hooksInstalled = true
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    // Clear ended sessions
                    Button {
                        Task { await SessionStore.shared.process(.clearEndedSessions) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 12)
                            Text(L10n.clearEnded)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)

                    AccessibilityRow(isEnabled: AXIsProcessTrusted())

                    // Star & Feedback
                    HStack(spacing: 6) {
                        Button {
                            NSWorkspace.shared.open(URL(string: "https://github.com/xmqywx/CodeIsland")!)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill").font(.system(size: 9)).foregroundColor(.yellow)
                                Text("Star").font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.yellow.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.yellow.opacity(0.15), lineWidth: 0.5)))
                        }
                        .buttonStyle(.plain)

                        Button {
                            NSWorkspace.shared.open(URL(string: "https://github.com/xmqywx/CodeIsland/issues")!)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "bubble.left").font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                                Text(L10n.tr("Feedback", "反馈")).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 6)

                    VersionRow()

                    // WeChat contact
                    HStack(spacing: 4) {
                        Text(L10n.tr("WeChat", "微信"))
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.2))
                        Text("A115939")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                            .textSelection(.enabled)
                    }
                    .padding(.top, 4)

                    Text(L10n.tr("Actively maintained · Your star keeps us going!\nHave ideas? Tap Feedback — we'd love to hear from you!", "持续更新中 · Star 是我们最大的动力！\n有好的想法？点击反馈告诉我们，期待下个版本见！"))
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.15))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            refreshStates()
        }
        .onChange(of: viewModel.contentType) { _, newValue in
            if newValue == .menu {
                refreshStates()
            }
        }
    }

    private func refreshStates() {
        hooksInstalled = HookInstaller.isInstalled()
        launchAtLogin = SMAppService.mainApp.status == .enabled
        screenSelector.refreshScreens()
    }
}

// MARK: - Version Row

struct VersionRow: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 16)

            Text(L10n.version)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(appVersion)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Accessibility Permission Row

struct AccessibilityRow: View {
    let isEnabled: Bool

    @State private var isHovered = false
    @State private var refreshTrigger = false

    private var currentlyEnabled: Bool {
        // Re-check on each render when refreshTrigger changes
        _ = refreshTrigger
        return isEnabled
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.raised")
                .font(.system(size: 12))
                .foregroundColor(textColor)
                .frame(width: 16)

            Text(L10n.accessibility)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor)

            Spacer()

            if isEnabled {
                Circle()
                    .fill(TerminalColors.green)
                    .frame(width: 6, height: 6)

                Text(L10n.enabled)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            } else {
                Button(action: openAccessibilitySettings) {
                    Text(L10n.enable)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
        )
        .onHover { isHovered = $0 }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshTrigger.toggle()
        }
    }

    private var textColor: Color {
        .white.opacity(isHovered ? 1.0 : 0.7)
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct MenuRow: View {
    let icon: String
    let label: String
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(textColor)
                    .frame(width: 16)

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textColor)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var textColor: Color {
        if isDestructive {
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        }
        return .white.opacity(isHovered ? 1.0 : 0.7)
    }
}

struct MenuToggleRow: View {
    let icon: String
    let label: String
    let isOn: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(textColor)
                    .frame(width: 16)

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textColor)

                Spacer()

                Circle()
                    .fill(isOn ? TerminalColors.green : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)

                Text(isOn ? L10n.on : L10n.off)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var textColor: Color {
        .white.opacity(isHovered ? 1.0 : 0.7)
    }
}

// MARK: - Language Picker

struct LanguageRow: View {
    @State private var isExpanded = false
    @State private var isHovered = false
    @State private var current = L10n.appLanguage

    private let options: [(id: String, label: String)] = [
        ("auto", "Auto / 自动"),
        ("en", "English"),
        ("zh", "中文"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 12))
                        .foregroundColor(textColor)
                        .frame(width: 16)

                    Text(L10n.language)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(textColor)

                    Spacer()

                    Text(L10n.currentLanguageLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(options, id: \.id) { option in
                        Button {
                            L10n.appLanguage = option.id
                            current = option.id
                        } label: {
                            HStack {
                                Text(option.label)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                if current == option.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.03))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var textColor: Color {
        .white.opacity(isHovered ? 1.0 : 0.7)
    }
}

// MARK: - Threshold Picker Row

struct ThresholdPickerRow: View {
    @Binding var threshold: Int
    @State private var isHovered = false

    private let options: [(value: Int, label: String)] = [
        (70, "70%"),
        (80, "80%"),
        (90, "90%"),
        (0, "Off"),
    ]

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "gauge.with.needle")
                .font(.system(size: 12))
                .foregroundColor(textColor)
                .frame(width: 16)

            Text(L10n.tr("Alert", "警告阈值"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor)

            Spacer()

            HStack(spacing: 3) {
                ForEach(options, id: \.value) { option in
                    Button {
                        threshold = option.value
                    } label: {
                        Text(option.label)
                            .font(.system(size: 10, weight: threshold == option.value ? .bold : .regular))
                            .foregroundColor(threshold == option.value ? .white : .white.opacity(0.4))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(threshold == option.value ? Color.white.opacity(0.15) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
        )
        .onHover { isHovered = $0 }
    }

    private var textColor: Color {
        .white.opacity(isHovered ? 1.0 : 0.7)
    }
}
