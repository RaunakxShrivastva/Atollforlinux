pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Terminal tab backend (Developer > Terminal).
//
// A persistent interactive shell in a PTY (util-linux `script` allocates the
// pseudo-terminal; Quickshell's Process streams it). One session is reused
// for every command: cd, env vars, sudo passwords and job control all work
// exactly as in a real terminal. stdin is written directly, stdout/stderr
// arrive as raw byte chunks and run through a small ANSI/VT parser that
// renders SGR colours and \r/\b/erase-line into rich text.
//
// Full-screen apps (htop, vim) need a real VT emulator - that is what the
// header's "Open <emulator>" button is for.
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
    property string title: "Terminal"
    property string lastCommand: ""

    // ---- live session ----
    property bool alive: false
    property string text: ""              // rich-text transcript (HTML)

    // Parser state: the current line is a cell buffer so \r (progress bars,
    // spinners) and CSI K/J can rewrite it; finished lines are HTML strings.
    property var _lines: []
    property var _cells: []
    property int _col: 0
    property int _esc: 0                  // 0 ground, 1 ESC, 2 CSI, 3 OSC
    property string _csi: ""
    property string _osc: ""
    property var _attr: ({ c: null, bg: null, b: false, u: false })
    property var _pending: []             // sends queued before the shell starts

    readonly property var _pal: [
        "#000000", "#cd0000", "#00cd00", "#cdcd00", "#0000ee", "#cd00cd", "#00cdcd", "#e5e5e5",
        "#7f7f7f", "#ff0000", "#00ff00", "#ffff00", "#5c5cff", "#ff00ff", "#00ffff", "#ffffff"
    ]

    signal launched(string command)

    // ------------------------------------------------------------------ PTY
    readonly property string _shell: {
        var s = String(Settings.values.terminalShell || "bash");
        return s === "" ? "bash" : s;
    }

    property Process shell: Process {
        // `script -qfec` wraps the child in a PTY; stty fixes the window size
        // (the pipe side has no winsize of its own); -i forces an interactive
        // shell so readline, prompts and job control all engage.
        command: ["script", "-qfec",
            "stty cols 120 rows 24 2>/dev/null; exec " + root._shell + " -i",
            "/dev/null"]
        workingDirectory: Quickshell.env("HOME") || "/tmp"
        environment: ({ TERM: "xterm-256color", COLORTERM: "truecolor" })
        stdinEnabled: true
        onStarted: {
            root.alive = true;
            var q = root._pending;
            root._pending = [];
            for (var i = 0; i < q.length; i++) shell.write(q[i]);
        }
        onExited: {
            root.alive = false;
            if (root._restartWhenDead) {
                root._restartWhenDead = false;
                shell.running = true;
                return;
            }
            root._appendHtml("<span style=\"color:#888888\">[session ended]</span>");
        }
        // Empty splitMarker = raw streaming (preserves \r, partial lines,
        // prompts without a trailing newline).
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._feed(data)
        }
        stderr: SplitParser {
            splitMarker: ""
            onRead: data => root._feed(data)
        }
    }

    // ---------------------------------------------------------------- input
    function send(line) {
        var s = String(line || "");
        if (s === "") return;
        root.lastCommand = s;
        root.writeRaw(s + "\n");
    }

    // Raw byte write (Ctrl+C, arrows, tab completion...).
    function writeRaw(s) {
        if (!root.shell.running) {
            root._pending.push(String(s));
            root._restartProcess();
            return;
        }
        root.shell.write(String(s));
    }

    // Header's restart control: fresh shell, fresh screen.
    function restart() {
        root._reset();
        root._restartProcess();
    }

    // Kept for call sites that used the one-shot runner (chips, IPC).
    function run(command) { root.send(command); }

    function launch() {
        root.resolve();
        if (root.emulator === "") {
            root._appendHtml("<span style=\"color:#888888\">[no terminal emulator found - install kitty, foot, konsole or xterm]</span>");
            return "";
        }
        var cmd = root.emulator + " " + root.flagFor(root.emulator) + " " + root._shell;
        root.title = root._shell;
        runner.command = ["sh", "-c", cmd + " >/dev/null 2>&1 &"];
        runner.running = true;
        root.launched(cmd);
        return cmd;
    }

    function clear() {
        root._reset();
    }

    property Process runner: Process {}

    function _restartProcess() {
        if (root.shell.running) {
            root._restartWhenDead = true;
            root.shell.running = false;      // onExited auto-restarts below
        } else {
            root.shell.running = true;
        }
    }

    property bool _restartWhenDead: false

    // ---------------------------------------------------------------- output
    function _appendHtml(html) {
        root._lines.push(html);
        if (root._lines.length > 400)
            root._lines = root._lines.slice(root._lines.length - 400);
        root._publish();
    }

    function _reset() {
        root._lines = [];
        root._cells = [];
        root._col = 0;
        root._esc = 0;
        root._csi = "";
        root._osc = "";
        root._attr = { c: null, bg: null, b: false, u: false };
        root.text = "";
    }

    function _feed(chunk) {
        var s = String(chunk || "");
        if (s === "") return;
        for (var i = 0; i < s.length; i++) {
            var ch = s.charAt(i);
            var code = s.charCodeAt(i);
            if (root._esc === 0) {
                if (code === 0x1b) { root._esc = 1; continue; }
                if (ch === "\n") { root._finishLine(); continue; }
                if (ch === "\r") { root._col = 0; continue; }
                if (code === 0x08) { if (root._col > 0) root._col--; continue; }
                if (ch === "\t") { root._tab(); continue; }
                if (code < 0x20 || code === 0x7f) continue;   // BEL, other C0
                root._print(ch);
            } else if (root._esc === 1) {
                if (ch === "[") { root._esc = 2; root._csi = ""; continue; }
                if (ch === "]") { root._esc = 3; root._osc = ""; continue; }
                root._esc = 0;                                  // ESC ( B etc.
            } else if (root._esc === 2) {
                if (ch >= "@" && ch <= "~") {
                    root._esc = 0;
                    root._csiDispatch(ch);
                } else if (root._csi.length < 64) {
                    root._csi += ch;
                } else {
                    root._esc = 0;
                }
            } else if (root._esc === 3) {
                if (code === 0x07) { root._esc = 0; continue; }
                if (code === 0x1b && root._osc.endsWith("\\")) { root._esc = 0; continue; }
                if (root._osc.length < 256) root._osc += ch;
                else root._esc = 0;
            }
        }
        root._publish();
    }

    function _publish() {
        // RichText treats bare \n as whitespace - line breaks need <br/>.
        var s = root._lines.join("<br/>");
        if (root._cells.length > 0) {
            s += (s === "" ? "" : "<br/>") + root._render(root._cells);
        }
        root.text = s;
    }

    function _finishLine() {
        root._lines.push(root._render(root._cells));
        root._cells = [];
        root._col = 0;
        if (root._lines.length > 400)
            root._lines = root._lines.slice(root._lines.length - 400);
    }

    function _print(ch) {
        var cell = { t: ch, c: root._attr.c, bg: root._attr.bg,
                     b: root._attr.b, u: root._attr.u };
        if (root._col < root._cells.length)
            root._cells[root._col] = cell;
        else
            root._cells.push(cell);
        root._col++;
    }

    function _tab() {
        var pad = 8 - (root._col % 8);
        for (var i = 0; i < pad; i++) root._print(" ");
    }

    // ------------------------------------------------------------- CSI/SGR
    function _csiDispatch(final) {
        var raw = root._csi;
        var privateMark = "";
        if (raw.charAt(0) === "?" || raw.charAt(0) === ">" || raw.charAt(0) === "<") {
            privateMark = raw.charAt(0);
            raw = raw.substring(1);
        }
        var parts = raw.split(";");
        var nums = [];
        for (var i = 0; i < parts.length; i++)
            nums.push(parts[i] === "" ? 0 : parseInt(parts[i], 10) || 0);

        if (privateMark !== "") return;             // private modes: ignore
        if (final === "m") { root._sgr(nums); return; }
        if (final === "K") {
            var mode = nums[0] || 0;
            if (mode === 0) root._cells = root._cells.slice(0, root._col);
            else if (mode === 1) { root._cells = root._cells.slice(root._col); root._col = 0; }
            else { root._cells = []; root._col = 0; }
            return;
        }
        if (final === "J") {
            if ((nums[0] || 0) === 2) { root._lines = []; root._cells = []; root._col = 0; }
            return;
        }
        if (final === "G") {                        // horizontal absolute
            var col = Math.max(1, nums[0] || 1) - 1;
            root._col = Math.min(col, root._cells.length);
            return;
        }
        // Cursor moves (A/B/C/D), SGR-adjacent junk, device queries: ignored.
        // Full-screen apps still need a real VT - see the header launcher.
    }

    function _sgr(nums) {
        var a = { c: root._attr.c, bg: root._attr.bg, b: root._attr.b, u: root._attr.u };
        for (var i = 0; i < nums.length; i++) {
            var v = nums[i];
            if (v === 0) a = { c: null, bg: null, b: false, u: false };
            else if (v === 1) a.b = true;
            else if (v === 22) a.b = false;
            else if (v === 4) a.u = true;
            else if (v === 24) a.u = false;
            else if (v >= 30 && v <= 37) a.c = root._pal[v - 30];
            else if (v >= 90 && v <= 97) a.c = root._pal[v - 90 + 8];
            else if (v === 39) a.c = null;
            else if (v >= 40 && v <= 47) a.bg = root._pal[v - 40];
            else if (v >= 100 && v <= 107) a.bg = root._pal[v - 100 + 8];
            else if (v === 49) a.bg = null;
            else if (v === 38 || v === 48) {
                var target = (v === 38) ? "c" : "bg";
                if (nums[i + 1] === 5) { a[target] = root._c256(nums[i + 2] || 0); i += 2; }
                else if (nums[i + 1] === 2) {
                    var r = Math.min(255, nums[i + 2] || 0), g = Math.min(255, nums[i + 3] || 0), b = Math.min(255, nums[i + 4] || 0);
                    a[target] = "#" + ((1 << 24) | (r << 16) | (g << 8) | b).toString(16).slice(1);
                    i += 4;
                }
            }
        }
        root._attr = a;
    }

    function _c256(n) {
        if (n < 16) return root._pal[n];
        if (n >= 232) { var g = 8 + (n - 232) * 10; return "#" + ((1 << 24) | (g << 16) | (g << 8) | g).toString(16).slice(1); }
        n -= 16;
        var steps = [0, 95, 135, 175, 215, 255];
        var r = steps[Math.floor(n / 36) % 6], g = steps[Math.floor(n / 6) % 6], b = steps[n % 6];
        return "#" + ((1 << 24) | (r << 16) | (g << 8) | b).toString(16).slice(1);
    }

    // ------------------------------------------------------------- render
    function _escHtml(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function _render(cells) {
        if (cells.length === 0) return "";
        var out = "", i = 0;
        while (i < cells.length) {
            var a = cells[i];
            var j = i + 1;
            while (j < cells.length && cells[j].c === a.c && cells[j].bg === a.bg
                   && cells[j].b === a.b && cells[j].u === a.u) j++;
            var run = "";
            for (var k = i; k < j; k++) run += cells[k].t;
            var html = root._escHtml(run);
            if (a.c || a.bg || a.b || a.u) {
                var style = "";
                if (a.c) style += "color:" + a.c + ";";
                if (a.bg) style += "background-color:" + a.bg + ";";
                if (a.b) style += "font-weight:700;";
                if (a.u) style += "text-decoration:underline;";
                html = "<span style=\"" + style + "\">" + html + "</span>";
            }
            out += html;
            i = j;
        }
        return out;
    }

    // ------------------------------------------------------------ emulator
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

    function flagFor(bin) {
        return root.execFlag[bin] !== undefined ? root.execFlag[bin] : "-e";
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

    Component.onCompleted: root.resolve()
}
