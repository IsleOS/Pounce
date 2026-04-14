//
//  SettingsThemePaletteTests.swift
//  ClaudeIslandTests
//
//  Unit tests for SettingsThemePalette.from(config:bundleResourcesURL:)
//  resolution rules: icon disambiguation, cycleDuration clamping,
//  transition mapping, illustration URL existence pruning.
//

import XCTest
@testable import ClaudeIsland

final class SettingsThemePaletteTests: XCTestCase {

    // MARK: - Fixture

    private func makeConfig(
        illustrations: SettingsThemeConfig.IllustrationsBlock? = nil,
        icons: SettingsThemeConfig.IconsBlock? = nil
    ) -> SettingsThemeConfig {
        SettingsThemeConfig(
            colorScheme: .dark,
            sidebar: .init(
                fill: "#000000", text: "#FFFFFF",
                selected: "#111111", selectedText: "#FFFFFF",
                border: "#222222"
            ),
            detail: .init(
                fill: "#000000", text: "#FFFFFF",
                cardFill: "#111111", cardBorder: "#222222",
                subtle: "#333333", accent: "#FF0000"
            ),
            illustrations: illustrations,
            icons: icons
        )
    }

    private func makeTempBundleDir(withFiles names: [String] = []) -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for name in names {
            let url = dir.appendingPathComponent(name)
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            FileManager.default.createFile(atPath: url.path, contents: Data([0x47, 0x49, 0x46]))
        }
        return dir
    }

    // MARK: - Icon disambiguation

    func test_iconString_with_slash_becomes_image() {
        let bundleDir = makeTempBundleDir(withFiles: ["icons/gear.png"])
        let config = makeConfig(icons: .init(
            general: "icons/gear.png",
            appearance: nil, notifications: nil, behavior: nil,
            plugins: nil, codelight: nil, advanced: nil
        ))

        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)

        guard case .image(let url) = palette.icons?.general else {
            XCTFail("expected .image for path containing /, got \(String(describing: palette.icons?.general))")
            return
        }
        XCTAssertEqual(url.lastPathComponent, "gear.png")
    }

    func test_iconString_ending_png_without_slash_becomes_image() {
        let bundleDir = makeTempBundleDir(withFiles: ["gear.png"])
        let config = makeConfig(icons: .init(
            general: "gear.png",
            appearance: nil, notifications: nil, behavior: nil,
            plugins: nil, codelight: nil, advanced: nil
        ))

        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)

        guard case .image = palette.icons?.general else {
            XCTFail("expected .image for .png name, got \(String(describing: palette.icons?.general))")
            return
        }
    }

    func test_iconString_plain_name_becomes_sfSymbol() {
        let bundleDir = makeTempBundleDir()
        let config = makeConfig(icons: .init(
            general: "gearshape",
            appearance: "paintbrush.pointed.fill",
            notifications: nil, behavior: nil,
            plugins: nil, codelight: nil, advanced: nil
        ))

        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)

        XCTAssertEqual(palette.icons?.general, .sfSymbol("gearshape"))
        XCTAssertEqual(palette.icons?.appearance, .sfSymbol("paintbrush.pointed.fill"))
    }

    func test_iconString_missing_png_file_becomes_nil() {
        let bundleDir = makeTempBundleDir()  // no files
        let config = makeConfig(icons: .init(
            general: "icons/missing.png",
            appearance: nil, notifications: nil, behavior: nil,
            plugins: nil, codelight: nil, advanced: nil
        ))

        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)

        XCTAssertNil(palette.icons?.general, "missing PNG should resolve to nil, not raise")
    }

    // MARK: - Illustrations

    func test_illustrations_files_resolve_to_existing_urls_only() {
        let bundleDir = makeTempBundleDir(withFiles: [
            "assets/a.gif", "assets/c.gif"   // b.gif is missing
        ])
        let config = makeConfig(illustrations: .init(
            files: ["assets/a.gif", "assets/b.gif", "assets/c.gif"],
            cycleDuration: 8, transition: "crossfade"
        ))

        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)

        XCTAssertEqual(palette.illustrations?.files.count, 2)
        XCTAssertEqual(palette.illustrations?.files.map { $0.lastPathComponent }, ["a.gif", "c.gif"])
    }

    func test_illustrations_all_missing_becomes_nil() {
        let bundleDir = makeTempBundleDir()  // no files
        let config = makeConfig(illustrations: .init(
            files: ["assets/missing.gif"], cycleDuration: 8, transition: "crossfade"
        ))

        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)

        XCTAssertNil(palette.illustrations)
    }

    func test_illustrations_empty_list_becomes_nil() {
        let bundleDir = makeTempBundleDir()
        let config = makeConfig(illustrations: .init(
            files: [], cycleDuration: 8, transition: "crossfade"
        ))

        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)

        XCTAssertNil(palette.illustrations)
    }

    func test_cycleDuration_clamps_low() {
        let bundleDir = makeTempBundleDir(withFiles: ["a.gif"])
        let config = makeConfig(illustrations: .init(
            files: ["a.gif"], cycleDuration: 0.5, transition: "crossfade"
        ))
        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)
        XCTAssertEqual(palette.illustrations?.cycleDuration, 3.0)
    }

    func test_cycleDuration_clamps_high() {
        let bundleDir = makeTempBundleDir(withFiles: ["a.gif"])
        let config = makeConfig(illustrations: .init(
            files: ["a.gif"], cycleDuration: 120, transition: "crossfade"
        ))
        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)
        XCTAssertEqual(palette.illustrations?.cycleDuration, 60.0)
    }

    func test_cycleDuration_missing_defaults_to_8() {
        let bundleDir = makeTempBundleDir(withFiles: ["a.gif"])
        let config = makeConfig(illustrations: .init(
            files: ["a.gif"], cycleDuration: nil, transition: nil
        ))
        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)
        XCTAssertEqual(palette.illustrations?.cycleDuration, 8.0)
    }

    func test_transition_maps_known_values() {
        let bundleDir = makeTempBundleDir(withFiles: ["a.gif"])
        let combos: [(String, SettingsThemeIllustrations.Transition)] = [
            ("crossfade", .crossfade),
            ("slide", .slide),
            ("none", .none)
        ]
        for (input, expected) in combos {
            let config = makeConfig(illustrations: .init(
                files: ["a.gif"], cycleDuration: 8, transition: input
            ))
            let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)
            XCTAssertEqual(palette.illustrations?.transition, expected, "transition=\(input)")
        }
    }

    func test_transition_unknown_defaults_to_crossfade() {
        let bundleDir = makeTempBundleDir(withFiles: ["a.gif"])
        let config = makeConfig(illustrations: .init(
            files: ["a.gif"], cycleDuration: 8, transition: "wobble"
        ))
        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)
        XCTAssertEqual(palette.illustrations?.transition, .crossfade)
    }

    func test_transition_missing_defaults_to_crossfade() {
        let bundleDir = makeTempBundleDir(withFiles: ["a.gif"])
        let config = makeConfig(illustrations: .init(
            files: ["a.gif"], cycleDuration: 8, transition: nil
        ))
        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)
        XCTAssertEqual(palette.illustrations?.transition, .crossfade)
    }

    // MARK: - Icons ref(for:)

    func test_icons_ref_returns_correct_entry_per_tab() {
        let bundleDir = makeTempBundleDir()
        let config = makeConfig(icons: .init(
            general: "gearshape",
            appearance: "paintbrush.pointed.fill",
            notifications: nil, behavior: nil,
            plugins: nil, codelight: nil, advanced: nil
        ))
        let palette = SettingsThemePalette.from(config: config, bundleResourcesURL: bundleDir)

        XCTAssertEqual(palette.icons?.ref(for: .general), .sfSymbol("gearshape"))
        XCTAssertEqual(palette.icons?.ref(for: .appearance), .sfSymbol("paintbrush.pointed.fill"))
        XCTAssertNil(palette.icons?.ref(for: .notifications))
        XCTAssertNil(palette.icons?.ref(for: .cmuxConnection))  // not in schema
        XCTAssertNil(palette.icons?.ref(for: .logs))
        XCTAssertNil(palette.icons?.ref(for: .about))
    }
}

// MARK: - Equatable conformance for test assertions

extension IconRef: Equatable {
    public static func == (lhs: IconRef, rhs: IconRef) -> Bool {
        switch (lhs, rhs) {
        case (.sfSymbol(let a), .sfSymbol(let b)): return a == b
        case (.image(let a), .image(let b)): return a == b
        default: return false
        }
    }
}

extension SettingsThemeIllustrations.Transition: Equatable {}
