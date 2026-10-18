import QtQuick
import "../theme"
import "../components"

// Focused harness for the colour-picker panel + popover. A tiny stand-in for
// ColorPickerService supplies the history (the real one needs Quickshell, which
// plain `qml6` cannot load); all colour maths comes from the real ColorFormats
// singleton, so the rendered hex/rgb/hsl strings are the shipping ones.
//   QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/colorpicker.qml
Window {
    id: stage
    width: 760
    height: 660
    visible: true
    color: "#101014"

    AtollFonts {}

    function sample(r, g, b, ageMs) {
        return { id: String(r * 1000 + g * 10 + b), r: r, g: g, b: b, a: 1,
                 timestamp: Date.now() - ageMs };
    }

    // Stand-in for ColorPickerService.
    QtObject {
        id: mockService
        property var history: [
            stage.sample(0.04, 0.52, 1.00, 5000),
            stage.sample(1.00, 0.23, 0.19, 120000),
            stage.sample(0.19, 0.82, 0.35, 3600000),
            stage.sample(1.00, 0.84, 0.04, 7200000),
            stage.sample(0.75, 0.35, 0.95, 90000000)
        ]
        function removeColor(id) {
            history = history.filter(function (e) { return e.id !== id; });
        }
        function clearHistory() { history = []; }
        function copy(text) { console.log("copy " + text); }
    }

    ColorPickerPanel {
        id: panel
        x: 20
        y: 20
        width: 450
        height: 600
        service: mockService
        selected: mockService.history[0]
    }

    ColorPickerPopover {
        x: 500
        y: 20
        service: mockService
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: stage.contentItem.grabToImage(function (res) {
            res.saveToFile("/tmp/opencode/preview/colorpicker.png");
            Qt.quit();
        })
    }
}
