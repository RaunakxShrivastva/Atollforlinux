import QtQuick
import Quickshell
import Quickshell.Io

// Downloads (Appearance / General > "Downloads widget"). Lists the most recent
// files in `downloadsPath`, newest first, capped by "Shelf max items".
QtObject {
    id: root

    property string dir: "~/Downloads"
    property int maxItems: 8
    property var entries: []
    property bool refreshing: false

    function refresh() {
        refreshProc.running = true;
    }

    function open(path) {
        openProc.command = ["xdg-open", path];
        openProc.running = true;
    }

    property Process refreshProc: Process {
        command: ["bash", "-c",
            "d=\"" + root.dir.replace("~", "$HOME") + "\"; " +
            "for f in \"$d\"/*; do [ -f \"$f\" ] || continue; " +
            "printf '%s\\t%s\\t%s\\n' \"$(stat -c %Y \"$f\")\" \"$(stat -c %s \"$f\")\" \"$f\"; " +
            "done | sort -rn | head -n " + root.maxItems]
        stdout: SplitParser {
            onRead: line => {
                var parts = line.split("\t");
                if (parts.length < 3) return;
                var p = parts[2];
                var name = p.substring(p.lastIndexOf("/") + 1);
                root.entries = root.entries.concat([{
                    name: name,
                    path: p,
                    size: Number(parts[1]),
                    mtime: Number(parts[0])
                }]);
            }
        }
        onRunningChanged: {
            if (running) { root.refreshing = true; root.entries = []; }
            else root.refreshing = false;
        }
    }

    function sizeText(bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(0) + " KB";
        if (bytes < 1024 * 1024 * 1024) return (bytes / 1048576).toFixed(1) + " MB";
        return (bytes / 1073741824).toFixed(2) + " GB";
    }

    property Process openProc: Process {}

    property Timer poll: Timer {
        interval: 8000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
