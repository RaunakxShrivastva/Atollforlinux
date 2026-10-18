import QtQuick
import Quickshell
import Quickshell.Io

// Notes storage for the Notes tab (Productivity > Notes). A list of note items
// persisted as JSON under $XDG_DATA_HOME/atoll, mirroring Atoll's NoteItem
// (title, content, pinned, colorIndex). The legacy single-file notes.md is
// migrated once on first load if it exists.
QtObject {
    id: root

    readonly property string dir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/atoll"
    readonly property string path: dir + "/notes.json"
    readonly property string legacyPath: dir + "/notes.md"

    // [{ id, title, body, pinned, colorIndex, created }]
    property var notes: []
    property bool loaded: false

    signal changed()

    function save() {
        root.persist();
    }

    function nextColor() {
        var maxIndex = -1;
        for (var i = 0; i < notes.length; i++)
            maxIndex = Math.max(maxIndex, Number(notes[i].colorIndex) || 0);
        return (maxIndex + 1) % 6;
    }

    function add(title, body) {
        var id = String(Date.now()) + "-" + Math.floor(Math.random() * 1000);
        var next = notes.slice();
        next.unshift({
            id: id,
            title: title && title.length > 0 ? title : "New Note",
            body: body || "",
            pinned: false,
            colorIndex: nextColor(),
            created: Date.now()
        });
        notes = next;
        changed();
        saveTimer.restart();
        return id;
    }

    function update(id, title, body) {
        var next = notes.slice();
        for (var i = 0; i < next.length; i++) {
            if (next[i].id === id) {
                var copy = {};
                for (var k in next[i]) copy[k] = next[i][k];
                if (title !== undefined) copy.title = title;
                if (body !== undefined) copy.body = body;
                next[i] = copy;
                break;
            }
        }
        notes = next;
        changed();
        saveTimer.restart();
    }

    function remove(id) {
        notes = notes.filter(function (n) { return n.id !== id; });
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
        changed();
        saveTimer.restart();
    }

    // "Create from Clipboard": the first line becomes the title, the rest the body.
    function fromClipboard(text) {
        var value = String(text || "").trim();
        if (value === "") return "";
        var nl = value.indexOf("\n");
        var title = nl > 0 ? value.substring(0, nl) : value;
        var body = nl > 0 ? value.substring(nl + 1) : "";
        return add(title.substring(0, 60), body);
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
