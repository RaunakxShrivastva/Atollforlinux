pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

// Colour picker (Utilities > Colour Picker), ported from
// managers/ColorPickerManager.swift + models/PickedColor.swift.
//
// A pick grabs one pixel under the cursor and pushes it onto a persisted
// history (newest first, capped at 50). Two backends are tried in order:
//   1. hyprpicker  - the wlroots/Hyprland grabber
//   2. spectacle   - a region grab, then the centre pixel of the region, which
//                    is what is available on KWin. The HUD says "drag a small
//                    area" so the centre lands on the pixel you want.
// The history is stored as JSON under $XDG_DATA_HOME/atoll (r/g/b/a are 0..1
// floats, like PickedColor, so every format is derived from one canonical value).
QtObject {
    id: root

    readonly property string dir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/atoll"
    readonly property string path: dir + "/colors.json"
    readonly property string tmpShot: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/atoll/pick.png"

    readonly property int maxHistory: Math.max(1, Number(Settings.values.colorHistorySize) || 10)

    // [{ id, r, g, b, a, timestamp }] newest first
    property var history: []
    property bool loaded: false

    property string lastColor: ""
    property bool picking: false
    property bool _got: false

    signal picked(string value)
    signal failed(string reason)
    signal changed()

    // ---------------- picking ----------------

    function pick() {
        if (picking) return;
        picking = true;
        root._got = false;
        pickProc.running = true;
    }

    property Process pickProc: Process {
        // Always ask hyprpicker for hex: the history stays canonical and the
        // copy honours colorPickerFormat ourselves.
        command: ["sh", "-c", "hyprpicker -f hex 2>/dev/null || hyprpicker 2>/dev/null"]
        stdout: SplitParser {
            onRead: line => root.accept(line)
        }
        onExited: {
            if (root._got) {
                root.picking = false;
                return;
            }
            // No hyprpicker (or no wlroots screen-copy protocol): fall back to a
            // Spectacle region grab and sample its centre pixel.
            fallback.running = true;
        }
    }

    property Process fallback: Process {
        command: ["sh", "-c",
            "mkdir -p '" + dir + "' && rm -f '" + tmpShot + "' && "
            + "spectacle -b -n -r -o '" + tmpShot + "' >/dev/null 2>&1 && "
            + "magick '" + tmpShot + "' -gravity center -crop 1x1+0+0 "
            + "-format '#%[hex:p{0,0}]' info: 2>/dev/null"]
        stdout: SplitParser {
            onRead: line => root.accept(line)
        }
        onExited: {
            root.picking = false;
            if (!root._got)
                root.failed("Could not read a pixel - install hyprpicker (Hyprland) or check the Spectacle grab.");
        }
    }

    // A line of picker output -> canonical colour -> history -> clipboard.
    function accept(line) {
        var c = root.parseHex(line);
        if (c === null) return;
        root._got = true;
        root.addColor(c);
    }

    function addColor(c) {
        var entry = {
            id: String(Date.now()) + "-" + Math.floor(Math.random() * 1000),
            r: c.r, g: c.g, b: c.b, a: c.a === undefined ? 1 : c.a,
            timestamp: Date.now()
        };
        var next = [entry].concat(root.history.slice(0, root.maxHistory - 1));
        root.history = next;
        root.changed();
        root.saveTimer.restart();

        var value = root.formatColor(entry, Settings.values.colorPickerFormat || "hex");
        root.lastColor = value;
        root.copy(value);
        root.picked(value);
    }

    function removeColor(id) {
        root.history = root.history.filter(function (e) { return e.id !== id; });
        root.changed();
        root.saveTimer.restart();
    }

    function clearHistory() {
        root.history = [];
        root.changed();
        root.saveTimer.restart();
    }

    // ---------------- formats ----------------
    // All colour maths lives in the ColorFormats singleton (theme/) so the views
    // and the offscreen harnesses can share it without pulling in Quickshell.
    function toHex(c) { return ColorFormats.toHex(c); }
    function toRgb(c) { return ColorFormats.toRgb(c); }
    function toRgba(c) { return ColorFormats.toRgba(c); }
    function toHsl(c) { return ColorFormats.toHsl(c); }
    function toHsla(c) { return ColorFormats.toHsla(c); }
    function toHsv(c) { return ColorFormats.toHsv(c); }
    function toQml(c) { return ColorFormats.toQml(c); }
    function formatsFor(c) { return ColorFormats.formatsFor(c); }
    function formatColor(c, name) { return ColorFormats.formatColor(c, name); }
    function colorOf(c) { return ColorFormats.colorOf(c); }
    function timeAgo(ts) { return ColorFormats.timeAgo(ts); }
    function parseHex(s) { return ColorFormats.parseHex(s); }

    // ---------------- clipboard ----------------

    function copy(text) {
        if (String(text || "") === "") return;
        copyProc.command = ["wl-copy", String(text)];
        copyProc.running = true;
    }

    property Process copyProc: Process {}

    // ---------------- persistence ----------------

    property Process readProc: Process {
        command: ["bash", "-c", "cat '" + root.path + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text.trim();
                if (text !== "") {
                    try {
                        var parsed = JSON.parse(text);
                        var list = parsed && parsed.colors ? parsed.colors : parsed;
                        if (list instanceof Array) {
                            root.history = list;
                            root.changed();
                        }
                    } catch (e) {
                        // Corrupt file: keep the empty history rather than clobber it.
                    }
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
        root.writeProc.pending = JSON.stringify({ colors: root.history });
        root.writeProc.running = true;
    }

    property Timer saveTimer: Timer {
        interval: 400
        onTriggered: root.persist()
    }

    Component.onCompleted: readProc.running = true
}
