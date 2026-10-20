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
    //
    // Full-screen pick: grab one frame, then answer colour queries from a
    // persistent helper that keeps the raw pixels in memory. (hyprpicker needs
    // zwlr_screencopy_v1, which KWin does not offer; spawning ImageMagick per
    // mouse move was far too slow.)

    property bool capturing: false
    property bool overlayVisible: false
    property string shotUrl: ""
    property string hoverHex: "#ffffff"
    property string hoverRgb: "rgb(255, 255, 255)"

    readonly property string helper:
        Quickshell.shellDir.toString().replace(/^file:\/\//, "") + "/bin/atoll-pick-sample.py"

    property int _sampleX: 0
    property int _sampleY: 0
    property bool _pending: false

    function pick() {
        if (root.capturing || root.overlayVisible) return;
        root.capturing = true;
        root.overlayVisible = false;
        // Give the island animation a head start; Spectacle takes ~2 s to
        // deliver its frame, so the notch is long gone by then.
        root.captureDelay.restart();
    }

    property Timer captureDelay: Timer {
        interval: 150
        onTriggered: root.capture.running = true
    }

    property Process capture: Process {
        command: ["sh", "-c",
            "mkdir -p '" + root.dir + "' && rm -f '" + root.tmpShot + "' && "
            + "spectacle -b -n -f -o '" + root.tmpShot + "' >/dev/null 2>&1 && "
            + "test -s '" + root.tmpShot + "'"]
        onExited: code => {
            root.capturing = false;
            if (code !== 0) {
                root.failed("Could not capture the screen for the colour picker.");
                return;
            }
            root.shotUrl = "file://" + root.tmpShot + "?t=" + Date.now();
            root.hoverHex = "#ffffff";
            root.hoverRgb = "rgb(255, 255, 255)";
            root.overlayVisible = true;
            // The sampler decodes the frozen frame once, then answers from
            // memory. Colours go live a moment after the loupe appears.
            root.sampler.command = ["python3", root.helper, root.tmpShot];
            root.sampler.running = true;
        }
    }

    // Pointer position -> helper query. Kept off the mouse-move path so the
    // loupe never waits on a subprocess.
    function sampleAt(x, y) {
        root._sampleX = x;
        root._sampleY = y;
        root._pending = true;
    }

    // Repeating, not restart-on-move: a 1 kHz mouse would keep resetting a
    // single-shot timer, so the hex would only update once the pointer stopped.
    property Timer sampleTimer: Timer {
        interval: 12
        repeat: true
        running: root.overlayVisible
        onTriggered: {
            if (!root._pending || !root.sampler.running) return;
            root._pending = false;
            root.sampler.write(root._sampleX + " " + root._sampleY + "\n");
        }
    }

    property Process sampler: Process {
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => root.acceptSample(line)
        }
        onExited: code => {
            // Stop() kills the helper on purpose; only report a real failure.
            if (root.overlayVisible)
                root.failed("The colour sampler stopped (python3 + Pillow are required).");
        }
    }

    function acceptSample(line) {
        var c = root.parseHex(line);
        if (c === null) return;
        root.hoverHex = root.toHex(c);
        root.hoverRgb = root.toRgb(c);
    }

    function stop() {
        root.overlayVisible = false;
        if (root.sampler.running) root.sampler.running = false;
    }

    function commitPick() {
        var c = root.parseHex(root.hoverHex);
        root.stop();
        if (c !== null) root.addColor(c);
    }

    function cancelPick() {
        root.stop();
    }

    // A picked colour -> history -> clipboard.
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
