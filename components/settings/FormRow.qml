import QtQuick
import QtQuick.Layouts
import "../../theme"

// Base form row: label (+ optional description) on the left, the control on the
// right, and a hairline divider at the bottom. Control is the default child.
Item {
    id: row
    property string label: ""
    property string description: ""
    property bool divider: true
    // Optional settings key: when the platform cannot honour it, the row is
    // dimmed and explained instead of pretending to work (theme/Capabilities).
    property string settingKey: ""
    readonly property string supportNote: settingKey !== "" ? Capabilities.note(settingKey) : ""
    readonly property bool unsupported: supportNote !== ""

    onUnsupportedChanged: {
        for (let i = 0; i < holder.children.length; i++) {
            let c = holder.children[i];
            if (c && c.enabled !== undefined) c.enabled = !unsupported;
        }
    }
    default property alias control: holder.data

    Layout.fillWidth: true
    implicitHeight: Math.max(42, col.implicitHeight + 18)

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: holder.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            text: row.label
            color: row.unsupported ? Colors.textTertiary : Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.s13
            Layout.fillWidth: true
        }
        Text {
            text: row.description
            visible: row.description !== ""
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: Typography.s11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.maximumWidth: 360
        }
        Text {
            text: row.unsupported ? "Unavailable on Linux" : ""
            visible: row.unsupported
            color: Colors.systemOrange
            font.family: Typography.family
            font.pixelSize: Typography.s10
            Layout.fillWidth: true
            Layout.maximumWidth: 360
        }
    }

    Row {
        id: holder
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }

    Rectangle {
        visible: row.divider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
    }
}
