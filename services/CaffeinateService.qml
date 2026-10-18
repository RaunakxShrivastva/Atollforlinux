import QtQuick
import Quickshell
import Quickshell.Io

// Caffeinate: hold a logind inhibitor so the machine (and optionally the
// display) will not sleep. Backed by systemd-inhibit, which is present on any
// systemd distro; the "sleep infinity" child is what actually holds the lock.
QtObject {
    id: root

    property bool enabled: false
    property bool keepDisplayAwake: false
    property string duration: "indefinite"   // "indefinite" or minutes as string

    readonly property bool active: enabled && inhibitProc.running

    function start(withDisplay, dur) {
        if (withDisplay !== undefined) keepDisplayAwake = withDisplay;
        if (dur !== undefined && dur !== "") duration = dur;
        enabled = true;
        inhibitProc.running = true;
        applyDuration();
    }

    function stop() {
        enabled = false;
        inhibitProc.running = false;
        durationTimer.stop();
    }

    function toggle() { enabled ? stop() : start(); }

    function applyDuration() {
        durationTimer.stop();
        var n = Number(duration);
        if (duration !== "indefinite" && isFinite(n) && n > 0) {
            durationTimer.interval = n * 60 * 1000;
            durationTimer.restart();
        }
    }

    property Process inhibitProc: Process {
        command: ["systemd-inhibit",
                  "--what=" + (root.keepDisplayAwake ? "idle:sleep" : "sleep"),
                  "--who=Atoll for Linux",
                  "--why=Caffeinate is enabled",
                  "--mode=block",
                  "sleep", "infinity"]
    }

    property Timer durationTimer: Timer {
        repeat: false
        onTriggered: root.stop()
    }
}
