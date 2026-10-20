import QtQuick
import QtQuick.Layouts
import "../theme"

// The strip of lyric lines kept under the closed notch when
// "Pin lyrics when closed" is on (PinnedLyricsView). Shows one, three or five
// fixed slots around the current line; missing neighbours stay blank.
ColumnLayout {
    id: root

    property var slots: []
    property real sweepProgress: 0
    property string highlightStyle: "sweep"
    // The pinned modifier's own palette: sung white, unsung the player tint at
    // 0.55, idle white at 0.45.
    property color tint: Colors.accent
    property color sung: Colors.white
    property color unsung: Qt.rgba(tint.r, tint.g, tint.b, 0.55)
    property color idle: Qt.rgba(1, 1, 1, 0.45)

    spacing: 0

    Repeater {
        model: root.slots

        delegate: LyricLine {
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: Atoll.pinnedLyricsRowHeight
            Layout.leftMargin: Atoll.pinnedLyricsPaddingH
            Layout.rightMargin: Atoll.pinnedLyricsPaddingH
            text: modelData.text
            isCurrent: modelData.isCurrent === true
            progress: root.sweepProgress
            highlightStyle: modelData.isCurrent ? root.highlightStyle : "solid"
            sung: root.sung
            unsung: root.unsung
            idle: root.idle
            tint: root.tint
            fontSize: Atoll.pinnedLyricsFontSize
            fontWeight: Typography.medium
            lineLimit: 1
            alignCenter: true
            // Keep height-only: a lyric row must never claim width from the
            // closed notch's stack.
            implicitWidth: 0
        }
    }
}
