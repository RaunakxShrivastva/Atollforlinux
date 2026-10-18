import QtQuick
import QtQuick.Layouts
import "../theme"

// The merged Notes tab (Atoll's NotchNotesView). When the clipboard display mode
// is "Separate tab" the tab is an HStack(spacing: 0) of the clipboard pane beside
// the notes pane, split by a divider; each pane takes an equal share of the
// width. With only one of the two enabled it fills the tab on its own.
RowLayout {
    id: root

    property bool clipboardVisible: true
    property bool notesVisible: true

    property var entries: []
    property var notes: []
    property string appName: ""
    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property bool hasNotification: false

    signal pickRequested(int id)
    signal removeRequested(int id)
    signal clearRequested()
    signal dismissClicked()

    signal noteAdded(string title, string body)
    signal noteUpdated(string id, string title, string body)
    signal noteRemoved(string id)
    signal notePinned(string id)
    signal allCleared()

    spacing: 0

    ClipboardView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.clipboardVisible
        columns: root.notesVisible && root.clipboardVisible ? 1 : 2
        entries: root.entries
        appName: root.appName
        summary: root.summary
        body: root.body
        appIcon: root.appIcon
        hasNotification: root.hasNotification
        onPickRequested: id => root.pickRequested(id)
        onRemoveRequested: id => root.removeRequested(id)
        onClearRequested: root.clearRequested()
        onDismissClicked: root.dismissClicked()
    }

    // Divider (only between the two panes).
    Rectangle {
        visible: root.clipboardVisible && root.notesVisible && !root.hasNotification
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        color: Qt.rgba(1, 1, 1, 0.15)
    }

    NotesView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.notesVisible
        notes: root.notes
        onNoteAdded: (title, body) => root.noteAdded(title, body)
        onNoteUpdated: (id, title, body) => root.noteUpdated(id, title, body)
        onNoteRemoved: id => root.noteRemoved(id)
        onNotePinned: id => root.notePinned(id)
        onAllCleared: root.allCleared()
    }
}
