import QtQuick
import QtQuick.Layouts
import "../theme"

// Terminal tab (Developer > Terminal), ported from
// components/Notch/NotchTerminalView.swift.
//
// A real interactive shell: TerminalService keeps one PTY session alive, the
// input line feeds its stdin (Enter, arrows for shell history, Tab
// completion, Ctrl+C/D/L forwarded), and the console renders the streamed
// output with ANSI colours. Passwords and prompts work because the shell
// runs on a PTY, not a pipe. `service` is the TerminalService singleton.
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
        // Launcher for the real terminal, kept in the header where there is
        // always room (the chips row below used to push it past the edge).
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            visible: root.emulator !== ""
            implicitWidth: openLabel.implicitWidth + 16
            implicitHeight: 18
            radius: 5
            color: openMouse.containsMouse ? Qt.lighter(Colors.accent, 1.15) : Colors.accent
            Text {
                id: openLabel
                anchors.centerIn: parent
                text: "Open " + root.emulator
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
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.service) root.service.launch()
            }
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
                onClicked: if (root.service) root.service.restart()
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

    // Enter hands the line to the live shell (stdin), like a real terminal.
    function submitCommand() {
        var cmd = commandInput.text;
        commandInput.text = "";
        if (cmd.trim() === "") return;
        if (root.service) root.service.send(cmd);
    }

    // Typing into the notch needs the island to hold the keyboard
    // (shell.qml gates that on NotchContainer.wantsKeyboard).
    onVisibleChanged: if (visible) Qt.callLater(() => commandInput.forceActiveFocus())

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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // ---- input line: type here, Enter runs, Up/Down walk history ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "$"
                        color: Colors.accent
                        font.family: Typography.familyMono
                        font.pixelSize: Typography.s11
                        font.weight: Typography.medium
                        renderType: Text.QtRendering
                    }

                    TextEdit {
                        id: commandInput
                        Layout.fillWidth: true
                        color: Colors.textPrimary
                        font.family: Typography.familyMono
                        font.pixelSize: Typography.s11
                        renderType: Text.QtRendering
                        selectByMouse: true
                        wrapMode: TextEdit.NoWrap
                        // Keep an empty line's height stable so the row does
                        // not collapse when the field is blank.
                        Layout.preferredHeight: Math.max(font.pixelSize + 6, contentHeight)
                        Keys.onReturnPressed: event => root.submitCommand()
                        Keys.onEnterPressed: event => root.submitCommand()
                        // Arrows walk the SHELL's history (readline), not a
                        // local list - the session is the source of truth.
                        Keys.onUpPressed: event => {
                            if (root.service) root.service.writeRaw("\u001b[A");
                            event.accepted = true;
                        }
                        Keys.onDownPressed: event => {
                            if (root.service) root.service.writeRaw("\u001b[B");
                            event.accepted = true;
                        }
                        // Tab completion and the usual line-editing signals.
                        Keys.onTabPressed: event => {
                            if (root.service) root.service.writeRaw("\t");
                            event.accepted = true;
                        }
                        Keys.onPressed: event => {
                            if (!(event.modifiers & Qt.ControlModifier)) return;
                            var k = event.key;
                            if (k === Qt.Key_C) { root.service.writeRaw("\u0003"); event.accepted = true; }
                            else if (k === Qt.Key_D) { root.service.writeRaw("\u0004"); event.accepted = true; }
                            else if (k === Qt.Key_L) { root.service.writeRaw("\u000c"); event.accepted = true; }
                            else if (k === Qt.Key_U) { root.service.writeRaw("\u0015"); event.accepted = true; }
                            else if (k === Qt.Key_W) { root.service.writeRaw("\u0017"); event.accepted = true; }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Colors.hairline
                }

                Flickable {
                    id: consoleFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: transcript.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    // Follow the tail as output arrives, like a real terminal.
                    onContentHeightChanged: if (contentHeight > height) contentY = contentHeight - height

                    TextEdit {
                        id: transcript
                        width: consoleFlick.width
                        text: root.service && root.service.text !== ""
                              ? root.service.text
                              : root.shellName + "  (type a command below the line above; passwords and prompts work)"
                        color: Colors.textPrimary
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.WrapAnywhere
                        textFormat: TextEdit.RichText
                        font.family: Typography.familyMono
                        font.pixelSize: Typography.s11
                        renderType: Text.QtRendering
                    }
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
                        onClicked: if (root.service) root.service.send(String(chip.modelData))
                    }
                }
            }
        }
    }
}
