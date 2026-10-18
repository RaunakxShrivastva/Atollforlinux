pragma Singleton
import QtQuick

// Atoll uses SF Pro (sizes 9-32, weights medium/semibold/bold, .rounded and
// .monospaced designs). On Linux the closest neutral match is Inter / Inter
// Display (installed); timers fall back to a monospaced face.
QtObject {
    readonly property string family: "Inter"
    readonly property string familyDisplay: "Inter Display"
    readonly property string familyMono: "FiraCode Nerd Font Mono"
    readonly property string iconFamily: "Material Symbols Rounded"
    // Atoll's header/labels use ".system(..., design: .rounded)". SF Rounded has
    // no Linux equivalent; Nunito is bundled (see components/AtollFonts.qml).
    readonly property string familyRounded: "Nunito"

    // Sizes: 9, 10, 11, 12, 13, 14, 16, 18, 20, 32
    readonly property int s9: 9
    readonly property int s10: 10
    readonly property int s11: 11
    readonly property int s12: 12
    readonly property int s13: 13
    readonly property int s14: 14
    readonly property int s16: 16
    readonly property int s18: 18
    readonly property int s20: 20
    readonly property int s32: 32

    // Weights
    readonly property int regular: Font.Normal    // 400
    readonly property int medium: Font.Medium     // 500
    readonly property int semibold: Font.DemiBold // 600
    readonly property int bold: Font.Bold         // 700

    // Optical tracking (letterSpacing, px)
    readonly property real trackTight: -0.2
    readonly property real trackNormal: 0.0
    readonly property real trackWide: 0.3

    // ---- Backwards-compatible aliases (legacy names) ----
    readonly property string fontFamily: family
    readonly property int sizeSmall: s10
    readonly property int sizePill: s12
    readonly property int sizeBody: s13
    readonly property int sizeTitle: s14
    readonly property int sizeHeader: s18
    readonly property int sizeLarge: s20
    readonly property int weightNormal: regular
    readonly property int weightMedium: medium
    readonly property int weightSemibold: semibold
    readonly property int weightBold: bold
}
