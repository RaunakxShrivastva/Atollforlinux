import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

// Notes pane (Productivity > Notes). Mirrors Atoll's NoteListView / NoteRow /
// NoteEditorView: a "Notes" heading with circular actions, an expandable
// search + colour-filter bar, a pinned-first list (single column, or two
// columns once there are more than three notes), image attachments, and the
// inline editor with title, colour dots, body, character count and paste.
Item {
    id: root

    // [{ id, title, body, pinned, colorIndex, created, modified, image }]
    property var notes: []

    // Feature switches, passed down from Settings (this component must not
    // import ../services: a plain-qml6 harness would load every singleton).
    property bool enablePinning: true
    property bool enableSearch: false
    property bool enableColorFiltering: false
    property bool enableFromClipboard: true
    property bool enableCharCount: true

    // Clipboard and file work is delegated to NotchContainer so this component
    // stays free of Quickshell.Io (the dev harness loads it under plain qml6).
    signal copyRequested(string text)
    signal pasteRequested(bool intoEditor)
    signal imageDiscarded(string path)

    signal noteAdded(string title, string body, int colorIndex, string image)
    signal noteUpdated(string id, string title, string body, int colorIndex, string image)
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

    // Attachments directory; NotchContainer passes NotesService's imageDir.
    property string imageDir: ""

    property string editingId: ""
    property bool editingNew: false
    property string draftTitle: ""
    property string draftBody: ""
    property int draftColor: 0
    property string draftImage: ""
    // True when draftImage was pasted in this editing session, so cancelling
    // can remove the file it created.
    property bool draftImageIsNew: false

    // Search / filter bar state (Atoll's isSearchExpanded + selectedColorFilter).
    property bool filterOpen: false
    property string searchText: ""
    property int colorFilter: -1

    readonly property bool editorOpen: editingNew || editingId !== ""
    readonly property bool wantsKeyboard: editorOpen || (filterOpen && enableSearch)

    // Pinned first, then most recently modified (Atoll sorts by
    // modificationDate), after applying the search and colour filters.
    readonly property var visibleNotes: {
        var q = searchText.toLowerCase();
        var list = [];
        var all = notes || [];
        for (var i = 0; i < all.length; i++) {
            var n = all[i];
            if (colorFilter >= 0 && (Number(n.colorIndex) || 0) !== colorFilter) continue;
            if (q !== "") {
                var title = String(n.title || "").toLowerCase();
                var body = String(n.body || "").toLowerCase();
                if (title.indexOf(q) < 0 && body.indexOf(q) < 0) continue;
            }
            list.push(n);
        }
        list.sort(function (a, b) {
            if (!!a.pinned !== !!b.pinned) return a.pinned ? -1 : 1;
            var am = Number(a.modified) || Number(a.created) || 0;
            var bm = Number(b.modified) || Number(b.created) || 0;
            return bm - am;
        });
        return list;
    }
    // Atoll switches to a two-column LazyVGrid past three notes.
    readonly property bool gridMode: visibleNotes.length > 3
    readonly property var leftNotes: {
        var out = [];
        for (var i = 0; i < visibleNotes.length; i += 2) out.push(visibleNotes[i]);
        return out;
    }
    readonly property var rightNotes: {
        var out = [];
        for (var i = 1; i < visibleNotes.length; i += 2) out.push(visibleNotes[i]);
        return out;
    }

    function timeAgo(note) {
        var t = Number(note.modified) || Number(note.created) || 0;
        var secs = Math.max(0, (Date.now() - t) / 1000);
        if (secs < 60) return "Just now";
        if (secs < 3600) return Math.floor(secs / 60) + "m";
        if (secs < 86400) return Math.floor(secs / 3600) + "h";
        return Math.floor(secs / 86400) + "d";
    }

    function startNew(title, body, colorIndex, image) {
        editingNew = true;
        editingId = "";
        draftTitle = title || "";
        draftBody = body || "";
        draftColor = colorIndex === undefined || colorIndex < 0 ? 0 : colorIndex;
        draftImage = image || "";
        draftImageIsNew = (image || "") !== "";
        titleField.forceActiveFocus();
    }

    function startEdit(note) {
        editingNew = false;
        editingId = note.id;
        draftTitle = note.title || "";
        draftBody = note.body || "";
        draftColor = Number(note.colorIndex) || 0;
        draftImage = note.image || "";
        draftImageIsNew = false;
        titleField.forceActiveFocus();
    }

    function commitEdit() {
        if (editingNew) root.noteAdded(draftTitle, draftBody, draftColor, draftImage);
        else if (editingId !== "") root.noteUpdated(editingId, draftTitle, draftBody, draftColor, draftImage);
        editingId = "";
        editingNew = false;
        draftImage = "";
        draftImageIsNew = false;
    }

    function cancelEdit() {
        if (draftImageIsNew && draftImage !== "") root.imageDiscarded(draftImage);
        editingId = "";
        editingNew = false;
        draftImage = "";
        draftImageIsNew = false;
    }

    function dropDraftImage() {
        if (draftImageIsNew && draftImage !== "") root.imageDiscarded(draftImage);
        draftImage = "";
        draftImageIsNew = false;
    }

    // Clipboard paste shared by the header button and the editor's photo
    // button: an image on the clipboard becomes an attachment, text becomes
    // note content (first line = title when creating a note).
    function pasteFromClipboard(intoEditor) {
        root.pasteRequested(intoEditor);
    }

    // Called back by NotchContainer once the clipboard read finishes. imagePath
    // is non-empty when the clipboard held an image.
    function applyClipboard(text, imagePath, intoEditor) {
        if (imagePath !== "") {
            if (intoEditor) {
                root.dropDraftImage();
                root.draftImage = imagePath;
                root.draftImageIsNew = true;
            } else {
                root.startNew("", "", 0, imagePath);
            }
            return;
        }
        var txt = String(text || "").trim();
        if (txt === "") return;
        if (intoEditor) {
            root.draftBody = root.draftBody === "" ? txt : root.draftBody + "\n" + txt;
        } else {
            var nl = txt.indexOf("\n");
            root.noteAdded(nl > 0 ? txt.substring(0, nl).substring(0, 60) : txt.substring(0, 60),
                           nl > 0 ? txt.substring(nl + 1) : "", -1, "");
        }
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
                text: root.editorOpen ? "Edit Note" : "Notes"
                color: Colors.white
                font.family: Typography.familyDisplay
                font.pixelSize: Typography.s16
                font.weight: Typography.semibold
            }
            Item { Layout.fillWidth: true }

            // Back (editor only)
            CircleButton {
                visible: root.editorOpen
                iconName: "chevron.left"
                onClicked: root.cancelEdit()
            }
            // Search / colour filter toggle (Atoll: magnifyingglass)
            CircleButton {
                visible: !root.editorOpen && (root.enableSearch || root.enableColorFiltering)
                iconName: "magnifyingglass"
                iconColor: root.filterOpen ? Colors.accent : Colors.white
                onClicked: root.filterOpen = !root.filterOpen
            }
            // Create from Clipboard
            CircleButton {
                visible: !root.editorOpen && root.enableFromClipboard
                iconName: "doc.on.clipboard"
                onClicked: root.pasteFromClipboard(false)
            }
            // Attach from Clipboard (editor)
            CircleButton {
                visible: root.editorOpen && root.enableFromClipboard
                iconName: "photo"
                onClicked: root.pasteFromClipboard(true)
            }
            // Clear all (confirmed)
            CircleButton {
                visible: !root.editorOpen && root.notes.length > 0
                iconName: "trash"
                iconColor: Colors.systemRed
                onClicked: root.confirmClear = true
            }
            // New / Save
            CircleButton {
                visible: !root.editorOpen
                iconName: "plus"
                onClicked: root.startNew("", "", -1, "")
            }
            CircleButton {
                visible: root.editorOpen
                iconName: "checkmark"
                iconColor: root.colorFor(root.draftColor)
                onClicked: root.commitEdit()
            }
        }

        // ---- Search + colour filter bar (Atoll's expandable bar) ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            visible: root.filterOpen && !root.editorOpen
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                visible: root.enableSearch
                spacing: 6

                SvgIcon {
                    iconName: "magnifyingglass"
                    color: Colors.textTertiary
                    implicitWidth: 11
                    implicitHeight: 11
                }
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    text: root.searchText
                    placeholderText: "Search notes\u2026"
                    color: Colors.white
                    placeholderTextColor: Colors.textTertiary
                    selectByMouse: true
                    font.family: Typography.family
                    font.pixelSize: Typography.s12
                    leftPadding: 0
                    background: null
                    onTextChanged: root.searchText = text
                }
                SvgIcon {
                    visible: root.searchText !== ""
                    iconName: "xmark.circle.fill"
                    color: Colors.textTertiary
                    implicitWidth: 11
                    implicitHeight: 11
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.searchText = ""
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.enableColorFiltering
                spacing: 6

                Rectangle {
                    width: allLabel.implicitWidth + 12
                    height: 18
                    radius: 9
                    color: root.colorFilter < 0 ? Qt.rgba(0.04, 0.52, 1, 0.3) : Colors.fillSubtle
                    Text {
                        id: allLabel
                        anchors.centerIn: parent
                        text: "All"
                        color: Colors.white
                        font.family: Typography.family
                        font.pixelSize: Typography.s10
                        font.weight: Typography.medium
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.colorFilter = -1
                    }
                }

                Repeater {
                    model: root.palette.length
                    delegate: Rectangle {
                        required property int index
                        width: 14
                        height: 14
                        radius: 7
                        color: root.palette[index]
                        border.width: root.colorFilter === index ? 2 : 0
                        border.color: Colors.white
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.colorFilter = root.colorFilter === index ? -1 : index
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }

        // ---- Editor ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12
            visible: root.editorOpen
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

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

                // Colour dots (Atoll's NoteEditorView picker).
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: root.palette.length
                        delegate: Rectangle {
                            required property int index
                            width: 16
                            height: 16
                            radius: 8
                            color: root.palette[index]
                            border.width: root.draftColor === index ? 2 : 0
                            border.color: Colors.white
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.draftColor = index
                            }
                        }
                    }
                }
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

                // Attachment preview, bottom right (Atoll's 55x55 image overlay).
                Rectangle {
                    visible: root.draftImage !== ""
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 10
                    anchors.bottomMargin: 10
                    width: 55
                    height: 55
                    radius: Metrics.r10
                    color: Colors.panel
                    border.color: Colors.hairlineStrong
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: root.draftImage !== "" ? "file://" + root.draftImage : ""
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    SvgIcon {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: -4
                        iconName: "xmark.circle.fill"
                        color: Colors.white
                        implicitWidth: 14
                        implicitHeight: 14
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dropDraftImage()
                        }
                    }
                }

                Text {
                    visible: root.enableCharCount
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: root.draftImage !== "" ? 74 : 8
                    anchors.bottomMargin: 8
                    text: root.draftBody.length + " chars"
                    color: Colors.textTertiary
                    font.family: Typography.familyMono
                    font.pixelSize: Typography.s10
                }
            }
        }

        // ---- List ----
        Flickable {
            id: listFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12
            visible: !root.editorOpen
            clip: true
            contentHeight: listColumn.height
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: listColumn
                width: listFlick.width
                spacing: 8

                // Two-column grid (> 3 notes), Atoll's LazyVGrid.
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.gridMode
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: root.leftNotes
                            delegate: NoteCard { note: modelData; compact: true }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: root.rightNotes
                            delegate: NoteCard { note: modelData; compact: true }
                        }
                    }
                }

                // Single column (<= 3 notes).
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !root.gridMode
                    spacing: 8
                    Repeater {
                        model: root.visibleNotes
                        delegate: NoteCard { note: modelData; compact: false }
                    }
                }

                // Empty / no-results state.
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 18
                    visible: root.visibleNotes.length === 0
                    spacing: 6

                    SvgIcon {
                        Layout.alignment: Qt.AlignHCenter
                        iconName: root.searchText !== "" ? "magnifyingglass" : "note.text"
                        color: Colors.textTertiary
                        implicitWidth: 28
                        implicitHeight: 28
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.searchText !== "" ? "No results found" : "No notes yet"
                        color: Colors.textSecondary
                        font.family: Typography.familyDisplay
                        font.pixelSize: Typography.s14
                        font.weight: Typography.semibold
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.searchText === ""
                        text: "Tap + to write one"
                        color: Colors.textTertiary
                        font.family: Typography.family
                        font.pixelSize: Typography.s11
                    }
                }
            }
        }
    }

    // ---- Delete-all confirmation (Atoll's "Delete All Notes?" alert) ----
    property bool confirmClear: false
    Rectangle {
        anchors.fill: parent
        visible: root.confirmClear
        color: Qt.rgba(0, 0, 0, 0.55)
        z: 10

        MouseArea {
            anchors.fill: parent
            onClicked: root.confirmClear = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 260)
            height: 112
            radius: Metrics.r12
            color: Colors.panel
            border.color: Colors.hairlineStrong
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: "Delete all notes?"
                    color: Colors.white
                    font.family: Typography.familyDisplay
                    font.pixelSize: Typography.s14
                    font.weight: Typography.semibold
                }
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "This removes every note and its attachments."
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.s11
                    wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    Rectangle {
                        width: 64
                        height: 24
                        radius: 12
                        color: cancelMouse.containsMouse ? Colors.fillHover : Colors.fillSubtle
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Colors.white
                            font.family: Typography.family
                            font.pixelSize: Typography.s11
                        }
                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.confirmClear = false
                        }
                    }
                    Rectangle {
                        width: 64
                        height: 24
                        radius: 12
                        color: deleteMouse.containsMouse ? Qt.rgba(1, 0.27, 0.23, 0.9) : Colors.systemRed
                        Text {
                            anchors.centerIn: parent
                            text: "Delete"
                            color: Colors.white
                            font.family: Typography.family
                            font.pixelSize: Typography.s11
                            font.weight: Typography.semibold
                        }
                        MouseArea {
                            id: deleteMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.confirmClear = false;
                                root.allCleared();
                            }
                        }
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

    // ---- Note card (Atoll's NoteRow) ----
    component NoteCard: Rectangle {
        id: card
        property var note: null
        property bool compact: false
        property bool copied: false

        Layout.fillWidth: true
        Layout.preferredHeight: compact ? 64 : 68
        radius: 12
        color: cardMouse.containsMouse ? Colors.fillHover : Colors.fill
        border.color: Qt.rgba(root.colorFor(card.note.colorIndex).r,
                              root.colorFor(card.note.colorIndex).g,
                              root.colorFor(card.note.colorIndex).b, 0.25)
        border.width: 1
        clip: true
        Behavior on color { ColorAnimation { duration: Motion.instant } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            spacing: 8

            // Colour accent bar.
            Rectangle {
                Layout.preferredWidth: compact ? 3 : 4
                Layout.fillHeight: true
                radius: 2
                color: root.colorFor(card.note.colorIndex)
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: compact ? 1 : 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    SvgIcon {
                        visible: card.note.pinned === true
                        iconName: "pin.fill"
                        color: root.colorFor(card.note.colorIndex)
                        implicitWidth: compact ? 7 : 10
                        implicitHeight: compact ? 7 : 10
                    }
                    Text {
                        Layout.fillWidth: true
                        text: card.note.title && card.note.title.length > 0
                              ? card.note.title : "New Note"
                        color: Colors.white
                        font.family: Typography.familyDisplay
                        font.pixelSize: compact ? Typography.s12 : Typography.s13
                        font.weight: Typography.semibold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: card.note.body && card.note.body.length > 0
                          ? card.note.body : "No content"
                    color: card.note.body ? Qt.rgba(1, 1, 1, 0.7) : Colors.textTertiary
                    font.family: Typography.family
                    font.pixelSize: compact ? Typography.s10 : Typography.s11
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: compact ? 1 : 2
                    verticalAlignment: Text.AlignTop
                }
            }

            // Attachment thumbnail.
            Rectangle {
                visible: card.note.image !== undefined && card.note.image !== ""
                Layout.preferredWidth: compact ? 32 : 50
                Layout.preferredHeight: compact ? 32 : 50
                radius: Metrics.r6
                color: Colors.panel
                border.color: Colors.hairlineStrong
                border.width: 1
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: card.note.image ? "file://" + card.note.image : ""
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            // Age, only on the roomy single-column rows (Atoll hides it in the
            // grid and while hovering).
            Text {
                visible: !card.compact && !cardMouse.containsMouse
                text: root.timeAgo(card.note)
                color: Colors.textTertiary
                font.family: Typography.family
                font.pixelSize: Typography.s10
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
            color: Colors.panel
            border.color: Colors.hairline
            border.width: 1

            RowLayout {
                id: actionsRow
                anchors.centerIn: parent
                spacing: 4

                CircleButton {
                    visible: root.enablePinning
                    compact: true
                    iconName: card.note.pinned === true ? "pin.slash.fill" : "pin.fill"
                    onClicked: root.notePinned(card.note.id)
                }
                CircleButton {
                    compact: true
                    iconName: card.copied ? "checkmark" : "doc.on.doc"
                    iconColor: card.copied ? Colors.systemGreen : Colors.white
                    onClicked: {
                        root.copyRequested(card.note.body || "");
                        card.copied = true;
                        copiedTimer.restart();
                    }
                }
                CircleButton {
                    compact: true
                    iconName: "trash"
                    iconColor: Colors.systemRed
                    onClicked: root.noteRemoved(card.note.id)
                }
            }

            Timer {
                id: copiedTimer
                interval: 1500
                onTriggered: card.copied = false
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.startEdit(card.note)
        }
    }

}
