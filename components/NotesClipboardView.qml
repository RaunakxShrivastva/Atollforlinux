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
    property string imageDir: ""
    // Notes sub-features, forwarded from Settings (see NotesView).
    property bool notePinning: true
    property bool noteSearch: false
    property bool noteColorFiltering: false
    property bool noteFromClipboard: true
    property bool noteCharCount: true
    property string appName: ""
    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property bool hasNotification: false

    // True while the notes editor is open: the island has to take the keyboard
    // on demand for its text fields to be typeable (see shell.qml).
    readonly property bool wantsKeyboard: root.notesVisible && notesView.wantsKeyboard

    signal pickRequested(int id)
    signal removeRequested(int id)
    signal clearRequested()
    signal dismissClicked()

    signal noteCopyRequested(string text)
    signal notePasteRequested(bool intoEditor)
    signal noteImageDiscarded(string path)

    signal noteAdded(string title, string body, int colorIndex, string image)
    signal noteUpdated(string id, string title, string body, int colorIndex, string image)
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
        id: notesView
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.notesVisible
        notes: root.notes
        imageDir: root.imageDir
        enablePinning: root.notePinning
        enableSearch: root.noteSearch
        enableColorFiltering: root.noteColorFiltering
        enableFromClipboard: root.noteFromClipboard
        enableCharCount: root.noteCharCount
        onCopyRequested: text => root.noteCopyRequested(text)
        onPasteRequested: intoEditor => root.notePasteRequested(intoEditor)
        onImageDiscarded: path => root.noteImageDiscarded(path)
        onNoteAdded: (title, body, colorIndex, image) => root.noteAdded(title, body, colorIndex, image)
        onNoteUpdated: (id, title, body, colorIndex, image) => root.noteUpdated(id, title, body, colorIndex, image)
        onNoteRemoved: id => root.noteRemoved(id)
        onNotePinned: id => root.notePinned(id)
        onAllCleared: root.allCleared()
    }
}
