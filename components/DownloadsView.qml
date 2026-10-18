import QtQuick
import QtQuick.Layouts
import "../theme"

// Shelf / Downloads tab: the newest files in the downloads folder, newest first.
ColumnLayout {
    id: root

    property var entries: []
    property string folder: ""
    signal openRequested(string path)
    signal openFolder()

    anchors.fill: parent
    anchors.margins: 4
    spacing: 5

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 8

        Text {
            Layout.fillWidth: true
            text: "Downloads"
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.s12
            font.weight: Typography.semibold
        }
        Text {
            text: "Open folder"
            color: Colors.accent
            font.family: Typography.family
            font.pixelSize: Typography.s11
            font.weight: Typography.medium
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.openFolder() }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        visible: root.entries.length === 0
        text: "No recent downloads"
        color: Colors.textTertiary
        font.family: Typography.family
        font.pixelSize: Typography.s12
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        clip: true
        spacing: 1
        model: root.entries
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row
            required property var modelData
            width: ListView.view.width
            height: 30
            radius: Metrics.r8
            color: rowMouse.containsMouse ? Colors.fillHover : "transparent"

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openRequested(row.modelData.path)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                SvgIcon {
                    Layout.alignment: Qt.AlignVCenter
                    iconName: "arrow.down.circle"
                    color: Colors.accent
                    implicitWidth: 14
                    implicitHeight: 14
                }
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: row.modelData.name
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.s12
                    elide: Text.ElideMiddle
                    renderType: Text.QtRendering
                }
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.sizeBytes(row.modelData.size)
                    color: Colors.textTertiary
                    font.family: Typography.family
                    font.pixelSize: Typography.s11
                    renderType: Text.QtRendering
                }
            }
        }
    }

    function sizeBytes(bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1048576) return (bytes / 1024).toFixed(0) + " KB";
        if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
        return (bytes / 1073741824).toFixed(2) + " GB";
    }
}
