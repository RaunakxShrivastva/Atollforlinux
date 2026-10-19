pragma Singleton
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
//
// Favorites (Atoll's `pinnedItems`) are a second, independent list. cliphist
// has no pin concept and recycles ids, so a favorite is a copy of the content
// kept by bin/atoll-clipboard - text inline, images as PNG files under
// $XDG_DATA_HOME/atoll/clip-favorites - exactly like Atoll writing a pinned
// image out with persistImageFile() so trimming the history cannot lose it.
//
// A singleton because three surfaces share it: the notch tab (NotchContainer),
// the attached popover and the floating panel window.
QtObject {
    id: root

    property var entries: []      // [{ id, preview, kind, age, ageLong, thumb }]
    property var favorites: []    // [{ id, kind, mime, preview, age, ageLong, text?, file? }]
    property bool available: false
    // Atoll's clipboardHistorySize is the size of the history itself, so it
    // bounds both the notch card row and the popover/panel list.
    readonly property int limit: Math.max(1, Settings.num("clipboardHistorySize", 3))
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

    // ---- Favorites ------------------------------------------------------
    // Pinning reads the cliphist entry once and stores it; nothing here tracks
    // cliphist ids beyond the preview string used to mark a history row as
    // already favorited.

    readonly property string helper:
        String(Quickshell.shellDir).replace(/^file:\/\//, "") + "/bin/atoll-clipboard"
    readonly property string dataDir:
        (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/atoll"

    function refreshFavorites() { favList.running = true; }

    function pin(id) {
        favCmd.command = [root.helper, "pin", String(id)];
        favCmd.running = true;
    }

    function unpin(fid) {
        favCmd.command = [root.helper, "unpin", String(fid)];
        favCmd.running = true;
    }

    function clearFavorites() {
        favCmd.command = [root.helper, "clear"];
        favCmd.running = true;
    }

    function pickFavorite(fid) {
        favPick.command = [root.helper, "pick", String(fid)];
        favPick.running = true;
    }

    // A history row is favorited when some favorite was pinned from the same
    // cliphist preview (cliphist offers no content hash in `list`).
    function isFavorite(entry) {
        return root.favoriteFor(entry) !== null;
    }

    function favoriteFor(entry) {
        if (!entry) return null;
        var key = entry.match !== undefined ? entry.match : entry.preview;
        for (var i = 0; i < root.favorites.length; i++)
            if (root.favorites[i].match === key) return root.favorites[i];
        return null;
    }

    function favoriteThumb(fav) {
        return fav && fav.file ? "file://" + root.dataDir + "/clip-favorites/" + fav.file : "";
    }

    // An entry is copied back with the favorite's own MIME type, so a pinned
    // image returns as image/png rather than as unrecognised bytes.
    property Process favCmd: Process {
        stdout: StdioCollector {
            onStreamFinished: root.parseFavorites(this.text)
        }
    }

    property Process favPick: Process {}

    property Process favList: Process {
        command: [root.helper, "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseFavorites(this.text)
        }
    }

    function parseFavorites(text) {
        var out = [];
        try {
            var doc = JSON.parse(String(text).trim());
            var items = doc && doc.items ? doc.items : [];
            for (var i = 0; i < items.length; i++) {
                var it = items[i];
                out.push({
                    id: it.id,
                    kind: it.kind || "Text",
                    mime: it.mime || "text/plain",
                    match: it.match || "",
                    preview: it.preview || "",
                    text: it.text || "",
                    file: it.file || "",
                    thumb: root.favoriteThumb(it),
                    age: root.relativeAge((it.created || 0) * 1000),
                    ageLong: root.longAge((it.created || 0) * 1000)
                });
            }
        } catch (e) {
            out = [];
        }
        root.favorites = out;
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

    // Spelled-out variant for the popover/panel rows, matching Atoll's
    // timeAgoString(): "Just now" / "4m ago" / "2h ago" / "3d ago".
    function longAge(ms) {
        if (!ms) return "";
        var s = Math.max(0, (Date.now() - ms) / 1000);
        if (s < 60) return "Just now";
        if (s < 3600) return Math.floor(s / 60) + "m ago";
        if (s < 86400) return Math.floor(s / 3600) + "h ago";
        return Math.floor(s / 86400) + "d ago";
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
            // cliphist's preview is the payload itself for text, so a lone URL
            // can be labelled the way Atoll labels its .url items.
            var isUrl = !binary && /^https?:\/\/\S+$/.test(preview.trim())
                        && preview.split("\n").length === 1;
            var kind = binary ? "Image" : (isUrl ? "URL" : "Text");
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
                // Atoll shows the word "Image" for an image item rather than
                // cliphist's `[[ binary data ... ]]` marker.
                preview: binary ? "Image" : preview,
                // The raw cliphist preview, used to match a history entry
                // against the favorite it was pinned from.
                match: preview,
                kind: kind,
                age: root.relativeAge(root.stamps[key]),
                ageLong: root.longAge(root.stamps[key]),
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
        // "Persist clipboard history" off: cliphist always writes its store, so
        // the session-only behaviour means starting from an empty one.
        if (!Settings.persistClipboard) {
            persistWipe.command = ["bash", "-c",
                "command -v cliphist >/dev/null && cliphist wipe 2>/dev/null || true"];
            persistWipe.running = true;
        }
        refresh();
        refreshFavorites();
        watcher.running = true;
    }

    property Process persistWipe: Process {
        onRunningChanged: if (!running) root.refresh()
    }

    property Process mkdir: Process {
        command: ["bash", "-c", "command -v cliphist >/dev/null && mkdir -p '" + root.cacheDir + "' || true"]
    }
}
