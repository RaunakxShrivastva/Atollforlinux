import QtQuick
import QtQuick.Layouts
import "../theme"

// Terminal tab (Developer > Terminal), ported from
// components/Notch/NotchTerminalView.swift.
//
// Atoll hosts a live shell in SwiftTerm; a Wayland layer surface cannot host a
// native window, so the header + guake-style role are kept and the body shows a
// working console for one-off commands plus a launcher for the real terminal.
// `service` is the TerminalService singleton.
ColumnLayout {
    id: root

    property var service: null
    property string shellName: "bash"

    // Passed in so the view (and the offscreen harness) need no singleton.
    property bool featureEnabled: true
    property var quickCommands: []
    property string emulator: ""

    spacing: 0
    anchors.fill: parent

    // ---- header ----
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.topMargin: 6
        Layout.bottomMargin: 4
        spacing: 6

        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            iconName: "apple.terminal"
            size: 11
            color: Colors.textPrimary
        }
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            text: root.service ? root.service.title : "Terminal"
            color: Colors.textPrimary
            elide: Text.ElideRight
            font.family: Typography.family
            font.pixelSize: Typography.s11
            font.weight: Typography.medium
            renderType: Text.QtRendering
        }
        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            iconName: "arrow.counterclockwise"
            size: 10
            color: restartMouse.containsMouse ? Colors.textPrimary : Colors.textSecondary
            MouseArea {
                id: restartMouse
                anchors.fill: parent
                anchors.margins: -5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.service) root.service.clear()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        implicitHeight: 1
        color: Colors.hairlineStrong
    }

    // ---- disabled placeholder (NotchTerminalView's else branch) ----
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !root.featureEnabled
        spacing: 8
        Item { Layout.fillHeight: true }
        SvgIcon {
            Layout.alignment: Qt.AlignHCenter
            iconName: "apple.terminal"
            size: 28
            color: Colors.textSecondary
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Terminal is disabled"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.s12
            font.weight: Typography.medium
            renderType: Text.QtRendering
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Enable it in Settings → Terminal"
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: Typography.s10
            renderType: Text.QtRendering
        }
        Item { Layout.fillHeight: true }
    }

    // ---- console ----
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 8
        Layout.topMargin: 6
        visible: root.featureEnabled
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: Colors.black
            border.width: 1
            border.color: Colors.hairline
            clip: true

            Flickable {
                id: console
                anchors.fill: parent
                anchors.margins: 8
                contentWidth: width
                contentHeight: transcript.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                // Follow the tail as output arrives, like a real terminal.
                onContentHeightChanged: if (contentHeight > height) contentY = contentHeight - height

                TextEdit {
                    id: transcript
                    width: console.width
                    text: root.service && root.service.output !== ""
                          ? root.service.output
                          : "$ " + root.shellName + "  (press Run, or open a real terminal)"
                    color: root.service && root.service.output !== ""
                           ? Colors.textPrimary : Colors.textTertiary
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    textFormat: TextEdit.PlainText
                    font.family: Typography.familyMono
                    font.pixelSize: Typography.s11
                    renderType: Text.QtRendering
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.quickCommands
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    implicitWidth: chipLabel.implicitWidth + 16
                    implicitHeight: 20
                    radius: 6
                    color: chipMouse.containsMouse ? Colors.fillHover : Colors.fill
                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: String(chip.modelData)
                        color: Colors.textSecondary
                        font.family: Typography.familyMono
                        font.pixelSize: Typography.s10
                        renderType: Text.QtRendering
                    }
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.service) root.service.run(String(chip.modelData))
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: openLabel.implicitWidth + 20
                implicitHeight: 20
                radius: 6
                color: openMouse.containsMouse ? Qt.lighter(Colors.accent, 1.15) : Colors.accent
                Text {
                    id: openLabel
                    anchors.centerIn: parent
                    text: root.emulator === "" ? "No terminal found" : "Open " + root.emulator
                    color: Colors.white
                    font.family: Typography.family
                    font.pixelSize: Typography.s10
                    font.weight: Typography.medium
                    renderType: Text.QtRendering
                }
                MouseArea {
                    id: openMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.emulator !== ""
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.service) root.service.launch()
                }
            }
        }
    }
}
