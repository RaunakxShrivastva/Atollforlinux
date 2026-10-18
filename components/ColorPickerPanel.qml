import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

// Colour-picker panel — floating window near the notch, ported from
// components/ColorPicker/ColorPickerPanel.swift (450x600).
//
//   header  | close, eyedropper + "Color Picker", Pick Color, clear-all trash
//           | search field
//   body    | left: "Recent Colors" list (swatch, hex, age, hover copy/delete)
//           | right: "Color Details" (big swatch + every format, click to copy)
//
// `service` is the ColorPickerService instance owned by the shell.
Item {
    id: root

    property var service: null
    property string searchText: ""
    property var selected: null
    // Utilities > Color Picker > "Show all colour formats".
    property bool showAllFormats: true

    signal pickRequested()
    signal closeRequested()

    readonly property var colors: {
        var list = root.service ? root.service.history : [];
        var q = root.searchText.trim().toLowerCase();
        if (q === "") return list;
        return list.filter(function (c) {
            return ColorFormats.toHex(c).toLowerCase().indexOf(q) >= 0
                || ColorFormats.toRgb(c).toLowerCase().indexOf(q) >= 0;
        });
    }

    // Keep the selection valid as the history changes.
    onColorsChanged: {
        if (root.selected === null) return;
        var found = null;
        for (var i = 0; i < root.colors.length; i++)
            if (root.colors[i].id === root.selected.id) found = root.colors[i];
        root.selected = found;
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.panel
        border.width: 1
        border.color: Colors.hairline

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ---- header ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Close (NativeStyleCloseButton)
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 18
                        height: 18
                        radius: 9
                        color: closeMouse.containsMouse ? Colors.systemRed : Colors.fillActive

                        SvgIcon {
                            anchors.centerIn: parent
                            iconName: "xmark"
                            size: 9
                            color: closeMouse.containsMouse ? Colors.white : Colors.textSecondary
                        }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                    }

                    SvgIcon {
                        Layout.alignment: Qt.AlignVCenter
                        iconName: "eyedropper.halffull"
                        size: 16
                        color: Colors.textPrimary
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "Color Picker"
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.s16
                        font.weight: Typography.semibold
                        renderType: Text.QtRendering
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: pickRow.implicitWidth + 24
                        implicitHeight: pickRow.implicitHeight + 12
                        radius: 8
                        color: pickMouse.containsMouse ? Qt.lighter(Colors.accent, 1.15) : Colors.accent

                        RowLayout {
                            id: pickRow
                            anchors.centerIn: parent
                            spacing: 6
                            SvgIcon {
                                iconName: "plus.circle.fill"
                                size: 14
                                color: Colors.white
                            }
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

                    SvgIcon {
                        Layout.alignment: Qt.AlignVCenter
                        iconName: "trash"
                        size: 14
                        color: root.colors.length === 0 ? Colors.textTertiary : Colors.systemRed
                        opacity: root.colors.length === 0 ? 0.5 : 1
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            enabled: root.colors.length > 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.service) root.service.clearHistory()
                        }
                    }
                }

                // Search bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 8
                    color: Colors.fillSubtle

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        SvgIcon {
                            iconName: "magnifyingglass"
                            size: 14
                            color: Colors.textSecondary
                        }
                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Search colors..."
                            placeholderTextColor: Colors.textTertiary
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.s14
                            background: null
                            selectByMouse: true
                            onTextChanged: root.searchText = text
                        }
                        SvgIcon {
                            iconName: "xmark.circle.fill"
                            size: 12
                            color: Colors.textSecondary
                            visible: searchField.text !== ""
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchField.text = ""
                            }
                        }
                    }
                }
            }

            // ---- body: list | details ----
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Left: recent colours
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 210
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        color: Colors.fillSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            Text {
                                text: "Recent Colors"
                                color: Colors.textPrimary
                                font.family: Typography.family
                                font.pixelSize: Typography.s14
                                font.weight: Typography.semibold
                                renderType: Text.QtRendering
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                implicitWidth: countLabel.implicitWidth + 12
                                implicitHeight: countLabel.implicitHeight + 4
                                radius: 4
                                color: Colors.fill
                                Text {
                                    id: countLabel
                                    anchors.centerIn: parent
                                    text: String(root.colors.length)
                                    color: Colors.textSecondary
                                    font.family: Typography.family
                                    font.pixelSize: Typography.s12
                                    font.weight: Typography.medium
                                    renderType: Text.QtRendering
                                }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colors.hairlineStrong
                    }

                    // Empty state
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.colors.length === 0
                        spacing: 8

                        Item { Layout.fillHeight: true }
                        SvgIcon {
                            Layout.alignment: Qt.AlignHCenter
                            iconName: "eyedropper"
                            size: 32
                            color: Colors.textSecondary
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No Colors Found"
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.s16
                            font.weight: Typography.medium
                            renderType: Text.QtRendering
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 160
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: root.searchText === ""
                                  ? "Start picking colors to build your history"
                                  : "No colors match '" + root.searchText + "'"
                            color: Colors.textSecondary
                            font.family: Typography.family
                            font.pixelSize: Typography.s12
                            renderType: Text.QtRendering
                        }
                        Item { Layout.fillHeight: true }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.colors.length > 0
                        clip: true
                        model: root.colors
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 0

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            height: 48
                            color: (root.selected && root.selected.id === row.modelData.id)
                                   ? Qt.rgba(0.04, 0.52, 1.0, 0.20)
                                   : (rowMouse.containsMouse ? Colors.fillHover : "transparent")

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.selected = row.modelData
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: root.service ? ColorFormats.colorOf(row.modelData) : Colors.fill
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.8)
                                }
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2
                                    Text {
                                        text: root.service ? ColorFormats.toHex(row.modelData) : ""
                                        color: Colors.textPrimary
                                        font.family: Typography.familyMono
                                        font.pixelSize: Typography.s14
                                        font.weight: Typography.medium
                                        renderType: Text.QtRendering
                                    }
                                    Text {
                                        text: root.service ? ColorFormats.timeAgo(row.modelData.timestamp) : ""
                                        color: Colors.textSecondary
                                        font.family: Typography.family
                                        font.pixelSize: Typography.s12
                                        renderType: Text.QtRendering
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                RowLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 4
                                    visible: rowMouse.containsMouse
                                    SvgIcon {
                                        iconName: "doc.on.doc"
                                        size: 12
                                        color: Colors.accent
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -5
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (root.service) root.service.copy(ColorFormats.toHex(row.modelData))
                                        }
                                    }
                                    SvgIcon {
                                        iconName: "trash"
                                        size: 12
                                        color: Colors.systemRed
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -5
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (root.service) root.service.removeColor(row.modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Colors.hairlineStrong }

                // Right: colour details
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 240
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        color: Colors.fillSubtle
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Color Details"
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.s14
                            font.weight: Typography.semibold
                            renderType: Text.QtRendering
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colors.hairlineStrong
                    }

                    // No selection
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.selected === null
                        spacing: 16
                        Item { Layout.fillHeight: true }
                        SvgIcon {
                            Layout.alignment: Qt.AlignHCenter
                            iconName: "hand.point.up.left"
                            size: 32
                            color: Colors.textSecondary
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 180
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: "Select a color to view details"
                            color: Colors.textSecondary
                            font.family: Typography.family
                            font.pixelSize: Typography.s14
                            renderType: Text.QtRendering
                        }
                        Item { Layout.fillHeight: true }
                    }

                    // Selected: large swatch + format rows
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.selected !== null
                        spacing: 0

                        Flickable {
                            id: detailsFlick
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: details.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: details
                                width: detailsFlick.width
                                spacing: 16

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    Layout.topMargin: 16
                                    implicitHeight: 80
                                    radius: 8
                                    color: root.service && root.selected ? ColorFormats.colorOf(root.selected) : Colors.fill
                                    border.width: 1
                                    border.color: Colors.hairline
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 16
                                    Layout.rightMargin: 16
                                    Layout.bottomMargin: 16
                                    spacing: 6

                                    Repeater {
                                        model: root.service && root.selected
                                               ? (root.showAllFormats
                                                  ? ColorFormats.formatsFor(root.selected)
                                                  : ColorFormats.formatsFor(root.selected).slice(0, 1))
                                               : []
                                        delegate: Rectangle {
                                            id: fmtRow
                                            required property var modelData
                                            Layout.fillWidth: true
                                            implicitHeight: 26
                                            radius: 6
                                            color: fmtMouse.containsMouse ? Colors.fillHover : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 8
                                                Text {
                                                    Layout.preferredWidth: 40
                                                    Layout.alignment: Qt.AlignLeft
                                                    text: fmtRow.modelData.name
                                                    color: Colors.textSecondary
                                                    font.family: Typography.familyMono
                                                    font.pixelSize: Typography.s10
                                                    font.weight: Typography.medium
                                                    renderType: Text.QtRendering
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: fmtRow.modelData.value
                                                    color: Colors.textPrimary
                                                    elide: Text.ElideMiddle
                                                    font.family: Typography.familyMono
                                                    font.pixelSize: Typography.s10
                                                    renderType: Text.QtRendering
                                                }
                                                SvgIcon {
                                                    visible: fmtMouse.containsMouse
                                                    iconName: "doc.on.doc"
                                                    size: 11
                                                    color: Colors.accent
                                                }
                                            }
                                            MouseArea {
                                                id: fmtMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: if (root.service) root.service.copy(fmtRow.modelData.value)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
