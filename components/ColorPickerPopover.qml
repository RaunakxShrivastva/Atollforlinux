import QtQuick
import QtQuick.Layouts
import "../theme"

// Colour-picker popover — the compact dropdown attached to the header's
// eyedropper button, ported from
// components/ColorPicker/ColorPickerPopover.swift (240 wide).
//
// Header, "Pick Color", "Show Color History", then a 6-column preview of the
// 12 newest colours (24px circles) that copy their hex on click.
Item {
    id: root

    property var service: null
    property int previewCount: 12

    signal pickRequested()
    signal showHistoryRequested()
    signal closeRequested()

    readonly property var preview: root.service
                                   ? root.service.history.slice(0, root.previewCount) : []

    implicitWidth: 240
    implicitHeight: content.implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.panel
        border.width: 1
        border.color: Colors.hairline

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                SvgIcon {
                    Layout.alignment: Qt.AlignVCenter
                    iconName: "eyedropper.halffull"
                    size: 14
                    color: Colors.textPrimary
                }
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: "Color Picker"
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.s14
                    font.weight: Typography.semibold
                    renderType: Text.QtRendering
                }
                Item { Layout.fillWidth: true }
                SvgIcon {
                    Layout.alignment: Qt.AlignVCenter
                    iconName: "xmark"
                    size: 12
                    color: Colors.textSecondary
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // Actions
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 8
                    color: pickMouse.containsMouse ? Qt.lighter(Colors.accent, 1.15) : Colors.accent
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        SvgIcon { iconName: "plus.circle.fill"; size: 14; color: Colors.white }
                        Text {
                            text: "Pick Color"
                            color: Colors.white
                            font.family: Typography.family
                            font.pixelSize: Typography.s14
                            font.weight: Typography.medium
                            renderType: Text.QtRendering
                        }
                    }
                    MouseArea {
                        id: pickMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pickRequested()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 8
                    color: histMouse.containsMouse ? Colors.fillActive : Colors.fill
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        SvgIcon { iconName: "rectangle.grid.2x2"; size: 14; color: Colors.textPrimary }
                        Text {
                            text: "Show Color History"
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.s14
                            font.weight: Typography.medium
                            renderType: Text.QtRendering
                        }
                    }
                    MouseArea {
                        id: histMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showHistoryRequested()
                    }
                }
            }

            // Recent colours preview
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.preview.length > 0

                Text {
                    text: "Recent Colors"
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.s12
                    font.weight: Typography.medium
                    renderType: Text.QtRendering
                }

                Grid {
                    columns: 6
                    spacing: 4
                    Repeater {
                        model: root.preview
                        delegate: Rectangle {
                            id: swatch
                            required property var modelData
                            width: 24
                            height: 24
                            radius: 12
                            color: root.service ? ColorFormats.colorOf(swatch.modelData) : Colors.fill
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.8)

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.service) root.service.copy(ColorFormats.toHex(swatch.modelData));
                                    root.closeRequested();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
