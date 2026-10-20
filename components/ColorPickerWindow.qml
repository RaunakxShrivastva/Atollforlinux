import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "../services"

// Colour-picker panel window. Atoll shows `ColorPickerPanel` in an NSPanel
// floating near the notch; here it is a layer-shell surface anchored under the
// island (the same Overlay layer the island uses, so it stays above fullscreen
// windows the way the NSPanel does). Opened by the notch's eyedropper button
// when `colorPickerDisplayMode` is "panel".
PanelWindow {
    id: win

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    anchors { top: true }
    // Clears the expanded island (closed pill 32 + open 200) rather than
    // overlapping it, since the eyedropper button only exists when it is open.
    margins.top: Atoll.islandTopOffset + Atoll.notchOpenHeight + 14

    implicitWidth: 450
    implicitHeight: 600
    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "atoll-colorpicker"
    WlrLayershell.exclusiveZone: 0
    // OnDemand so the search field can be typed into once the panel is clicked,
    // without the panel stealing keys while it is merely on screen.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function open() { win.visible = true; }
    function close() { win.visible = false; }
    function toggle() { win.visible = !win.visible; }

    ColorPickerPanel {
        anchors.fill: parent
        service: ColorPickerService
        showAllFormats: Settings.colorFormats
        onPickRequested: {
            win.close();
            ColorPickerService.pick();
        }
        onCloseRequested: win.close()
    }

    IpcHandler {
        target: "colorpicker"
        function toggle(): void { win.toggle(); }
        function open(): void { win.open(); }
        function close(): void { win.close(); }
        function pick(): void { ColorPickerService.pick(); }
        function cancel(): void { ColorPickerService.cancelPick(); }
        function commit(): void { ColorPickerService.commitPick(); }
        function clear(): void { ColorPickerService.clearHistory(); }
    }
}
