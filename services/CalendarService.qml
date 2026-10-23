import QtQuick
import Quickshell
import Quickshell.Io

// Calendar agenda (General > Live activities > Calendar).
//
// Atoll reads EventKit on macOS; there is no such framework here, so this reads
// an iCalendar (.ics) file instead -- what `khal`, Thunderbird, Nextcloud and
// Google Calendar all export. VEVENTs become events and VTODOs become
// reminders, so "Hide all-day events" and "Hide completed reminders" have
// something real to filter. Recurrence rules are not expanded: the first
// occurrence is used as-is.
QtObject {
    id: root

    property string path: "~/.local/share/atoll/calendar.ics"
    property bool hideAllDay: false
    property bool hideCompleted: false
    property int limit: 5

    property var events: []
    property var reminderTodos: []

    // Refreshed so "upcoming" ages out of the list without a reload.
    property double now: Date.now()
    property Timer clock: Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.now = Date.now()
    }

    readonly property var upcoming: {
        var out = [];
        var base = root.now - 12 * 3600 * 1000; // keep things started today
        for (var i = 0; i < root.events.length; i++) {
            var e = root.events[i];
            if (e.start < base) continue;
            if (root.hideAllDay && e.allDay) continue;
            out.push(e);
        }
        if (!root.hideCompleted) {
            for (var j = 0; j < root.reminderTodos.length; j++) {
                var t = root.reminderTodos[j];
                if (t.start < base) continue;
                out.push(t);
            }
        }
        out.sort(function (a, b) { return a.start - b.start; });
        return out.slice(0, root.limit);
    }

    // Everything the calendars know about, keyed by day: the standalone
    // calendar's agenda pane has no "upcoming" window and no 5-item limit.
    readonly property var agenda: {
        var out = [];
        for (var i = 0; i < root.events.length; i++) {
            var e = root.events[i];
            if (root.hideAllDay && e.allDay) continue;
            out.push(e);
        }
        if (!root.hideCompleted) {
            for (var j = 0; j < root.reminderTodos.length; j++) {
                var t = root.reminderTodos[j];
                if (root.hideAllDay && t.allDay) continue;
                out.push(t);
            }
        }
        out.sort(function (a, b) { return a.start - b.start; });
        return out;
    }

    function parseDate(v, isDateOnly) {
        if (!v) return null;
        var s = v.trim();
        // YYYYMMDD
        if (/^\d{8}$/.test(s)) return new Date(+s.substr(0, 4), +s.substr(4, 2) - 1, +s.substr(6, 2));
        // YYYYMMDDTHHMMSS[Z]
        var m = s.match(/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z)?$/);
        if (!m) return null;
        var Y = +m[1], Mo = +m[2] - 1, D = +m[3], H = +m[4], Mi = +m[5], S = +m[6];
        return m[7] ? new Date(Date.UTC(Y, Mo, D, H, Mi, S)) : new Date(Y, Mo, D, H, Mi, S);
    }

    function prop(block, name) {
        // Matches NAME (optionally NAME;PARAM=...) : value, anywhere in the block.
        var re = new RegExp("^" + name + "(;[^:\\n]*)?:(.*)$", "m");
        var m = block.match(re);
        return m ? m[2] : "";
    }

    function isAllDay(block) {
        if (/DTSTART[^:\n]*VALUE=DATE[:;]/.test(block)) return true;
        var d = prop(block, "DTSTART");
        return d !== "" && /^\d{8}$/.test(d.trim());
    }

    function parse(text) {
        // Unfold: a line beginning with space or tab continues the previous one.
        var raw = text.replace(/\r\n/g, "\n").split("\n");
        var lines = [];
        for (var i = 0; i < raw.length; i++) {
            if (lines.length > 0 && /^[ \t]/.test(raw[i])) lines[lines.length - 1] += raw[i].substr(1);
            else lines.push(raw[i]);
        }
        var joined = lines.join("\n");

        var ev = [], todos = [];
        var re = /BEGIN:(VEVENT|VTODO)([\s\S]*?)END:\1/g, m;
        while ((m = re.exec(joined)) !== null) {
            var kind = m[1];
            var block = m[2];
            var summary = prop(block, "SUMMARY").replace(/\\,/g, ",").replace(/\\n/gi, " ").trim();
            if (summary === "") summary = "(no title)";
            var allDay = isAllDay(block);
            var start = parseDate(prop(block, "DTSTART"), allDay)
                        || parseDate(prop(block, "DUE"), allDay)
                        || parseDate(prop(block, "DTEND"), allDay);
            if (!start) continue;
            var completed = /STATUS:COMPLETED/i.test(block);
            var entry = { summary: summary, start: start.getTime(), allDay: allDay, completed: completed };
            if (kind === "VEVENT") ev.push(entry); else todos.push(entry);
        }
        root.events = ev;
        root.reminderTodos = todos;
    }

    // Only hand the path to FileView once it exists, so a machine with no
    // calendar configured does not log a read failure on every reload.
    property bool available: false
    property string realPath: root.path.replace("~", Quickshell.env("HOME"))
    property Process existsProbe: Process {
        command: ["bash", "-c", "[ -f " + JSON.stringify(realPath) + " ] && echo yes || echo no"]
        stdout: SplitParser {
            onRead: line => root.available = (line.trim() === "yes")
        }
        Component.onCompleted: running = true
    }

    property FileView file: FileView {
        path: root.available ? root.realPath : ""
        watchChanges: true
        onTextChanged: root.parse(text())
        onFileChanged: reload()
        onLoadFailed: root.events = [], root.reminderTodos = []
    }

    function refresh() { existsProbe.running = true; }
    onAvailableChanged: if (available) file.reload()
    Component.onCompleted: refresh()
}
