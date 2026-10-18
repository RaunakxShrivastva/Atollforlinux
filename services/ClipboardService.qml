import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history (Utilities > Clipboard). Backed by cliphist + wl-clipboard:
// `wl-paste --watch cliphist store` fills the history, and picking an entry
// pipes it back through `cliphist decode | wl-copy`. Everything degrades to an
// empty list if cliphist is not installed.
//
// Each entry is { id, preview, kind, age, thumb } mirroring the row model of
// Atoll's NotchClipboardView: a document glyph, the text (or an image
// thumbnail), a "Text"/"Image" subtitle and a right-aligned relative age.
QtObject {
    id: root

    property var entries: []      // [{ id, preview, kind, age, thumb }]
    property bool available: false
    property int limit: 3
    property int revision: 0      // bumped after thumbnails land

    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/atoll/clip"    // id -> first-seen epoch ms, so entries get a stable relative age.
    property var stamps: ({})

    function refresh() { listProc.running = true; }

    function pick(id) {
        pickProc.command = ["bash", "-c", "cliphist decode " + id + " | wl-copy 2>/dev/null || true"];
        pickProc.running = true;
    }

    function remove(id) {
        removeProc.command = ["bash", "-c", "cliphist decode " + id + " | cliphist delete 2>/dev/null || true"];
        removeProc.running = true;
        refreshDebounce.restart();
    }

    function clear() {
        clearProc.command = ["bash", "-c", "cliphist wipe 2>/dev/null || true"];
        clearProc.running = true;
        refreshDebounce.restart();
    }

    function thumbFor(id) {
        return "file://" + root.cacheDir + "/" + id + ".png";
    }

    // "32m" / "2h" / "3d" / "now". Returns "" while an entry has no stamp yet.
    function relativeAge(ms) {
        if (!ms) return "";
        var s = Math.max(0, (Date.now() - ms) / 1000);
        if (s < 60) return "now";
        var m = Math.floor(s / 60);
        if (m < 60) return m + "m";
        var h = Math.floor(m / 60);
        if (h < 24) return h + "h";
        return Math.floor(h / 24) + "d";
    }

    property Process listProc: Process {
        command: ["bash", "-c", "command -v cliphist >/dev/null && cliphist list | head -" + Math.max(1, root.limit)]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    property Process pickProc: Process {}
    property Process removeProc: Process {}
    property Process clearProc: Process {}
    property Process watcher: Process {
        command: ["bash", "-c", "command -v cliphist >/dev/null && wl-paste --watch cliphist store"]
    }

    // Thumbnails decoded so far this session. An image entry advertises a thumb
    // path only once the file exists, so the view instantiates its Image lazily
    // and never has to re-request a missing URL.
    property var thumbsDone: ({})

    // Downscale image entries into the thumbnail cache (one pass for the list).
    property var thumbRequest: []
    property Process thumbProc: Process {
        onRunningChanged: if (!running) {
            for (var i = 0; i < root.thumbRequest.length; i++)
                root.thumbsDone[String(root.thumbRequest[i])] = true;
            root.thumbRequest = [];
            if (root._refreshAfterThumbs) {
                root._refreshAfterThumbs = false;
                root.refresh();
            }
            root.revision++;
        }
    }
    property bool _refreshAfterThumbs: false

    property Timer refreshDebounce: Timer {
        interval: 250
        onTriggered: root.refresh()
    }

    property Timer poll: Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function parse(text) {
        var out = [];
        var needThumbs = [];
        var lines = text.split("\n");
        var now = Date.now();
        var dirty = false;

        for (var i = 0; i < lines.length; i++) {
            var t = lines[i].trim();
            if (t === "") continue;
            var tab = t.indexOf("\t");
            var id = tab > 0 ? Number(t.substring(0, tab)) : NaN;
            if (!isFinite(id)) continue;
            var preview = tab > 0 ? t.substring(tab + 1) : t;

            // cliphist marks binary payloads; treat those as images.
            var binary = preview.indexOf("[[ binary data") === 0;
            var kind = binary ? "Image" : "Text";
            var thumb = "";
            if (binary) {
                if (root.thumbsDone[String(id)]) thumb = root.thumbFor(id);
                else needThumbs.push(id);
            }

            var key = String(id);
            if (root.stamps[key] === undefined) {
                root.stamps[key] = now;
                dirty = true;
            }

            out.push({
                id: id,
                preview: preview,
                kind: kind,
                age: root.relativeAge(root.stamps[key]),
                thumb: thumb
            });
        }

        if (dirty) root.saveStamps();

        if (needThumbs.length > 0 && !thumbProc.running) {
            var dir = root.cacheDir;
            var cmd = "mkdir -p '" + dir + "'; command -v magick >/dev/null || exit 0; ";
            for (var j = 0; j < needThumbs.length; j++) {
                var iid = needThumbs[j];
                cmd += "[ -f '" + dir + "/" + iid + ".png' ] || "
                     + "(cliphist decode " + iid + " 2>/dev/null | magick - -resize 200x150\\> '"
                     + dir + "/" + iid + ".png' 2>/dev/null); ";
            }
            root.thumbRequest = needThumbs;
            root._refreshAfterThumbs = true;
            thumbProc.command = ["bash", "-c", cmd];
            thumbProc.running = true;
        }

        root.entries = out;
        root.available = out.length > 0;
        root.revision++;
    }

    // Sidecar store of first-seen timestamps so relative ages survive restarts.
    // Written/read through a shell so a missing cache directory never produces a
    // FileView warning on first run.
    readonly property string stampPath: root.cacheDir + "/clip-timestamps.json"

    function saveStamps() {
        stampWrite.command = ["bash", "-c",
            "mkdir -p '" + root.cacheDir + "' && printf %s '" + JSON.stringify(root.stamps)
            + "' > '" + stampPath + "'"];
        stampWrite.running = true;
    }

    property Process stampWrite: Process {}

    property Process stampRead: Process {
        command: ["bash", "-c", "cat '" + root.stampPath + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    if (parsed && typeof parsed === "object") root.stamps = parsed;
                } catch (e) {
                    root.stamps = {};
                }
            }
        }
    }

    Component.onCompleted: {
        mkdir.running = true;
        stampRead.running = true;
        refresh();
        watcher.running = true;
    }

    property Process mkdir: Process {
        command: ["bash", "-c", "command -v cliphist >/dev/null && mkdir -p '" + root.cacheDir + "' || true"]
    }
}
