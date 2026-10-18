import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

// Focused harness for the terminal tab: enabled (with a transcript) and the
// disabled placeholder. A stand-in for TerminalService keeps this runnable
// under plain `qml6`.
//   QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/terminal.qml
Window {
    id: stage
    width: 760
    height: 300
    visible: true
    color: "#101014"

    AtollFonts {}

    QtObject {
        id: mockService
        property string title: "ls -la ~"
        property string output: "$ ls -la ~\n" +
            "total 48\n" +
            "drwx------ 1 raunakxshrivastva raunakxshrivastva  4096 Oct 18 21:02 .\n" +
            "drwxr-xr-x 1 root            root              4096 Oct 12 09:11 ..\n" +
            "drwxr-xr-x 1 raunakxshrivastva raunakxshrivastva  4096 Oct 18 20:58 .cache\n" +
            "drwxr-xr-x 1 raunakxshrivastva raunakxshrivastva  4096 Oct 18 21:40 .config\n" +
            "drwxr-xr-x 1 raunakxshrivastva raunakxshrivastva  4096 Oct 17 23:12 .local\n\n" +
            "$ df -h\n" +
            "Filesystem      Size  Used Avail Use% Mounted on\n" +
            "/dev/nvme0n1p2  476G  312G  141G  69% /"
        function run(command) {}
        function launch() {}
        function clear() {}
    }

    Rectangle {
        x: 16; y: 16; width: 460; height: 264
        radius: 16
        color: "#000000"

        TerminalView {
            anchors.fill: parent
            service: mockService
            featureEnabled: true
            shellName: "zsh"
            emulator: "kitty"
            quickCommands: ["htop", "df -h", "sensors"]
        }
    }

    Rectangle {
        x: 492; y: 16; width: 252; height: 264
        radius: 16
        color: "#000000"

        TerminalView {
            anchors.fill: parent
            service: mockService
            featureEnabled: false
        }
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: stage.contentItem.grabToImage(function (res) {
            res.saveToFile("/tmp/opencode/preview/terminal.png");
            Qt.quit();
        })
    }
}
