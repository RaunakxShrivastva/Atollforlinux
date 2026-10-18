import QtQuick
import Quickshell
import Quickshell.Io

// Screen + keyboard backlight, read straight from sysfs so it works on any
// distro. Feeds the brightness HUD (Controls > System HUD) by watching the raw
// value: an external brightness key writes the same file, so a change is our
// cue to raise the OSD (no compositor hook required).
QtObject {
    id: root

    property string device: ""          // e.g. intel_backlight / amdgpu_bl1
    property int maxBrightness: 1
    property real brightness: 0.0       // 0..1
    readonly property int brightnessPercent: Math.round(brightness * 100)
    readonly property bool available: device !== "" && maxBrightness > 0

    property string kbdDevice: ""       // e.g. smc::kbd_backlight
    property int kbdMaxBrightness: 1
    property real kbdBrightness: 0.0
    readonly property bool kbdAvailable: kbdDevice !== ""
    readonly property int kbdBrightnessPercent: Math.round(kbdBrightness * 100)

    // Raised when the value changes from outside this service (a brightness key)
    // vs a change we made here (the island's own control).
    signal externalBrightnessChange()
    signal externalKbdChange()
    signal internalBrightnessChange()
    signal internalKbdChange()

    property bool _applying: false

    function refresh() { readProc.running = true; }

    function setBrightness(v) {
        if (!available) return;
        var pct = Math.max(1, Math.min(100, Math.round(v * 100)));
        root.brightness = pct / 100;
        root._applying = true;
        root.internalBrightnessChange();
        writeProc.command = ["bash", "-c",
            "brightnessctl -d " + root.device + " set " + pct + "% 2>/dev/null || " +
            "echo " + Math.round(root.maxBrightness * pct / 100) +
            " | sudo -n tee /sys/class/backlight/" + root.device + "/brightness >/dev/null 2>&1 || true"];
        writeProc.running = true;
    }

    function adjustBrightness(delta) { setBrightness(root.brightness + delta); }

    function setKbd(v) {
        if (!kbdAvailable) return;
        var pct = Math.max(0, Math.min(100, Math.round(v * 100)));
        root.kbdBrightness = pct / 100;
        root._applying = true;
        root.internalKbdChange();
        writeProc2.command = ["bash", "-c",
            "brightnessctl -d " + root.kbdDevice + " set " + pct + "% 2>/dev/null || true"];
        writeProc2.running = true;
    }

    property Process readProc: Process {
        command: ["bash", "-c",
            "b=/sys/class/backlight; " +
            "for d in \"$b\"/*; do " +
            "  [ -e \"$d/max_brightness\" ] || continue; " +
            "  echo BACKLIGHT $(basename \"$d\") $(cat \"$d/brightness\") $(cat \"$d/max_brightness\"); " +
            "  break; " +
            "done; " +
            "for l in /sys/class/leds/*kbd_backlight*; do " +
            "  [ -e \"$l/max_brightness\" ] || continue; " +
            "  echo KBD $(basename \"$l\") $(cat \"$l/brightness\") $(cat \"$l/max_brightness\"); " +
            "  break; " +
            "done"]
        stdout: SplitParser {
            onRead: data => root.parse(data.trim())
        }
    }

    property Process writeProc: Process {
        onExited: root._applying = false
    }
    property Process writeProc2: Process {
        onExited: root._applying = false
    }

    function parse(line) {
        if (line === "") return;
        var f = line.split(" ");
        if (f[0] === "BACKLIGHT" && f.length >= 4) {
            var cur = Number(f[2]) / Number(f[3]);
            var first = root.device === "";
            if (first) root.device = f[1];
            root.maxBrightness = Number(f[3]);
            if (Math.abs(cur - root.brightness) > 0.005) {
                root.brightness = cur;
                if (!first && !root._applying) root.externalBrightnessChange();
            }
        } else if (f[0] === "KBD" && f.length >= 4) {
            var cur2 = Number(f[2]) / Number(f[3]);
            var first2 = root.kbdDevice === "";
            if (first2) root.kbdDevice = f[1];
            root.kbdMaxBrightness = Number(f[3]);
            if (Math.abs(cur2 - root.kbdBrightness) > 0.005) {
                root.kbdBrightness = cur2;
                if (!first2 && !root._applying) root.externalKbdChange();
            }
        }
    }

    // Poll: there is no sysfs change notification for the backlight.
    property Timer poll: Timer {
        interval: 350
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
