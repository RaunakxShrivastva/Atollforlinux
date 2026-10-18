import QtQuick

QtObject {
    id: root

    property int secondsRemaining: 0
    property bool isRunning: false
    property bool isStopwatch: false
    property int stopwatchSeconds: 0

    readonly property string formattedTime: {
        if (isStopwatch) {
            let m = Math.floor(stopwatchSeconds / 60);
            let s = stopwatchSeconds % 60;
            return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
        } else {
            let m = Math.floor(secondsRemaining / 60);
            let s = secondsRemaining % 60;
            return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
        }
    }

    property Timer ticker: Timer {
        interval: 1000
        repeat: true
        running: root.isRunning
        onTriggered: {
            if (root.isStopwatch) {
                root.stopwatchSeconds++;
            } else {
                if (root.secondsRemaining > 0) {
                    root.secondsRemaining--;
                } else {
                    root.isRunning = false;
                }
            }
        }
    }

    function startTimer(seconds) {
        root.isStopwatch = false;
        root.secondsRemaining = seconds;
        root.isRunning = true;
    }

    function startStopwatch() {
        root.isStopwatch = true;
        root.stopwatchSeconds = 0;
        root.isRunning = true;
    }

    function togglePause() {
        root.isRunning = !root.isRunning;
    }

    function reset() {
        root.isRunning = false;
        root.secondsRemaining = 0;
        root.stopwatchSeconds = 0;
    }
}
