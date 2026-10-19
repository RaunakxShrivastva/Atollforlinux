import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

// Focused harness for the Notes pane: the list with search + colour filter
// open, the two-column grid, the editor with an attachment and char count, the
// no-results state and the delete-all confirmation. Renders under plain `qml6`
// because NotesView takes no service dependency:
//   mkdir -p /tmp/opencode/preview
//   magick -size 120x90 gradient:purple-black /tmp/opencode/preview/note-thumb.png
//   QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/notes.qml
Window {
    id: stage
    width: 1180
    height: 620
    visible: true
    color: "#101014"

    AtollFonts {}

    // grabToImage has a transparent background, so paint the stage for the PNG.
    Rectangle {
        anchors.fill: parent
        color: "#101014"
    }

    readonly property var baseNotes: [
        { id: "n1", title: "Release checklist", body: "Tag v2.3.0, rebuild the appcast, upload the DMG and update the Homebrew cask.", pinned: true, colorIndex: 0, created: Date.now() - 300000, modified: Date.now() - 120000, image: "" },
        { id: "n2", title: "Groceries", body: "Oat milk, espresso beans, sourdough, basil.", pinned: false, colorIndex: 3, created: Date.now() - 86400000, modified: Date.now() - 86400000, image: "" },
        { id: "n3", title: "Design notes", body: "The island's open width should follow the tab count: 640 with three tabs, 690 with five, 770 with six.", pinned: false, colorIndex: 1, created: Date.now() - 3600000, modified: Date.now() - 1800000, image: "" },
        { id: "n4", title: "Screenshot", body: "Palette reference for the clipboard panel.", pinned: false, colorIndex: 4, created: Date.now() - 7200000, modified: Date.now() - 7200000, image: "/tmp/opencode/preview/note-thumb.png" },
        { id: "n5", title: "Keyboard shortcut", body: "Super+Shift+N opens a new note.", pinned: false, colorIndex: 2, created: Date.now() - 172800000, modified: Date.now() - 172800000, image: "" }
    ]

    // ---- List, filters expanded ----
    Rectangle {
        x: 16; y: 16; width: 380; height: 580
        color: "transparent"

        NotesView {
            anchors.fill: parent
            notes: stage.baseNotes
            imageDir: "/tmp/opencode/preview"
            enablePinning: true
            enableSearch: true
            enableColorFiltering: true
            enableFromClipboard: true
            enableCharCount: true
            filterOpen: true
            searchText: "note"
            colorFilter: -1
        }
    }

    // ---- Single column, no filters ----
    Rectangle {
        x: 412; y: 16; width: 380; height: 580
        color: "transparent"

        NotesView {
            anchors.fill: parent
            notes: stage.baseNotes.slice(0, 3)
            imageDir: "/tmp/opencode/preview"
            enablePinning: true
            enableSearch: false
            enableColorFiltering: false
        }
    }

    // ---- Editor with attachment + char count ----
    Rectangle {
        x: 808; y: 16; width: 356; height: 300
        color: "transparent"

        NotesView {
            anchors.fill: parent
            notes: stage.baseNotes
            imageDir: "/tmp/opencode/preview"
            enableCharCount: true
            editingNew: true
            draftTitle: "Palette reference"
            draftBody: "Text · 4m ago, URL · 2h ago, Image · 3d ago. The clipboard panel tints each kind: text grey, url blue, file orange, image purple."
            draftColor: 4
            draftImage: "/tmp/opencode/preview/note-thumb.png"
        }
    }

    // ---- No results ----
    Rectangle {
        x: 808; y: 332; width: 356; height: 264
        color: "transparent"

        NotesView {
            anchors.fill: parent
            notes: stage.baseNotes
            enableSearch: true
            filterOpen: true
            searchText: "zzzz"
        }
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: stage.contentItem.grabToImage(function (res) {
            res.saveToFile("/tmp/opencode/preview/notes.png");
            Qt.quit();
        })
    }
}
