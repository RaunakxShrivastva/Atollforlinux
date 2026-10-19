import QtQuick
import Quickshell
import Quickshell.Io

// Notes storage for the Notes tab (Productivity > Notes). A list of note items
// persisted as JSON under $XDG_DATA_HOME/atoll, mirroring Atoll's NoteItem
// (title, content, pinned, colorIndex, image). Attached images are files under
// note-images/ rather than inline data, the same split Atoll uses
// (NoteItem.imageFileName + NoteImages/). The legacy single-file notes.md is
// migrated once on first load if it exists.
QtObject {
    id: root

    readonly property string dir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/atoll"
    readonly property string path: dir + "/notes.json"
    readonly property string legacyPath: dir + "/notes.md"
    // Attachments live beside the JSON, so the pair can be moved or backed up
    // together (Atoll keeps NoteImages/ under Documents).
    readonly property string imageDir: dir + "/note-images"

    // [{ id, title, body, pinned, colorIndex, created, modified, image }]
    // image is a path under imageDir, or "" for a note without an attachment.
    property var notes: []
    property bool loaded: false

    signal changed()

    function save() {
        root.persist();
    }

    function newId() {
        return String(Date.now()) + "-" + Math.floor(Math.random() * 100000);
    }

    function nextColor() {
        var maxIndex = -1;
        for (var i = 0; i < notes.length; i++)
            maxIndex = Math.max(maxIndex, Number(notes[i].colorIndex) || 0);
        return (maxIndex + 1) % 6;
    }

    function add(title, body, colorIndex, image) {
        var now = Date.now();
        var next = notes.slice();
        next.unshift({
            id: newId(),
            title: title && title.length > 0 ? title : "New Note",
            body: body || "",
            pinned: false,
            colorIndex: colorIndex === undefined || colorIndex === null || colorIndex < 0
                        ? nextColor() : Number(colorIndex),
            created: now,
            modified: now,
            image: image || ""
        });
        notes = next;
        changed();
        saveTimer.restart();
        return notes[0].id;
    }

    function update(id, title, body, colorIndex, image) {
        var next = notes.slice();
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === id) {
                var copy = {};
                for (var k in next[i]) copy[k] = next[i][k];
                if (title !== undefined) copy.title = title;
                if (body !== undefined) copy.body = body;
                if (colorIndex !== undefined) copy.colorIndex = Number(colorIndex);
                if (image !== undefined && image !== copy.image) {
                    // The editor replaced or dropped the attachment: the file the
                    // note no longer points at is dead weight.
                    if (copy.image) removeFile(copy.image);
                    copy.image = image;
                }
                copy.modified = Date.now();
                next[i] = copy;
                break;
            }
        }
        notes = next;
        changed();
        saveTimer.restart();
    }

    function remove(id) {
        var next = [];
        for (var i = 0; i < notes.length; i++) {
            if (notes[i].id === id) {
                if (notes[i].image) removeFile(notes[i].image);
            } else {
                next.push(notes[i]);
            }
        }
        notes = next;
        changed();
        saveTimer.restart();
    }

    function togglePin(id) {
        var next = notes.slice();
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === id) {
                var copy = {};
                for (var k in next[i]) copy[k] = next[i][k];
                copy.pinned = !copy.pinned;
                next[i] = copy;
                break;
            }
        }
        notes = next;
        changed();
        saveTimer.restart();
    }

    function clearAll() {
        notes = [];
        wipeImages.running = true;
        changed();
        saveTimer.restart();
    }

    // Delete one attachment file (ignore a missing one).
    function removeFile(path) {
        if (!path) return;
        rmProc.command = ["bash", "-c", "rm -f -- '" + String(path).replace(/'/g, "'\\''") + "'"];
        rmProc.running = true;
    }

    property Process rmProc: Process {}

    // "Clear all" drops the notes' attachments with them.
    property Process wipeImages: Process {
        command: ["bash", "-c", "rm -rf -- '" + root.imageDir + "' 2>/dev/null || true"]
    }

    // Persistence. Read and write go through a shell so a missing file (first
    // run) is silent; the JSON is streamed on stdin so note text needs no
    // quoting.
    property Process readProc: Process {
        command: ["bash", "-c", "cat '" + root.path + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text.trim();
                if (text === "") {
                    root.loaded = true;
                    legacy.running = true;
                    return;
                }
                try {
                    var parsed = JSON.parse(text);
                    var list = parsed && parsed.notes ? parsed.notes : parsed;
                    if (list instanceof Array) {
                        root.notes = list;
                        root.changed();
                    }
                } catch (e) {
                    // Corrupt file: keep what we have rather than clobbering it.
                }
                root.loaded = true;
            }
        }
    }

    property Process writeProc: Process {
        property string pending: ""
        command: ["bash", "-c", "mkdir -p '" + root.dir + "' && cat > '" + root.path + "'"]
        stdinEnabled: true
        onStarted: if (pending !== "") write(pending)
    }

    function persist() {
        root.writeProc.pending = JSON.stringify({ notes: root.notes });
        root.writeProc.running = true;
    }

    // One-shot migration of the old Markdown scratchpad into a single note.
    property Process legacy: Process {
        command: ["bash", "-c", "cat '" + root.legacyPath + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = this.text.trim();
                if (txt.length > 0) {
                    root.add("Notes", txt);
                    rename.command = ["bash", "-c", "mv '" + root.legacyPath + "' '" + root.legacyPath + ".migrated' 2>/dev/null || true"];
                    rename.running = true;
                }
            }
        }
    }
    property Process rename: Process {}

    property Timer saveTimer: Timer {
        interval: 400
        onTriggered: root.save()
    }

    Component.onCompleted: readProc.running = true
}
