import QtQuick
import Quickshell.Io
import "../theme"
import "../components/lyrics.js" as Lyrics

// Fetches synced lyrics and keeps the current line in sync with playback.
//
// Atoll's MusicManager asks the keyless lrclib.net search endpoint
// (fetchLyricsFromAPI) and falls back to NetEase; the lrclib result carries
// both `plainLyrics` and `syncedLyrics`. We only need the first source, which is
// reachable without a key.
//
// Track state is pushed in from NotchContainer rather than read from MPRIS here
// so this service stays free of the Quickshell MPRIS module (it is the same
// split the Swift manager has: the manager owns the fetch, the view feeds it).
QtObject {
    id: svc

    // ---- Inputs (bound by the host) ----
    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property real position: 0          // seconds, from the player
    property real duration: 0          // seconds
    property bool isPlaying: false
    property bool enabled: false

    // ---- Outputs ----
    property var lines: []             // [{ t, text, timed }]
    property string availability: "unavailable" // unavailable | loading | timed | plain | instrumental
    property int currentIndex: -1
    property string currentLine: ""
    property bool isInstrumentalBreak: false
    property real sweepProgress: 0
    property string placeholder: "Show lyrics here"

    readonly property bool hasTimedLyrics: Lyrics.hasTimed(lines)

    // ---- Playback clock ----
    // MPRIS only reports the position at discrete moments (a seek, or a poll),
    // so the sync clock is advanced locally between reports. The same estimate
    // the Swift manager uses (estimatedPlaybackPosition).
    property real basePosition: 0
    property double baseStamp: 0

    function syncClock() {
        svc.basePosition = svc.position;
        svc.baseStamp = Date.now();
    }

    onPositionChanged: svc.syncClock()
    onIsPlayingChanged: svc.syncClock()

    function estimatedPosition() {
        if (!svc.isPlaying) return svc.basePosition;
        return svc.basePosition + (Date.now() - svc.baseStamp) / 1000.0;
    }

    // 30fps redraw while playing so the highlight tracks the voice without
    // stepping line by line. Idle, it just resolves the static text.
    property Timer tick: Timer {
        interval: 33
        repeat: true
        running: svc.enabled && svc.isPlaying && svc.lines.length > 0
        onTriggered: svc.update()
        onRunningChanged: if (running) svc.update()
    }

    function update() {
        if (!svc.hasTimedLyrics) {
            if (svc.currentIndex !== -1) svc.currentIndex = -1;
            if (svc.currentLine !== "") svc.currentLine = "";
            svc.isInstrumentalBreak = false;
            svc.sweepProgress = 0;
            return;
        }
        var pos = svc.estimatedPosition();
        var idx = Lyrics.currentIndex(svc.lines, pos, Atoll.leadTime);
        var text = (idx >= 0 && idx < svc.lines.length) ? svc.lines[idx].text : "";
        if (idx !== svc.currentIndex) svc.currentIndex = idx;
        if (text !== svc.currentLine) svc.currentLine = text;
        svc.isInstrumentalBreak = Lyrics.isInstrumentalBreak(svc.lines, idx, svc.duration, Atoll.instrumentalBreakThreshold);
        svc.sweepProgress = Lyrics.sweepProgress(svc.lines, idx, pos, svc.duration, Atoll.leadTime);
    }

    // ---- Fetching ----
    property var cache: ({})
    property string activeKey: ""
    property string fetchKey: ""

    function normalized(s) {
        if (!s) return "";
        return String(s).replace(/\s+/g, " ").trim();
    }

    // Strips feature/remaster suffixes, matching normalizedLyricsTitle.
    function cleanTitle(s) {
        var t = svc.normalized(s);
        var pats = [
            /\s*\((feat\.?|ft\.?|featuring)[^)]*\)/ig,
            /\s*\[(feat\.?|ft\.?|featuring)[^\]]*\]/ig,
            /\s*-\s*(feat\.?|ft\.?|featuring)\s+.*$/ig,
            /\s*\((remaster(ed)?|live|mono|stereo)[^)]*\)$/ig,
            /\s*\[(remaster(ed)?|live|mono|stereo)[^\]]*\]$/ig
        ];
        for (var i = 0; i < pats.length; i++) t = t.replace(pats[i], "");
        return svc.normalized(t);
    }

    readonly property string lookupTitle: svc.cleanTitle(svc.trackTitle)
    readonly property string lookupArtist: svc.normalized(svc.trackArtist)

    readonly property string lookupKey: {
        if (!svc.enabled) return "";
        var title = svc.lookupTitle.toLowerCase();
        var artist = svc.lookupArtist.toLowerCase();
        if (title === "" || artist === "") return "";
        if (title === "unknown track" || artist === "unknown artist") return "";
        return title + "\u0000" + artist;
    }

    onLookupKeyChanged: {
        svc.retries = 0;
        fetchTimer.restart();
    }

    onEnabledChanged: {
        if (svc.enabled) fetchTimer.restart();
        else svc.clear();
    }

    property Timer fetchTimer: Timer {
        interval: 350
        repeat: false
        onTriggered: svc.prepare()
    }

    function clear() {
        svc.lines = [];
        svc.availability = "unavailable";
        svc.currentIndex = -1;
        svc.currentLine = "";
        svc.isInstrumentalBreak = false;
        svc.sweepProgress = 0;
        svc.activeKey = "";
        svc.fetchKey = "";
    }

    function prepare(force) {
        if (!svc.enabled) { svc.clear(); return; }
        var key = svc.lookupKey;
        if (key === "") { svc.clear(); return; }
        if (key === svc.activeKey && !force) return;

        svc.activeKey = key;
        svc.currentIndex = -1;
        svc.currentLine = "";

        if (svc.cache[key] !== undefined) {
            svc.apply(svc.cache[key]);
            return;
        }
        if (svc.fetchKey === key) return;
        svc.fetchKey = key;
        svc.lines = [];
        svc.availability = "loading";

        var url = "https://lrclib.net/api/search?track_name="
                + encodeURIComponent(svc.lookupTitle)
                + "&artist_name=" + encodeURIComponent(svc.lookupArtist);
        fetchProc.command = ["curl", "-s", "--max-time", "10",
            "-H", "User-Agent: Atoll-for-Linux/1.0 (https://github.com/RaunakxShrivastva/Atollforlinux)",
            url];
        fetchProc.running = true;
    }

    property Process fetchProc: Process {
        stdout: StdioCollector {
            onStreamFinished: svc.handleResponse(this.text)
        }
        onExited: (code, status) => {
            // A failed request is not a fact about the track; keep it uncached
            // so a later attempt can succeed.
            if (code !== 0) {
                svc.fetchKey = "";
                if (svc.availability === "loading") svc.availability = "unavailable";
                svc.retryTimer.restart();
            }
        }
    }

    // A transient failure (network hiccup, a rate-limited or truncated
    // response) must not leave the panel stuck on "No lyrics found" for the
    // rest of the track, so try again a couple of times before giving up.
    property int retries: 0
    property Timer retryTimer: Timer {
        interval: 8000
        repeat: false
        onTriggered: {
            if (!svc.enabled || svc.lines.length > 0 || svc.retries >= 3) return;
            svc.retries++;
            svc.fetchKey = "";
            svc.prepare(true);
        }
    }


    function handleResponse(text) {
        if (svc.fetchKey === "") return;
        var key = svc.fetchKey;
        svc.fetchKey = "";
        var results = null;
        try { results = JSON.parse(text); } catch (e) { results = null; }
        if (!results || !Array.isArray(results)) {
            // A malformed body is a transport problem, not an answer: retry
            // instead of caching a false "no lyrics".
            if (svc.activeKey === key) {
                svc.availability = "unavailable";
                svc.placeholder = "No lyrics found";
                svc.retryTimer.restart();
            }
            return;
        }
        var body = svc.pick(results);
        svc.cache[key] = body;
        if (svc.activeKey === key) svc.apply(body);
    }

    // Prefers a timed match at the same duration, then any timed match, then a
    // plain one. Mirrors the ordering LyricsSearchResults.bestMatch applies.
    function pick(results) {
        var bestTimed = null;
        var bestPlain = null;
        var bestTimedDelta = 1e9;
        for (var i = 0; i < results.length; i++) {
            var r = results[i];
            if (!r) continue;
            var synced = r.syncedLyrics || "";
            var plain = r.plainLyrics || "";
            if (r.instrumental === true && synced === "" && plain === "") {
                if (bestTimed === null) bestTimed = r;
                continue;
            }
            if (synced !== "") {
                var delta = svc.duration > 0 && r.duration
                    ? Math.abs(Number(r.duration) - svc.duration) : 0;
                if (bestTimed === null || delta < bestTimedDelta) {
                    bestTimed = r;
                    bestTimedDelta = delta;
                }
            } else if (plain !== "" && bestPlain === null) {
                bestPlain = r;
            }
        }
        var chosen = bestTimed || bestPlain;
        if (!chosen) return { lines: [], availability: "unavailable" };
        return Lyrics.resolve(chosen.syncedLyrics, chosen.plainLyrics, chosen.instrumental);
    }

    function apply(body) {
        svc.lines = body.lines || [];
        svc.availability = body.availability || "unavailable";
        svc.currentIndex = -1;
        svc.currentLine = "";
        svc.isInstrumentalBreak = false;
        svc.sweepProgress = 0;
        if (svc.availability === "instrumental") svc.placeholder = "Instrumental";
        else if (svc.lines.length === 0) svc.placeholder = "No lyrics found";
        else svc.placeholder = "Show lyrics here";
        svc.syncClock();
        svc.update();
    }

    // ---- Derived views for the panel and the closed-notch pin ----
    readonly property var rows: Lyrics.buildRows(svc.lines, svc.duration, Atoll.instrumentalBreakThreshold)

    function pinnedSlots(context) {
        return Lyrics.pinnedSlots(svc.lines, svc.duration, svc.currentIndex, context, Atoll.instrumentalBreakThreshold);
    }
}
