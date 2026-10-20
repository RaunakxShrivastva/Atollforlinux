import QtQuick
import QtQuick.Effects
import "../theme"

// One lyric line, drawn with the configured highlight style.
//
// Ported from Atoll's LyricSweep.swift (gradient / solid / sweep) and
// SweptLyricText. The sweep reveals the sung colour from the left while the
// unsung remainder trails behind it; gradient paints a fixed tint -> sung ->
// tint gradient for the whole time the line is current; solid lights the line
// in one flat colour.
Item {
    id: root

    property string text: ""
    property bool isCurrent: false
    property real progress: 0.0

    property string highlightStyle: "sweep" // sweep | gradient | solid
    property color sung: Colors.white
    property color unsung: "#9a9a9a"
    property color idle: Qt.rgba(1, 1, 1, 0.5)
    property color tint: Colors.accent

    property real fontSize: Atoll.lyricsListFontSize
    property int fontWeight: isCurrent ? Typography.semibold : Typography.regular
    property int lineLimit: Atoll.lyricsListLineLimit
    property bool alignCenter: false

    readonly property bool sweeping: isCurrent && highlightStyle === "sweep"
    readonly property bool gradient: isCurrent && highlightStyle === "gradient"

    implicitHeight: base.contentHeight
    implicitWidth: base.contentWidth

    Text {
        id: base
        width: root.width
        text: root.text
        color: root.isCurrent
            ? (root.highlightStyle === "solid" ? root.sung
               : root.highlightStyle === "gradient" ? "transparent" : root.unsung)
            : root.idle
        font.family: Typography.family
        font.pixelSize: root.fontSize
        font.weight: root.fontWeight
        wrapMode: Text.WordWrap
        maximumLineCount: root.lineLimit
        elide: Text.ElideRight
        horizontalAlignment: root.alignCenter ? Text.AlignHCenter : Text.AlignLeft
        renderType: Text.QtRendering
    }

    // Sweep: a full copy in the sung colour, clipped to the progress. The clip
    // starts where the glyphs do, so a centred line still sweeps from its own
    // first letter rather than from the edge of the frame.
    readonly property real glyphStart: root.alignCenter
        ? Math.max(0, (root.width - base.paintedWidth) / 2) : 0

    Item {
        x: root.glyphStart
        width: root.sweeping
            ? Math.max(0, base.paintedWidth * Math.min(1, Math.max(0, root.progress))) : 0
        height: base.contentHeight
        clip: true
        visible: root.sweeping

        Text {
            x: -root.glyphStart
            width: root.width
            text: root.text
            color: root.sung
            font: base.font
            wrapMode: Text.WordWrap
            maximumLineCount: root.lineLimit
            elide: Text.ElideRight
            horizontalAlignment: base.horizontalAlignment
            renderType: Text.QtRendering
        }
    }

    // Gradient: a tint -> sung -> tint fill, masked to the glyphs. The mask is
    // sampled from the text's alpha channel through a ShaderEffectSource; a
    // plain Text as maskSource renders nothing.
    Text {
        id: gradientMask
        x: 0
        width: root.width
        text: root.text
        color: "black"
        font: base.font
        wrapMode: Text.WordWrap
        maximumLineCount: root.lineLimit
        elide: Text.ElideRight
        horizontalAlignment: base.horizontalAlignment
        renderType: Text.QtRendering
        visible: false
    }

    ShaderEffectSource {
        id: gradientTexture
        sourceItem: gradientMask
        hideSource: true
        live: true
        format: ShaderEffectSource.Alpha
    }

    Rectangle {
        id: gradientFill
        x: 0
        y: 0
        width: base.contentWidth
        height: base.contentHeight
        visible: false
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.tint }
            GradientStop { position: 0.5; color: root.sung }
            GradientStop { position: 1.0; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.82) }
        }
    }

    MultiEffect {
        anchors.fill: parent
        visible: root.gradient
        source: gradientFill
        maskEnabled: true
        maskSource: gradientTexture
    }
}
