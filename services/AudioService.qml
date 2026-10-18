import QtQuick
import Quickshell
import Quickshell.Io

// PipeWire/PulseAudio control via pactl -- no daemon of our own.
//
// Feeds: the media output menu (Devices > "Media output control") and the
// volume HUD (Controls > System HUD). `pactl subscribe` streams server events so
// volume changes are picked up with no polling.
QtObject {
    id: root

    // ---- Sinks (output devices) ----
    property var sinks: []          // [{ index, name, desc }]
    property string defaultSink: ""
    readonly property string defaultSinkDesc: {
        for (var i = 0; i < sinks.length; i++) {
            if (sinks[i].name === defaultSink) return sinks[i].desc;
        }
        return defaultSink;
    }

    // ---- Volume / mute of the default sink ----
    property real volume: 0.0       // 0..1
    property bool muted: false
    readonly property int volumePercent: Math.round(volume * 100)

    // External changes (a media key, another app) vs changes we made here; the
    // HUD shows for both, but "Custom OSD" only takes over the external ones.
    signal externalVolumeChange()
    signal internalVolumeChange()

    // Wall clock of our own last write, so the subscribe echo is not mistaken
    // for an external change.
    property double _lastWrite: 0
    // Set when a server event looks external; the signal is emitted only once
    // the volume re-read has actually landed, so the HUD never shows a stale
    // value (the read is a process round-trip).
    property bool _wantExternal: false

    function refreshSinks() {
        sinksProc.running = true;
    }

    function refreshVolume() {
        volumeProc.running = true;
    }

    function setDefaultSink(name) {
        sinkSetProc.command = ["pactl", "set-default-sink", name];
        sinkSetProc.running = true;
        root.defaultSink = name;
    }

    function setVolume(v) {
        var pct = Math.max(0, Math.min(1, v));
        root.volume = pct;
        root._lastWrite = Date.now();
        root.internalVolumeChange();
        if (root.muted && pct > 0) {
            root.muted = false;
            muteProc.command = ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "0"];
            muteProc.running = true;
        }
        volumeSetProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@",
                                 String(Math.round(pct * 100)) + "%"];
        volumeSetProc.running = true;
    }

    function adjustVolume(delta) { setVolume(root.volume + delta); }

    function toggleMute() {
        root.muted = !root.muted;
        root._lastWrite = Date.now();
        root.internalVolumeChange();
        muteProc.command = ["pactl", "set-sink-mute", "@DEFAULT_SINK@", root.muted ? "1" : "0"];
        muteProc.running = true;
    }

    // ---- Processes ----
    property Process sinksProc: Process {
        command: ["bash", "-c", "pactl -f json list sinks 2>/dev/null || pactl list short sinks"]
        stdout: SplitParser {
            onRead: data => root.parseSinks(data)
        }
    }

    property Process defaultSinkProc: Process {
        command: ["pactl", "get-default-sink"]
        stdout: SplitParser {
            onRead: data => { var s = data.trim(); if (s !== "") root.defaultSink = s; }
        }
    }

    property Process volumeProc: Process {
        command: ["bash", "-c",
            "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1; " +
            "pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}'"]
        stdout: SplitParser {
            onRead: data => root.parseVolume(data)
        }
        onRunningChanged: {
            if (!running && root._wantExternal) {
                root._wantExternal = false;
                root.externalVolumeChange();
            }
        }
    }

    property Process volumeSetProc: Process {}
    property Process muteProc: Process {}
    property Process sinkSetProc: Process {}

    // Long-lived: every server event re-reads volume + sink list.
    property Process subscribeProc: Process {
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.toLowerCase();
                if (line.indexOf("sink") === -1 && line.indexOf("server") === -1) return;
                volumeDebounce.restart();
                sinksDebounce.restart();
            }
        }
    }

    property Timer volumeDebounce: Timer {
        interval: 120
        onTriggered: {
            // Ignore the echo of a change we just made ourselves; otherwise
            // remember to announce it once the fresh value arrives.
            root._wantExternal = Date.now() - root._lastWrite > 600;
            root.refreshVolume();
        }
    }

    property Timer sinksDebounce: Timer {
        interval: 300
        onTriggered: root.refreshSinks()
    }

    Component.onCompleted: {
        refreshSinks();
        defaultSinkProc.running = true;
        refreshVolume();
    }

    function parseSinks(text) {
        var out = [];
        var t = text.trim();
        if (t === "") { root.sinks = out; return; }
        // JSON form (pactl -f json) preferred; fall back to the short table.
        if (t.charAt(0) === "[") {
            try {
                var arr = JSON.parse(t);
                for (var i = 0; i < arr.length; i++) {
                    out.push({
                        index: arr[i].index,
                        name: arr[i].name,
                        desc: (arr[i].description || arr[i].name)
                    });
                }
            } catch (e) { /* fall through to short form */ }
        }
        if (out.length === 0) {
            var lines = t.split("\n");
            for (var j = 0; j < lines.length; j++) {
                var f = lines[j].split("\t");
                if (f.length >= 2) out.push({ index: Number(f[0]), name: f[1], desc: f.length > 3 ? f[3] : f[1] });
            }
        }
        if (out.length > 0) {
            root.sinks = out;
            if (root.defaultSink === "") defaultSinkProc.running = true;
        }
    }

    function parseVolume(text) {
        var lines = text.trim().split("\n");
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim();
            if (l.endsWith("%")) {
                root.volume = Math.max(0, Math.min(1, parseInt(l) / 100));
            } else if (l === "yes" || l === "no") {
                root.muted = (l === "yes");
            }
        }
    }
}
