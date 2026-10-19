import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

// Focused harness for the Usage tab, exercising every card branch: the Claude
// token-window card with a plan badge, the Codex quota-gauge card, a failed
// provider, a not-configured provider and the loading spinner. A stand-in for
// LLMUsageService keeps this runnable under plain `qml6`.
//   QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/llmusage.qml
Window {
    id: stage
    width: 1040
    height: 232
    visible: true
    color: "#101014"

    AtollFonts {}

    // Fake "now" so the reset countdowns render deterministically.
    readonly property real nowSec: Date.now() / 1000

    QtObject {
        id: mockService
        property var results: ({
            claude: {
                status: "success",
                plan: "Max 5x",
                session: { input: 42000, output: 8100, cost: 0.31, unpriced: false, pct: false },
                today: { input: 812400, output: 96300, cost: 4.87, unpriced: false, pct: false },
                week: { input: 5920000, output: 641000, cost: 33.94, unpriced: false, pct: false },
                sessionLimit: null,
                weekLimit: null
            },
            codex: {
                status: "success",
                plan: null,
                session: { input: 214000, output: 12300, cost: 0.42, unpriced: false, pct: false },
                today: { input: 1840000, output: 51200, cost: 1.19, unpriced: false, pct: false },
                week: { input: 6180773, output: 37712, cost: 2.10, unpriced: false, pct: false },
                sessionLimit: { used: 42, limit: 100, resetsAt: stage.nowSec + 3 * 3600 + 600 },
                weekLimit: { used: 88, limit: 100, resetsAt: stage.nowSec + 2 * 86400 + 5 * 3600 }
            },
            cursor: {
                status: "failure",
                reason: "Cursor quota unavailable (needs a macOS Cursor session)"
            },
            antigravity: { status: "loading" },
            newAPI: {
                status: "failure",
                reason: "No New API accounts configured"
            }
        })
    }

    Rectangle {
        x: 16; y: 16; width: 660; height: 200
        radius: 20
        color: "#000000"

        LLMUsageView {
            anchors.fill: parent
            service: mockService
            providers: [
                { id: "claude", name: "Claude" },
                { id: "codex", name: "Codex" }
            ]
        }
    }

    Rectangle {
        x: 692; y: 16; width: 332; height: 200
        radius: 20
        color: "#000000"

        LLMUsageView {
            anchors.fill: parent
            service: mockService
            providers: [
                { id: "cursor", name: "Cursor" },
                { id: "antigravity", name: "Antigravity" },
                { id: "newAPI", name: "New API" }
            ]
        }
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: stage.contentItem.grabToImage(function (res) {
            res.saveToFile("/tmp/opencode/preview/llmusage.png");
            Qt.quit();
        })
    }
}
