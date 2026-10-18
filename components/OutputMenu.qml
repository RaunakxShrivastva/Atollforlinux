import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

// Audio output picker (Appearance/Devices > "Media output control"). Lists the
// PipeWire sinks; the active one is ticked. Backed by AudioService.
Popup {
    id: root

    property var sinks: []
    property string current: ""
    signal picked(string sinkName)

    width: 260
    padding: 8
    modal: false
    focus: true

    background: Rectangle {
        radius: 14
        color: "#1b1b1f"
        border.color: Colors.hairlineStrong
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: 2

        Text {
            Layout.leftMargin: 6
            Layout.topMargin: 2
            text: "Output"
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: Typography.s11
            font.weight: Typography.semibold
        }

        Repeater {
            model: root.sinks

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 8
                color: rowMouse.containsMouse ? Colors.surfaceHover : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 8

                    SvgIcon {
                        iconName: "hifispeaker"
                        color: modelData.name === root.current ? Colors.white : Colors.textSecondary
                        implicitWidth: 14
                        implicitHeight: 14
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.desc && modelData.desc !== "" ? modelData.desc : modelData.name
                        color: modelData.name === root.current ? Colors.white : Colors.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.s12
                        elide: Text.ElideRight
                    }
                    SvgIcon {
                        visible: modelData.name === root.current
                        iconName: "checkmark"
                        color: Colors.white
                        implicitWidth: 12
                        implicitHeight: 12
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.picked(modelData.name); root.close(); }
                }
            }
        }

        Text {
            Layout.leftMargin: 6
            Layout.bottomMargin: 2
            visible: root.sinks.length === 0
            text: "No sinks found"
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: Typography.s12
        }
    }
}
