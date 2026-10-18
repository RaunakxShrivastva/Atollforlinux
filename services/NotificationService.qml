import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string appName: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property bool hasActiveNotification: false

    signal newNotification()

    // Taps Notify() calls on the session bus with dbus-monitor instead of
    // registering a NotificationServer, so it coexists with the desktop's
    // existing daemon (swaync / KDE / etc.) rather than fighting over the name.
    property Process monitor: Process {
        command: ["dbus-monitor", "--session",
                  "interface='org.freedesktop.Notifications',member='Notify'"]
        running: true
        stdout: SplitParser {
            onRead: line => root.handleLine(line)
        }
    }

    property int _stage: 0

    function unquote(s) {
        var i = s.indexOf('"');
        if (i < 0) return "";
        var body = s.substring(i + 1);
        if (body.charAt(body.length - 1) === '"') body = body.substring(0, body.length - 1);
        return body.replace(/\\"/g, '"').replace(/\\\\/g, '\\');
    }

    function handleLine(line) {
        var t = line.trim();
        if (t.indexOf("member=Notify") !== -1) { _stage = 1; return; }
        if (_stage === 0) return;

        if (t.indexOf("string ") === 0) {
            var v = unquote(t);
            if (_stage === 1) { appName = v; _stage = 2; }
            else if (_stage === 3) { appIcon = v; _stage = 4; }
            else if (_stage === 4) { summary = v; _stage = 5; }
            else if (_stage === 5) { body = v; _stage = 0; emitNotification(); }
        } else if (t.indexOf("uint32 ") === 0) {
            if (_stage === 2) _stage = 3;
        }
    }

    function emitNotification() {
        if (appName === "") appName = "Notification";
        hasActiveNotification = true;
        newNotification();
        dismissTimer.restart();
    }

    property Timer dismissTimer: Timer {
        interval: 6000
        repeat: false
        onTriggered: root.hasActiveNotification = false
    }

    function dismiss() {
        dismissTimer.stop();
        root.hasActiveNotification = false;
    }
}
