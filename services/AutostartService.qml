import QtQuick
import Quickshell
import Quickshell.Io

// "Launch at login" (General). Writes/removes a freedesktop autostart entry that
// starts the shell the same way `atoll start` does.
QtObject {
    id: root

    readonly property string configHome: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config"))
    readonly property string dir: configHome + "/autostart"
    readonly property string path: dir + "/atoll.desktop"

    property bool enabled: false
    // Quickshell.shellDir is a url ("file:///path"); the Exec line needs a path.
    property string shellDir: String(Quickshell.shellDir).replace(/^file:\/\//, "")

    readonly property string desktopEntry:
        "[Desktop Entry]\n" +
        "Type=Application\n" +
        "Name=Atoll for Linux\n" +
        "Comment=Dynamic Island for Linux\n" +
        // The install path can contain spaces, so the executable must be quoted
        // per the Desktop Entry spec.
        "Exec=\"" + root.shellDir + "/bin/atoll\" start\n" +
        "X-GNOME-Autostart-enabled=true\n" +
        "Terminal=false\n"

    function apply(value) {
        root.enabled = value;
        if (value) writeProc.running = true;
        else removeProc.running = true;
    }

    property Process writeProc: Process {
        // %b so the \n escapes in the entry become real newlines.
        command: ["bash", "-c",
            "mkdir -p " + JSON.stringify(root.dir) + " && printf %b " +
            JSON.stringify(root.desktopEntry) + " > " + JSON.stringify(root.path)]
    }

    property Process removeProc: Process {
        command: ["bash", "-c", "rm -f " + JSON.stringify(root.path)]
    }

    property Process checkProc: Process {
        command: ["bash", "-c", "[ -f " + JSON.stringify(root.path) + " ] && echo yes || echo no"]
        stdout: SplitParser {
            onRead: line => { if (line.trim() !== "") root.enabled = (line.trim() === "yes"); }
        }
    }

    Component.onCompleted: checkProc.running = true
}
