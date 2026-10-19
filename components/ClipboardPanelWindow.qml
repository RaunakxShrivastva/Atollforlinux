import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "../services"

// Clipboard panel window - the "Panel" display mode of the header's clipboard
// button (Atoll: ClipboardPanel NSPanel via ClipboardPanelManager).
//
// Atoll centres the 380 x 480 panel in the screen's visible frame and lets you
// drag it; a layer-shell surface is positioned by anchors/margins rather than
// by the client, so with no anchors set the compositor centres it (and it stays
// where the compositor puts it). Overlay layer + keyboard focus on demand, so
// the search field is typeable while the panel floats above fullscreen windows.
PanelWindow {
    id: win

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    // No anchors: the compositor centres the surface (Atoll centres the panel
    // in the screen's visible frame).
    implicitWidth: 380
    implicitHeight: 480
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "atoll-clipboard"
    WlrLayershell.exclusiveZone: 0
    // OnDemand so the search field can be typed into once the panel is clicked,
    // without the panel stealing keys while it is merely on screen.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function open() {
        ClipboardService.refresh();
        ClipboardService.refreshFavorites();
        win.visible = true;
    }

    function close() { win.visible = false; }
    function toggle() { win.visible ? win.close() : win.open(); }

    ClipboardPanel {
        anchors.fill: parent
        service: ClipboardService
        onCloseRequested: win.close()
        // Copying a row leaves the panel up (Atoll keeps the NSPanel open).
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { win.toggle(); }
        function open(): void { win.open(); }
        function close(): void { win.close(); }
    }
}
