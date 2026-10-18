import QtQuick
import Quickshell
import Quickshell.Io

// Reads /proc and /sys directly -- no python/psutil subprocess. Mirrors the
// quantities Atoll's StatsManager exposes for the stats grid: CPU, memory, GPU
// (best-effort, sysfs), network up/down and disk read/write rates, each with a
// short history for the sparkline cards.
QtObject {
    id: root

    property real cpuUsage: 0.0
    property real ramUsage: 0.0
    property int ramUsedMb: 0
    property int ramTotalMb: 0
    property int batteryPercent: 100
    property bool isCharging: false

    property real gpuUsage: 0.0
    property bool hasGpu: false

    // Poll interval (ms); set from Settings > Developer > Stats interval.
    property real intervalMs: 1500

    property real netDown: 0    // bytes/s (received)
    property real netUp: 0      // bytes/s (transmitted)
    property real diskRead: 0   // bytes/s
    property real diskWrite: 0  // bytes/s

    // Ring buffers (newest last) feeding the sparkline graphs.
    readonly property int historyLength: 40
    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []
    property var netDownHistory: []
    property var netUpHistory: []
    property var diskReadHistory: []
    property var diskWriteHistory: []

    // previous /proc/stat jiffies (for the CPU delta)
    property real _prevTotal: 0
    property real _prevIdle: 0
    // previous cumulative counters (bytes) + wall clock for rate deltas
    property real _prevNetRx: -1
    property real _prevNetTx: -1
    property real _prevDiskR: -1
    property real _prevDiskW: -1
    property real _prevTime: 0

    property Timer timer: Timer {
        interval: root.intervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    property Process statsProc: Process {
        command: ["bash", "-c",
            "head -1 /proc/stat; " +
            "grep -E 'MemTotal|MemAvailable' /proc/meminfo; " +
            "for b in /sys/class/power_supply/BAT*; do " +
            "  if [ -e \"$b/capacity\" ]; then cat \"$b/capacity\"; cat \"$b/status\"; break; fi; " +
            "done; " +
            "g=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1); " +
            "if [ -n \"$g\" ]; then echo \"GPU $g\"; fi; " +
            "awk 'NR>2{split($0,a,\":\"); if(a[1]!=\"lo\" && a[1]!~\"lo$\"){split(a[2],b,\" \"); rx+=b[1]; tx+=b[9]}} END{printf \"NET %.0f %.0f\\n\", rx, tx}' /proc/net/dev; " +
            "awk '$3 ~ /^(sd[a-z]+|hd[a-z]+|vd[a-z]+|xvd[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+)$/ {r+=$6; w+=$10} END{printf \"DISK %.0f %.0f\\n\", r*512, w*512}' /proc/diskstats"]

        stdout: SplitParser {
            onRead: line => root.handleLine(line.trim())
        }
    }

    function _push(arr, value) {
        var a = arr.slice();
        a.push(value);
        while (a.length > root.historyLength) a.shift();
        return a;
    }

    function _rate(cur, prev, dtMs) {
        if (prev < 0 || dtMs <= 0) return 0;
        return Math.max(0, (cur - prev) / (dtMs / 1000));
    }

    function handleLine(line) {
        if (line.length === 0) return;

        if (line.indexOf("cpu ") === 0) {
            var f = line.split(/\s+/).slice(1);
            var idle = (Number(f[3]) || 0) + (Number(f[4]) || 0);
            var total = 0;
            for (var i = 0; i < f.length; i++) total += Number(f[i]) || 0;

            if (root._prevTotal > 0) {
                var dt = total - root._prevTotal;
                var di = idle - root._prevIdle;
                if (dt > 0) root.cpuUsage = Math.max(0, Math.min(100, (1 - di / dt) * 100));
            }
            root._prevTotal = total;
            root._prevIdle = idle;
            root.cpuHistory = root._push(root.cpuHistory, root.cpuUsage);

        } else if (line.indexOf("MemTotal:") === 0) {
            root.ramTotalMb = Math.round((Number(line.split(/\s+/)[1]) || 0) / 1024);

        } else if (line.indexOf("MemAvailable:") === 0) {
            var avail = Math.round((Number(line.split(/\s+/)[1]) || 0) / 1024);
            root.ramUsedMb = Math.max(0, root.ramTotalMb - avail);
            root.ramUsage = root.ramTotalMb > 0 ? (root.ramUsedMb / root.ramTotalMb) * 100 : 0;
            root.memHistory = root._push(root.memHistory, root.ramUsage);

        } else if (line.indexOf("GPU ") === 0) {
            root.gpuUsage = Number(line.split(/\s+/)[1]) || 0;
            root.hasGpu = true;
            root.gpuHistory = root._push(root.gpuHistory, root.gpuUsage);

        } else if (line.indexOf("NET ") === 0) {
            var nf = line.split(/\s+/);
            var now = Date.now();
            var dtMs = root._prevTime > 0 ? (now - root._prevTime) : 0;
            root.netDown = root._rate(Number(nf[1]) || 0, root._prevNetRx, dtMs);
            root.netUp = root._rate(Number(nf[2]) || 0, root._prevNetTx, dtMs);
            root._prevNetRx = Number(nf[1]) || 0;
            root._prevNetTx = Number(nf[2]) || 0;
            root.netDownHistory = root._push(root.netDownHistory, root.netDown);
            root.netUpHistory = root._push(root.netUpHistory, root.netUp);

        } else if (line.indexOf("DISK ") === 0) {
            var df = line.split(/\s+/);
            var now2 = Date.now();
            var dtMs2 = root._prevTime > 0 ? (now2 - root._prevTime) : 0;
            root.diskRead = root._rate(Number(df[1]) || 0, root._prevDiskR, dtMs2);
            root.diskWrite = root._rate(Number(df[2]) || 0, root._prevDiskW, dtMs2);
            root._prevDiskR = Number(df[1]) || 0;
            root._prevDiskW = Number(df[2]) || 0;
            root.diskReadHistory = root._push(root.diskReadHistory, root.diskRead);
            root.diskWriteHistory = root._push(root.diskWriteHistory, root.diskWrite);
            root._prevTime = now2;

        } else if (/^\d+$/.test(line)) {
            root.batteryPercent = parseInt(line);

        } else if (line === "Charging" || line === "Full") {
            root.isCharging = true;
        } else if (line === "Discharging" || line === "Not charging") {
            root.isCharging = false;
        }
    }
}
