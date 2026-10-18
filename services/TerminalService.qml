pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Terminal tab backend (Developer > Terminal), standing in for Atoll's
// TerminalManager.
//
// Atoll embeds SwiftTerm's `LocalProcessTerminalView` — a full VT emulator
// NSView driven by a PTY. A Wayland layer surface cannot host a native window
// and Quickshell has no terminal widget or PTY, so the tab cannot contain a
// live shell here. What it does instead is the Linux-first equivalent:
//   * resolve the terminal emulator available on this machine (`auto`),
//   * launch it running the configured shell (the guake-style dropdown role),
//   * run one-off commands through a plain pipe and show their output inline,
//     which needs no PTY and gives the tab something genuinely useful.
// `title` mirrors Atoll's terminalTitle (the shell's reported title, or the
// last command).
QtObject {
    id: root

    // Emulators we know how to launch, most-preferred first.
    readonly property var known: ["kitty", "foot", "ghostty", "wezterm", "alacritty",
                                  "konsole", "gnome-terminal", "xfce4-terminal", "xterm"]
    // How each takes a command to run in the new window.
    readonly property var execFlag: ({
        "gnome-terminal": "--",
        "xfce4-terminal": "-x"
    })

    property string emulator: ""          // resolved binary name, "" = none found
    property bool probed: false
    property bool busy: false
    property string title: "Terminal"
    property string output: ""            // transcript of the last command
    property string lastCommand: ""

    // `output`'s own change signal (outputChanged) notifies the view.
    signal launched(string command)

    // Prefer the configured emulator, else the first one installed.
    function resolve() {
        var pref = String(Settings.values.terminalEmulator || "auto");
        if (pref !== "" && pref !== "auto") {
            root.emulator = pref;
            root.probed = true;
            return;
        }
        if (root.emulator !== "" || root.probed) return;
        probe.running = true;
    }

    property Process probe: Process {
        command: ["sh", "-c",
            "for t in " + root.known.join(" ") + "; do"
            + " command -v \"$t\" >/dev/null 2>&1 && { echo \"$t\"; break; }; done"]
        stdout: SplitParser {
            onRead: line => {
                var v = line.trim();
                if (v !== "") root.emulator = v;
            }
        }
        onExited: root.probed = true
    }

    // The configured shell's argv tail for the emulator.
    function shellName() {
        var s = String(Settings.values.terminalShell || "bash");
        return s === "" ? "bash" : s;
    }

    function flagFor(bin) {
        return root.execFlag[bin] !== undefined ? root.execFlag[bin] : "-e";
    }

    // Opens the emulator running the configured shell. Returns the command it
    // spawned (for the transcript), or "" when no emulator is available.
    function launch() {
        root.resolve();
        if (root.emulator === "") {
            root.append("[no terminal emulator found - install kitty, foot, konsole or xterm]");
            return "";
        }
        var cmd = root.emulator + " " + root.flagFor(root.emulator) + " " + root.shellName();
        root.title = root.shellName();
        root.append("$ " + cmd);
        runner.command = ["sh", "-c", cmd + " >/dev/null 2>&1 &"];
        runner.running = true;
        root.launched(cmd);
        return cmd;
    }

    // One-off command through a pipe (no PTY needed). Output is appended to the
    // transcript and echoed back through `outputChanged`.
    function run(command) {
        var cmd = String(command || "").trim();
        if (cmd === "" || root.busy) return;
        root.busy = true;
        root.lastCommand = cmd;
        root.title = cmd;
        root.append("$ " + cmd);
        runProc.command = ["sh", "-c", cmd + " 2>&1"];
        runProc.running = true;
    }

    property Process runProc: Process {
        stdout: StdioCollector {
            onStreamFinished: root.append(root.trimmed(this.text))
        }
        onExited: {
            root.busy = false;
        }
    }

    property Process runner: Process {}

    function trimmed(text) {
        var t = String(text || "");
        while (t.length > 0 && (t.charAt(t.length - 1) === "\n" || t.charAt(t.length - 1) === "\r"))
            t = t.substring(0, t.length - 1);
        return t;
    }

    function append(text) {
        var t = String(text || "");
        if (t === "") return;
        var next = root.output === "" ? t : root.output + "\n" + t;
        // Keep the transcript bounded (Atoll's terminalScrollbackLines stand-in).
        var lines = next.split("\n");
        if (lines.length > 400) next = lines.slice(lines.length - 400).join("\n");
        root.output = next;
    }

    function clear() {
        root.output = "";
        root.title = "Terminal";
        root.lastCommand = "";
    }

    Component.onCompleted: root.resolve()
}
