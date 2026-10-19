import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

// Focused harness for the clipboard surfaces: the 380x480 panel (History and
// Favorites), the 280x320 popover and the shared rows in both styles. A
// stand-in for ClipboardService keeps this runnable under plain `qml6`:
//   mkdir -p /tmp/opencode/preview
//   magick -size 120x80 gradient:purple-black /tmp/opencode/preview/clip-thumb.png
//   QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/clipboard.qml
Window {
    id: stage
    width: 1160
    height: 560
    visible: true
    color: "#101014"

    AtollFonts {}

    // Stand-in for ClipboardService: same shape, no cliphist behind it.
    QtObject {
        id: mockService
        property var entries: [
            { id: 11, kind: "Text", preview: "omdrop send <device> <file>", match: "omdrop send <device> <file>", age: "now", ageLong: "Just now", thumb: "" },
            { id: 12, kind: "URL", preview: "https://github.com/Ebullioscopic/Atoll", match: "https://github.com/Ebullioscopic/Atoll", age: "4m", ageLong: "4m ago", thumb: "" },
            { id: 13, kind: "Image", preview: "Image", match: "[[ binary data 298 B png 60x40 ]]", age: "2h", ageLong: "2h ago",
              thumb: "file:///tmp/opencode/preview/clip-thumb.png" },
            { id: 14, kind: "Text", preview: "A long cliphist preview that has to wrap onto a second line and then elide because it keeps going and going", match: "A long cliphist preview that has to wrap onto a second line and then elide because it keeps going and going", age: "3d", ageLong: "3d ago", thumb: "" }
        ]
        property var favorites: [
            { id: "fav-1", kind: "Text", mime: "text/plain", match: "omdrop send <device> <file>",
              preview: "omdrop send <device> <file>", text: "omdrop send <device> <file>",
              file: "", thumb: "", age: "12h", ageLong: "12h ago" },
            { id: "fav-2", kind: "Image", mime: "image/png", match: "[[ binary data 298 B png 60x40 ]]",
              preview: "Image (298 B)", text: "", file: "mock.png",
              thumb: "file:///tmp/opencode/preview/clip-thumb.png", age: "2d", ageLong: "2d ago" }
        ]
        property int revision: 0

        function refresh() { revision++; }
        function refreshFavorites() { revision++; }
        function pick(id) { console.log("pick", id); }
        function remove(id) { console.log("remove", id); }
        function clear() { console.log("clear"); }
        function pin(id) { console.log("pin", id); }
        function unpin(id) { console.log("unpin", id); }
        function clearFavorites() { console.log("clearFavorites"); }
        function pickFavorite(id) { console.log("pickFavorite", id); }
        function isFavorite(entry) {
            for (var i = 0; i < favorites.length; i++)
                if (favorites[i].match === entry.match) return true;
            return false;
        }
    }

    // ---- Panel: History ----
    Rectangle {
        x: 16; y: 16; width: 380; height: 480
        color: "transparent"

        ClipboardPanel {
            anchors.fill: parent
            service: mockService
            selectedTab: "history"
        }
    }

    // ---- Panel: Favorites (with a search term) ----
    Rectangle {
        x: 412; y: 16; width: 380; height: 480
        color: "transparent"

        ClipboardPanel {
            anchors.fill: parent
            service: mockService
            selectedTab: "favorites"
            searchText: "zzz"
        }
    }

    // ---- Popover: History ----
    Rectangle {
        x: 808; y: 16; width: 280; height: 320
        color: "transparent"

        ClipboardPopover {
            anchors.fill: parent
            service: mockService
            selectedTab: "history"
        }
    }

    // ---- Popover: Favorites, empty search state ----
    Rectangle {
        x: 808; y: 356; width: 280; height: 320
        color: "transparent"

        ClipboardPopover {
            anchors.fill: parent
            service: mockService
            selectedTab: "favorites"
        }
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: stage.contentItem.grabToImage(function (res) {
            res.saveToFile("/tmp/opencode/preview/clipboard.png");
            Qt.quit();
        })
    }
}
