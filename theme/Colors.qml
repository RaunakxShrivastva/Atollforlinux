pragma Singleton
import QtQuick

// Design tokens extracted from the original Atoll SwiftUI source.
// Surfaces: Color.black.opacity(0.95) over .regularMaterial / .hudWindow blur.
// Overlays: Color.white.opacity(0.04 ... 0.2). Accents from Color+AccentColor.swift,
// MusicManager.swift and PrivacyLiveActivity.swift.
QtObject {
    // Base surfaces
    readonly property color black: "#000000"
    readonly property color white: "#ffffff"
    readonly property color panel: "#0b0b0d"
    readonly property color panelElevated: "#141417"

    // Hairlines & translucent overlays (white @ alpha)
    readonly property color fillSubtle: "#0affffff"   // 4%
    readonly property color fill: "#14ffffff"         // 8%
    readonly property color fillHover: "#1affffff"     // 10%
    readonly property color fillActive: "#26ffffff"    // 15%
    readonly property color hairline: "#1fffffff"      // 12%
    readonly property color hairlineStrong: "#33ffffff" // 20%

    // Text hierarchy
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#99ffffff" // 60%
    readonly property color textTertiary: "#59ffffff"  // 35%

    // Accents
    readonly property color accent: "#0a84ff"        // Color.blue (default effectiveAccent)
    readonly property color atollOrange: "#ff9402"    // brand #FF9402
    readonly property color mediaPink: "#ff2d55"      // appleMusicPink
    readonly property color spotifyGreen: "#00db4d"
    readonly property color amazonOrange: "#ff9900"
    readonly property color systemGreen: "#30d158"
    readonly property color systemRed: "#ff453a"
    readonly property color systemYellow: "#ffd60a"
    readonly property color systemPurple: "#bf5af2"
    readonly property color systemBlue: "#0a84ff"     // Color.blue (stats: CPU)
    readonly property color systemOrange: "#ff9500"   // Color.orange (stats: Network)
    readonly property color systemCyan: "#64d2ff"     // Color.cyan (stats: Disk)
    readonly property color cameraGreen: "#26cc41"    // #26CC41
    readonly property color batteryYellow: "#e1e1e1"  // #E1E1E1 neutral

    // Tracks (progress bars, rings)
    readonly property color track: "#2effffff"

    // Header: selected-tab capsule fill (Atoll: secondarySystemFill @ 0.25)
    readonly property color tabSelected: "#24ffffff"
    // Unselected header glyphs: macOS Atoll uses SwiftUI .gray.
    readonly property color tabIdle: "#8e8e93"
    readonly property color batteryOutline: "#80ffffff"

    // Shadow
    readonly property color shadow: "#99000000"

    // ---- Backwards-compatible aliases (legacy names used by existing views) ----
    readonly property color surfaceHover: fillHover
    readonly property color surfaceActive: fillActive
    readonly property color cardBackground: panel
    readonly property color cardBorder: hairline
    readonly property color notchBackground: black
    readonly property color notchBorder: hairline
    readonly property color shadowColor: shadow
    readonly property color purple: systemPurple
    readonly property color systemAccent: systemGreen
    readonly property color warning: systemYellow
    readonly property color error: systemRed
    readonly property color mediaAccent: mediaPink
}
