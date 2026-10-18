import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

// Notes pane (Productivity > Notes). Mirrors Atoll's NoteListView / NoteRow:
// a "Notes" heading with circular actions (create from clipboard, clear, new),
// a list of note cards (coloured accent bar, pinned glyph, title, 2-line body
// preview, hover-revealed pin/copy/delete), and an inline editor.
Item {
    id: root

    // [{ id, title, body, pinned, colorIndex, created }]
    property var notes: []

    signal noteAdded(string title, string body)
    signal noteUpdated(string id, string title, string body)
    signal noteRemoved(string id)
    signal notePinned(string id)
    signal allCleared()

    // Atoll's note palette (Defaults.colors).
    readonly property var palette: [
        Colors.systemYellow, Colors.systemBlue, Colors.systemRed,
        Colors.systemGreen, Colors.systemPurple, Colors.systemOrange
    ]
    function colorFor(index) {
        var i = Number(index);
        if (!isFinite(i) || i < 0) i = 0;
        return palette[i % palette.length];
    }

    property string editingId: ""
    property bool editingNew: false
    property string draftTitle: ""
    property string draftBody: ""

    // Pinned first, then newest (Atoll's NoteListView ordering).
    readonly property var ordered: {
        var list = (notes || []).slice();
        list.sort(function (a, b) {
            if (!!a.pinned !== !!b.pinned) return a.pinned ? -1 : 1;
            return (Number(b.created) || 0) - (Number(a.created) || 0);
        });
        return list;
    }

    function startNew() {
        editingNew = true;
        editingId = "";
        draftTitle = "";
        draftBody = "";
        titleField.forceActiveFocus();
    }

    function startEdit(note) {
        editingNew = false;
        editingId = note.id;
        draftTitle = note.title || "";
        draftBody = note.body || "";
        titleField.forceActiveFocus();
    }

    function commitEdit() {
        if (editingNew) root.noteAdded(draftTitle, draftBody);
        else if (editingId !== "") root.noteUpdated(editingId, draftTitle, draftBody);
        editingId = "";
        editingNew = false;
    }

    function cancelEdit() {
        editingId = "";
        editingNew = false;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ---- Heading ----
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 8
            spacing: 6

            Text {
                text: root.editingNew || root.editingId !== "" ? "Edit Note" : "Notes"
                color: Colors.white
                font.family: Typography.familyDisplay
                font.pixelSize: Typography.s16
                font.weight: Typography.semibold
            }
            Item { Layout.fillWidth: true }

            // Back (editor only)
            CircleButton {
                visible: root.editingNew || root.editingId !== ""
                iconName: "chevron.left"
                onClicked: root.cancelEdit()
            }
            // Create from Clipboard
            CircleButton {
                visible: !root.editingNew && root.editingId === ""
                iconName: "doc.on.clipboard"
                onClicked: pasteProc.running = true
            }
            // Clear all
            CircleButton {
                visible: !root.editingNew && root.editingId === "" && root.notes.length > 0
                iconName: "trash"
                iconColor: Colors.systemRed
                onClicked: root.allCleared()
            }
            // New / Save
            CircleButton {
                visible: !root.editingNew && root.editingId === ""
                iconName: "plus"
                onClicked: root.startNew()
            }
            CircleButton {
                visible: root.editingNew || root.editingId !== ""
                iconName: "checkmark"
                iconColor: Colors.systemGreen
                onClicked: root.commitEdit()
            }
        }

        // ---- Editor ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12
            visible: root.editingNew || root.editingId !== ""
            spacing: 6

            TextField {
                id: titleField
                Layout.fillWidth: true
                text: root.draftTitle
                placeholderText: "Title"
                color: Colors.white
                placeholderTextColor: Colors.textTertiary
                selectByMouse: true
                background: Rectangle {
                    radius: Metrics.r8
                    color: Colors.fillSubtle
                    border.color: Colors.hairline
                    border.width: 1
                }
                font.family: Typography.familyDisplay
                font.pixelSize: Typography.s14
                font.weight: Typography.semibold
                leftPadding: 10
                onTextChanged: root.draftTitle = text
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Metrics.r8
                color: Colors.fillSubtle
                border.color: Colors.hairline
                border.width: 1
                clip: true

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 6

                    TextArea {
                        id: bodyField
                        text: root.draftBody
                        placeholderText: "Write a note\u2026"
                        wrapMode: TextArea.Wrap
                        color: Colors.textPrimary
                        placeholderTextColor: Colors.textTertiary
                        selectByMouse: true
                        background: null
                        font.family: Typography.family
                        font.pixelSize: Typography.s13
                        onTextChanged: root.draftBody = text
                    }
                }
            }
        }

        // ---- List ----
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12
            visible: !root.editingNew && root.editingId === ""
            clip: true
            contentHeight: listColumn.height
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: listColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.ordered

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        radius: 12
                        color: cardMouse.containsMouse ? Colors.fillHover : Colors.fill
                        border.color: Qt.rgba(root.colorFor(card.modelData.colorIndex).r,
                                              root.colorFor(card.modelData.colorIndex).g,
                                              root.colorFor(card.modelData.colorIndex).b, 0.25)
                        border.width: 1
                        clip: true
                        Behavior on color { ColorAnimation { duration: Motion.instant } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: cardMouse.containsMouse ? 104 : 10
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            spacing: 10

                            // Colour accent bar.
                            Rectangle {
                                Layout.preferredWidth: 4
                                Layout.fillHeight: true
                                radius: 2
                                color: root.colorFor(card.modelData.colorIndex)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    SvgIcon {
                                        visible: card.modelData.pinned === true
                                        iconName: "pin.fill"
                                        color: root.colorFor(card.modelData.colorIndex)
                                        implicitWidth: 10
                                        implicitHeight: 10
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: card.modelData.title && card.modelData.title.length > 0
                                              ? card.modelData.title : "New Note"
                                        color: Colors.white
                                        font.family: Typography.familyDisplay
                                        font.pixelSize: Typography.s13
                                        font.weight: Typography.semibold
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: card.modelData.body && card.modelData.body.length > 0
                                          ? card.modelData.body : "No content"
                                    color: card.modelData.body ? Qt.rgba(1, 1, 1, 0.7) : Colors.textTertiary
                                    font.family: Typography.family
                                    font.pixelSize: Typography.s11
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    verticalAlignment: Text.AlignTop
                                }
                            }
                        }

                        // Hover actions: pin / copy / delete, in a pill capsule.
                        Rectangle {
                            visible: cardMouse.containsMouse
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: actionsRow.width + 8
                            height: 30
                            radius: 15
                            color: Colors.fill

                            RowLayout {
                                id: actionsRow
                                anchors.centerIn: parent
                                spacing: 4

                                CircleButton {
                                    compact: true
                                    iconName: card.modelData.pinned === true ? "pin.slash.fill" : "pin.fill"
                                    onClicked: root.notePinned(card.modelData.id)
                                }
                                CircleButton {
                                    compact: true
                                    iconName: "doc.on.doc"
                                    onClicked: copyProc.push(card.modelData.body || "")
                                }
                                CircleButton {
                                    compact: true
                                    iconName: "trash"
                                    iconColor: Colors.systemRed
                                    onClicked: root.noteRemoved(card.modelData.id)
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startEdit(card.modelData)
                        }
                    }
                }

                // Empty state.
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 18
                    visible: root.notes.length === 0
                    spacing: 6

                    SvgIcon {
                        Layout.alignment: Qt.AlignHCenter
                        iconName: "note.text"
                        color: Colors.textTertiary
                        implicitWidth: 28
                        implicitHeight: 28
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No notes yet"
                        color: Colors.textSecondary
                        font.family: Typography.familyDisplay
                        font.pixelSize: Typography.s14
                        font.weight: Typography.semibold
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Tap + to write one"
                        color: Colors.textTertiary
                        font.family: Typography.family
                        font.pixelSize: Typography.s11
                    }
                }
            }
        }
    }

    // ---- Circular header/action button (HoverButton in the Swift source) ----
    component CircleButton: Rectangle {
        id: button
        property string iconName: ""
        property color iconColor: Colors.white
        property bool compact: false
        signal clicked()

        implicitWidth: compact ? 22 : 26
        implicitHeight: compact ? 22 : 26
        radius: width / 2
        color: bMouse.containsMouse || bMouse.pressed ? Colors.fillHover : Colors.fillSubtle
        Behavior on color { ColorAnimation { duration: Motion.instant } }
        visible: true

        SvgIcon {
            anchors.centerIn: parent
            iconName: button.iconName
            color: button.iconColor
            implicitWidth: button.compact ? 12 : 14
            implicitHeight: button.compact ? 12 : 14
            scale: bMouse.pressed ? 0.9 : 1.0
            Behavior on scale { NumberAnimation { duration: Motion.instant; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: bMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    // Copy note text to the Wayland clipboard (argv form: no shell quoting).
    property Process copyProc: Process {
        id: copyProcess
        property string pending: ""
        function push(text) {
            var t = String(text || "");
            if (t === "") return;
            pending = t;
            running = true;
        }
        command: ["wl-copy", copyProcess.pending]
    }

    // "Create from Clipboard": read the current text selection, then split it
    // into a note (title = first line). Binary payloads are ignored.
    property Process pasteProc: Process {
        command: ["bash", "-c",
            "wl-paste --list-types 2>/dev/null | grep -qi text && wl-paste --no-newline | head -c 4096 || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = this.text.trim();
                if (txt === "") return;
                var nl = txt.indexOf("\n");
                root.noteAdded(nl > 0 ? txt.substring(0, nl).substring(0, 60) : txt.substring(0, 60),
                               nl > 0 ? txt.substring(nl + 1) : "");
            }
        }
    }
}
