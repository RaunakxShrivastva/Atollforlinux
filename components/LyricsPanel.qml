import QtQuick
import QtQuick.Layouts
import "../theme"

// LyricsSidePanelView: the 280pt column beside the player while the calendar is
// hidden. A "Lyrics" header with the pin button, then the scrolling list.
Item {
    id: root

    property var lines: []
    property real duration: 0
    property string availability: "unavailable"
    property int currentIndex: -1
    property real sweepProgress: 0
    property string placeholder: "Show lyrics here"
    property string highlightStyle: "sweep"
    property color tint: Colors.accent
    property bool pinned: false

    signal pinToggled()

    // The expanded-player style: sung white, unsung the artist tint at 0.55,
    // idle white at 0.5.
    readonly property color sung: Colors.white
    readonly property color unsung: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.55)
    readonly property color idle: Qt.rgba(1, 1, 1, 0.5)

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        radius: Atoll.lyricsPanelRadius

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Atoll.lyricsPanelHeaderSide
                Layout.rightMargin: Atoll.lyricsPanelHeaderSide
                Layout.topMargin: Atoll.lyricsPanelHeaderTop
                Layout.bottomMargin: Atoll.lyricsPanelHeaderBottom
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: "Lyrics"
                    color: root.tint
                    font.family: Typography.family
                    font.pixelSize: Typography.s14
                    font.weight: Typography.semibold
                    elide: Text.ElideRight
                }

                Item {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20

                    SvgIcon {
                        anchors.centerIn: parent
                        iconName: root.pinned ? "pin.fill" : "pin"
                        color: root.pinned ? root.tint : Qt.rgba(1, 1, 1, 0.5)
                        implicitWidth: 11
                        implicitHeight: 11
                        rotation: root.pinned ? 0 : 45
                        Behavior on rotation { NumberAnimation { duration: Motion.fast } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pinToggled()
                    }
                }
            }

            SyncedLyricsList {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                lines: root.lines
                duration: root.duration
                availability: root.availability
                currentIndex: root.currentIndex
                sweepProgress: root.sweepProgress
                placeholder: root.placeholder
                highlightStyle: root.highlightStyle
                sung: root.sung
                unsung: root.unsung
                idle: root.idle
                tint: root.tint
                paddingH: 12
                paddingV: 4
                lineSpacing: Atoll.lyricsListLineSpacing
            }
        }
    }
}
