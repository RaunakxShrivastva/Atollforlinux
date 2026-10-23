pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Quick Share providers for the shelf tab, the Linux counterpart of Atoll's
// QuickShareService: providers are discovered at runtime from binaries this
// machine can actually share with, and the chosen one persists in Settings.
//
//   LocalSend  — opens the LocalSend send dialog with the files attached
//   Mail       — composes a message with the files attached (xdg-email)
//   Copy Paths — puts the file paths on the clipboard (wl-copy)
//   System     — opens each file with its default handler (xdg-open); always
//                present as the fallback, like macOS's System Share Menu
QtObject {
    id: root

    // [{ id, binary }] in display order, filled by the probe below.
    property var available: []
    readonly property var candidates: [
        { id: "LocalSend",  binary: "localsend"  },
        { id: "Mail",       binary: "xdg-email"  },
        { id: "Copy Paths", binary: "wl-copy"    }
    ]

    // The persisted selection; the probe validates it against what is
    // actually installed and falls back to the first available provider.
    property string selected: String(Settings.str("quickShareProvider", ""))

    function ensureDiscovered() {
        if (available.length > 0 || probe.running) return;
        probe.running = true;
    }

    property Process probe: Process {
        command: ["sh", "-c",
            "for b in localsend xdg-email wl-copy; do"
            + " command -v \"$b\" >/dev/null 2>&1 && echo \"$b\"; done"]
        stdout: SplitParser {
            onRead: line => {
                var b = line.trim();
                if (b === "") return;
                for (var i = 0; i < root.candidates.length; i++) {
                    if (root.candidates[i].binary === b)
                        root.available.push(root.candidates[i]);
                }
                // Reassign so QML change signals fire for bindings.
                root.available = root.available.slice();
            }
        }
        onExited: {
            root.available = root.available.concat([{ id: "System", binary: "xdg-open" }]);
            // Restore the persisted choice when it still exists, else default
            // to the first available provider.
            var stored = String(Settings.str("quickShareProvider", ""));
            if (stored !== "" && root.available.some(p => p.id === stored))
                root.selected = stored;
            else
                root.selected = root.available[0].id;
        }
    }

    function select(id) {
        root.selected = id;
        Settings.set("quickShareProvider", id);
    }

    function _fileUri(path) {
        return path.startsWith("/") ? "file://" + path : path;
    }

    // `paths` are absolute local file paths. Runs the selected provider.
    function share(paths) {
        if (!paths || paths.length === 0) return;
        root.ensureDiscovered();
        var id = root.selected;
        var cmd = [];
        switch (id) {
            case "LocalSend":
                // The Linux LocalSend binary takes the files as arguments and
                // opens its send dialog with them pre-attached.
                cmd = ["localsend"].concat(paths.map(p => root._fileUri(p)));
                break;
            case "Mail":
                cmd = ["xdg-email"];
                for (var i = 0; i < paths.length; i++)
                    cmd = cmd.concat(["--attach", paths[i]]);
                break;
            case "Copy Paths":
                cmd = ["wl-copy", paths.join("\n")];
                break;
            default:
                // System: open every file with its default handler.
                for (var j = 0; j < paths.length; j++)
                    runner.launch(["xdg-open", root._fileUri(paths[j])]);
                return;
        }
        runner.launch(cmd);
    }

    // Detached launcher: sharing must not block the UI, and some targets
    // (xdg-email, localsend) outlive the call.
    property QtObject runner: QtObject {
        function launch(cmd) {
            if (cmd.length === 0) return;
            shareProc.command = ["sh", "-c",
                "\"$@\" >/dev/null 2>&1 &", "sh"].concat(cmd);
            shareProc.running = true;
        }
    }
    property Process shareProc: Process {}
}
