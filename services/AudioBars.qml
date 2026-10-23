pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared playback spectrum: one cava feed (PipeWire playback monitor,
// 40 bands / 30fps) drives the MediaWidget visualizer and any other music
// surface that wants a live analyser. Owner-refcounted — the analyser runs
// only while a visible surface claims it via setActive(owner, true).
// Levels settle flat when frames stop arriving (system silent, a restart
// gap, or the last owner releasing), so bars fall to rest instead of
// freezing on the last peak.
//
// Ported from Ryoku's shell/services/AudioBars.qml (same cava config:
// pipewire backend, ascii raw output, noise_reduction 45).
QtObject {
    id: root

    property var activeOwners: []
    readonly property bool active: activeOwners.length > 0

    function setActive(owner, enabled) {
        var arr = activeOwners.slice();
        var i = arr.indexOf(owner);
        if (enabled && i === -1) arr.push(owner);
        else if (!enabled && i !== -1) arr.splice(i, 1);
        activeOwners = arr;
    }

    readonly property int bars: 40
    readonly property int fps: 30

    // 0..1 per band + mean energy across all bands.
    property var levels: root.flat()
    property real energy: 0
    property real lastReadMs: 0

    function flat() {
        var a = [];
        for (var i = 0; i < root.bars; i++)
            a.push(0);
        return a;
    }

    // The live analyser. `running` is bound (never assigned) so every gate —
    // playback, visibility, the settings toggle — keeps working after a
    // restart. cava's native pipewire backend reads the default sink's
    // monitor with no pactl; exec so Quickshell's SIGTERM reaches cava and
    // leaves no orphaned analyser when the surface unloads.
    property Process cavaProc: Process {
        command: ["sh", "-c",
            "command -v cava >/dev/null 2>&1 || exit 0; "
            + "cfg=\"${XDG_RUNTIME_DIR:-/tmp}/atoll-cava-viz.conf\"; "
            + "printf '%s\\n' '[general]' 'framerate = " + root.fps + "' 'bars = " + root.bars + "' '' "
            + "'[input]' 'method = pipewire' 'source = auto' '' "
            + "'[output]' 'method = raw' 'raw_target = /dev/stdout' 'data_format = ascii' 'ascii_max_range = 100' 'channels = mono' 'mono_option = average' '' "
            + "'[smoothing]' 'noise_reduction = 45' > \"$cfg\"; exec cava -p \"$cfg\""]
        running: root.active && !cavaProc.backoff
        property bool backoff: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => root.readBars(line)
        }
        // cava exiting while we still want it (a transient pipewire hiccup)
        // earns one paced retry rather than a spin.
        onExited: if (root.active) {
            cavaProc.backoff = true;
            restartTimer.restart();
        }
    }

    property Timer restartTimer: Timer {
        interval: 1200
        onTriggered: cavaProc.backoff = false
    }

    // cava stops emitting frames once playback idles, so settle back to flat
    // when no frame has arrived recently.
    property Timer settleTimer: Timer {
        interval: 120
        running: root.active
        repeat: true
        onTriggered: if (Date.now() - root.lastReadMs > 260) {
            root.levels = root.flat();
            root.energy = 0;
        }
    }

    onActiveChanged: {
        levels = flat();
        energy = 0;
        if (active)
            lastReadMs = 0;
    }

    function norm(v) {
        var n = parseInt(v);
        if (isNaN(n))
            return 0;
        return Math.max(0, Math.min(1, n / 100));
    }

    // One cava line: "v1;v2;...;v40;" — semicolon or whitespace separated
    // integers in 0..ascii_max_range.
    function readBars(line) {
        var t = line.trim();
        if (!t)
            return;
        var parts = t.split(/[;\s]+/);
        if (parts.length < root.bars)
            return;
        var out = [];
        var sum = 0;
        for (var i = 0; i < root.bars; i++) {
            var v = root.norm(parts[i]);
            out.push(v);
            sum += v;
        }
        root.levels = out;
        root.energy = sum / root.bars;
        root.lastReadMs = Date.now();
    }
}
