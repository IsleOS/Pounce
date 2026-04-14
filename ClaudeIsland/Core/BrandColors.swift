//
//  BrandColors.swift
//  ClaudeIsland
//
//  Shared brand color constants referenced by both the notch-side views
//  and the settings theme palette. Centralizes hex literals that were
//  previously duplicated across NotchMenuView, PairPhoneView,
//  NotchCustomizationSettingsView, NativePluginStoreView, and the
//  SystemSettingsView Theme enum.
//

import SwiftUI

enum BrandColors {
    /// Brand lime #CAFF00 — the primary brand accent.
    static let lime = Color(red: 0xCA / 255, green: 0xFF / 255, blue: 0x00 / 255)
}
