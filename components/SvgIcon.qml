import QtQuick
import QtQuick.Effects
import "../theme"

// Vector icon rendered from Material Symbols Rounded — the closest Linux
// stand-in for macOS SF Symbols.
//
// The font is the *variable* build (FILL, GRAD, opsz, wght axes; see
// /usr/share/fonts/TTF/MaterialSymbolsRounded[...].ttf), so we drive the axes
// directly instead of hoping a static instance looks right:
//   FILL  -> 1 for SF's .fill symbols (Atoll uses the solid variants almost
//            everywhere), 0 for the outlined ones;
//   opsz  -> the rendered pixel size, which is how SF Symbols optical sizing
//            works too (stems thin out as the glyph grows);
//   wght  -> Atoll renders most chrome at .medium/.semibold.
Item {
    id: root

    property string iconName: "music"
    property color color: Colors.textPrimary
    property real size: Math.max(implicitWidth, implicitHeight)
    // Solid vs outlined. Defaults to the SF symbol's own variant.
    property bool fill: Icons.filled(iconName)
    // SF Symbols chrome reads as a medium-weight glyph; 400 looks thin next to
    // the solid .fill shapes.
    property int weight: 500
    property real grade: 0
    property int fontPixelOverride: 0

    implicitWidth: 16
    implicitHeight: 16

    readonly property string glyph: Icons.glyph(root.iconName)
    // Material Symbols leave noticeably more padding inside the em box than SF
    // Symbols (measured: ink/em ~0.86 for Material vs ~1.1 for SF at the same
    // nominal size), which is why same-size glyphs looked small and "cheap".
    // `size` is therefore the *ink* target; the font is scaled to hit it.
    readonly property real inkScale: 1.28
    readonly property int fontPixel: root.fontPixelOverride > 0 ? root.fontPixelOverride
                                                                  : Math.max(1, Math.round(root.size * inkScale))

    // A custom white-on-transparent asset (Icons.assetMap) instead of a font
    // glyph. MultiEffect colorization is what tints it; that only works because
    // the asset is white (a black SVG stays black).
    readonly property string assetPath: Icons.asset(root.iconName)

    Image {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        visible: root.assetPath !== ""
        source: root.assetPath !== "" ? Qt.resolvedUrl("../" + root.assetPath) : ""
        sourceSize.width: 256
        sourceSize.height: 256
        fillMode: Image.PreserveAspectFit
        smooth: true
        layer.enabled: root.assetPath !== ""
        layer.effect: MultiEffect {
            colorizationColor: root.color
            colorization: 1.0
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.glyph !== "" && root.assetPath === ""
        text: root.glyph
        color: root.color
        textFormat: Text.PlainText
        renderType: Text.QtRendering
        font.family: Typography.iconFamily
        font.pixelSize: root.fontPixel
        font.hintingPreference: Font.PreferNoHinting
        font.variableAxes: ({
            "FILL": root.fill ? 1 : 0,
            "GRAD": root.grade,
            "opsz": root.fontPixel,
            "wght": root.weight
        })
    }
}
