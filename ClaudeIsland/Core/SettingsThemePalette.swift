//
//  SettingsThemePalette.swift
//  ClaudeIsland
//
//  Value type holding every color role used in the settings window.
//  The `default` instance reproduces the current main-branch appearance
//  exactly. Theme plugins construct palettes via `from(config:)`.
//
//  Spec: docs/superpowers/specs/2026-04-13-settings-theme-palette-refactor-design.md
//

import SwiftUI

struct SettingsThemePalette {
    // MARK: - Meta
    let colorScheme: ColorScheme

    // MARK: - Sidebar (5 roles)
    let sidebarFill: Color
    let sidebarText: Color
    let sidebarSelected: Color
    let sidebarSelectedText: Color
    let sidebarBorder: Color

    // MARK: - Detail (6 roles)
    let detailFill: Color
    let detailText: Color
    let cardFill: Color
    let cardBorder: Color
    let subtle: Color
    let accent: Color

    // MARK: - Controls (6 roles)
    let accentText: Color
    let toggleOn: Color
    let toggleOff: Color
    let toggleOnBg: Color
    let toggleOffBg: Color
    let toggleOnBorder: Color

    // MARK: - Interactive states (3 roles)
    let hover: Color
    let secondaryButtonFill: Color
    let secondaryButtonBorder: Color

    // MARK: - Status (3 roles)
    let statusOk: Color
    let statusError: Color
    let statusUnknown: Color

    // MARK: - Logs (3 roles)
    let logDefault: Color
    let logError: Color
    let logWarning: Color

    // MARK: - Window (2 roles)
    let windowBorder: Color
    let windowShadow: Color

    // MARK: - Extensions (illustrations + icons, nil for default theme)
    let illustrations: SettingsThemeIllustrations?
    let icons: SettingsThemeIcons?
}

// MARK: - Default palette (current main-branch appearance)

extension SettingsThemePalette {
    static let `default` = SettingsThemePalette(
        colorScheme: .dark,

        // Sidebar — SystemSettingsView.swift Theme enum lines 175-179
        sidebarFill: BrandColors.lime,
        sidebarText: .black,
        sidebarSelected: Color.black.opacity(0.85),
        sidebarSelectedText: BrandColors.lime,
        sidebarBorder: Color.black.opacity(0.12),

        // Detail — SystemSettingsView.swift Theme enum lines 182-186
        detailFill: Color(red: 0.10, green: 0.10, blue: 0.11),
        detailText: .white,
        cardFill: Color.white.opacity(0.04),
        cardBorder: Color.white.opacity(0.08),
        subtle: Color.white.opacity(0.5),
        accent: BrandColors.lime,

        // Controls — SystemSettingsView.swift TabToggle lines 375-393
        accentText: .black,
        toggleOn: BrandColors.lime,
        toggleOff: Color.white.opacity(0.18),
        toggleOnBg: BrandColors.lime.opacity(0.1),
        toggleOffBg: Color.white.opacity(0.03),
        toggleOnBorder: BrandColors.lime.opacity(0.25),

        // Interactive states — SystemSettingsView.swift various buttons
        hover: Color.white.opacity(0.08),
        secondaryButtonFill: Color.white.opacity(0.06),
        secondaryButtonBorder: Color.white.opacity(0.08),

        // Status — SystemSettingsView.swift CmuxConnectionTab dotColor lines 941-943
        statusOk: Color(red: 0.3, green: 0.85, blue: 0.35),
        statusError: Color(red: 0.95, green: 0.35, blue: 0.35),
        statusUnknown: Color.white.opacity(0.25),

        // Logs — SystemSettingsView.swift LogsTab colorFor lines 1072-1078
        logDefault: Color.white.opacity(0.8),
        logError: Color(red: 1.0, green: 0.55, blue: 0.55),
        logWarning: Color(red: 1.0, green: 0.85, blue: 0.4),

        // Window — SystemSettingsView.swift lines 215, 217
        windowBorder: Color.white.opacity(0.08),
        windowShadow: Color.black.opacity(0.5),
        illustrations: nil,
        icons: nil
    )
}

// MARK: - Factory: construct from plugin JSON config

extension SettingsThemePalette {
    /// Build a full palette from plugin JSON. `bundleResourcesURL` is the
    /// plugin bundle's `Contents/Resources/` directory; relative asset paths
    /// in `config.illustrations` / `config.icons` are resolved against it.
    static func from(
        config: SettingsThemeConfig,
        bundleResourcesURL: URL
    ) -> SettingsThemePalette {
        let sidebarFill = Color(hex: config.sidebar.fill)
        let sidebarText = Color(hex: config.sidebar.text)
        let sidebarSelected = Color(hex: config.sidebar.selected)
        let sidebarSelectedText = Color(hex: config.sidebar.selectedText)
        let sidebarBorder = Color(hex: config.sidebar.border)

        let detailFill = Color(hex: config.detail.fill)
        let detailText = Color(hex: config.detail.text)
        let cardFill = Color(hex: config.detail.cardFill)
        let cardBorder = Color(hex: config.detail.cardBorder)
        let subtle = Color(hex: config.detail.subtle)
        let accent = Color(hex: config.detail.accent)

        let colorScheme: ColorScheme = config.colorScheme == .dark ? .dark : .light
        let accentText = accentTextColor(for: config.detail.accent)

        let illustrations = resolveIllustrations(
            config.illustrations,
            in: bundleResourcesURL
        )
        let icons = resolveIcons(
            config.icons,
            in: bundleResourcesURL
        )

        return SettingsThemePalette(
            colorScheme: colorScheme,

            sidebarFill: sidebarFill,
            sidebarText: sidebarText,
            sidebarSelected: sidebarSelected,
            sidebarSelectedText: sidebarSelectedText,
            sidebarBorder: sidebarBorder,

            detailFill: detailFill,
            detailText: detailText,
            cardFill: cardFill,
            cardBorder: cardBorder,
            subtle: subtle,
            accent: accent,

            accentText: accentText,
            toggleOn: accent,
            toggleOff: detailText.opacity(0.18),
            toggleOnBg: accent.opacity(0.1),
            toggleOffBg: detailText.opacity(0.03),
            toggleOnBorder: accent.opacity(0.25),

            hover: detailText.opacity(0.08),
            secondaryButtonFill: detailText.opacity(0.06),
            secondaryButtonBorder: cardBorder,

            statusOk: Color(red: 0.3, green: 0.85, blue: 0.35),
            statusError: Color(red: 0.95, green: 0.35, blue: 0.35),
            statusUnknown: detailText.opacity(0.25),

            logDefault: detailText.opacity(0.8),
            logError: Color(red: 1.0, green: 0.55, blue: 0.55),
            logWarning: Color(red: 1.0, green: 0.85, blue: 0.4),

            windowBorder: cardBorder,
            windowShadow: Color.black.opacity(0.5),

            illustrations: illustrations,
            icons: icons
        )
    }

    /// Returns `.black` for light accent colors, `.white` for dark ones.
    private static func accentTextColor(for hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        // Relative luminance (sRGB approximation)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5 ? .black : .white
    }

    // MARK: - Asset resolvers

    private static func resolveIllustrations(
        _ block: SettingsThemeConfig.IllustrationsBlock?,
        in resourcesURL: URL
    ) -> SettingsThemeIllustrations? {
        guard let block else { return nil }
        // Pre-load GIF bytes eagerly at activation time. The view just reads
        // from the resulting [Data] — no async load-on-appear race between
        // palette activation and view mount.
        let data: [Data] = block.files.compactMap { relPath in
            let url = resourcesURL.appendingPathComponent(relPath)
            return try? Data(contentsOf: url)
        }
        guard !data.isEmpty else { return nil }

        let duration = (block.cycleDuration ?? 8.0).clamped(to: 3.0...60.0)
        let transition: SettingsThemeIllustrations.Transition
        switch block.transition {
        case "slide":     transition = .slide
        case "none":      transition = .none
        default:          transition = .crossfade
        }

        return SettingsThemeIllustrations(
            data: data,
            cycleDuration: duration,
            transition: transition
        )
    }

    private static func resolveIcons(
        _ block: SettingsThemeConfig.IconsBlock?,
        in resourcesURL: URL
    ) -> SettingsThemeIcons? {
        guard let block else { return nil }
        let entries = SettingsThemeIcons(
            general:       resolveIconRef(block.general, in: resourcesURL),
            appearance:    resolveIconRef(block.appearance, in: resourcesURL),
            notifications: resolveIconRef(block.notifications, in: resourcesURL),
            behavior:      resolveIconRef(block.behavior, in: resourcesURL),
            plugins:       resolveIconRef(block.plugins, in: resourcesURL),
            codelight:     resolveIconRef(block.codelight, in: resourcesURL),
            advanced:      resolveIconRef(block.advanced, in: resourcesURL)
        )
        // If every field is nil the whole block is effectively empty — still
        // return it; views treat `nil` entries the same as an absent icon.
        return entries
    }

    private static func resolveIconRef(
        _ raw: String?,
        in resourcesURL: URL
    ) -> IconRef? {
        guard let raw, !raw.isEmpty else { return nil }
        let looksLikePath = raw.contains("/") || raw.lowercased().hasSuffix(".png")
        if looksLikePath {
            let url = resourcesURL.appendingPathComponent(raw)
            return FileManager.default.fileExists(atPath: url.path)
                ? .image(url)
                : nil
        } else {
            return .sfSymbol(raw)
        }
    }
}

// MARK: - ClosedRange clamping helper (scoped to this file)

fileprivate extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Extended palette types: illustrations + icons

struct SettingsThemeIllustrations: Equatable {
    let data: [Data]               // pre-loaded GIF bytes (empty => omit)
    let cycleDuration: Double      // clamped to 3.0...60.0
    let transition: Transition

    enum Transition {
        case crossfade
        case slide
        case none
    }
}

struct SettingsThemeIcons {
    let general: IconRef?
    let appearance: IconRef?
    let notifications: IconRef?
    let behavior: IconRef?
    let plugins: IconRef?
    let codelight: IconRef?
    let advanced: IconRef?

    func ref(for tab: SettingsTab) -> IconRef? {
        switch tab {
        case .general:         return general
        case .appearance:      return appearance
        case .notifications:   return notifications
        case .behavior:        return behavior
        case .plugins:         return plugins
        case .codelight:       return codelight
        case .advanced:        return advanced
        case .cmuxConnection,
             .logs,
             .about:           return nil
        }
    }
}

enum IconRef {
    case sfSymbol(String)
    case image(URL)
}

// MARK: - Plugin JSON config types

struct SettingsThemeConfig: Codable {
    let colorScheme: ThemeColorScheme
    let sidebar: SidebarColors
    let detail: DetailColors

    enum ThemeColorScheme: String, Codable {
        case light
        case dark
    }

    struct SidebarColors: Codable {
        let fill: String
        let text: String
        let selected: String
        let selectedText: String
        let border: String
    }

    struct DetailColors: Codable {
        let fill: String
        let text: String
        let cardFill: String
        let cardBorder: String
        let subtle: String
        let accent: String
    }

    // MARK: Optional plugin extensions (illustrations + icons)

    let illustrations: IllustrationsBlock?
    let icons: IconsBlock?

    struct IllustrationsBlock: Codable {
        let files: [String]           // relative paths inside the plugin bundle
        let cycleDuration: Double?    // seconds; missing → 8; clamped to 3...60
        let transition: String?       // "crossfade" | "slide" | "none"; missing → "crossfade"
    }

    struct IconsBlock: Codable {
        let general: String?
        let appearance: String?
        let notifications: String?
        let behavior: String?
        let plugins: String?
        let codelight: String?
        let advanced: String?
    }
}
