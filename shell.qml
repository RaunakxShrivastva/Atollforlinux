import QtQuick
import Quickshell
import Quickshell.Wayland
import "theme"
import "components"
import "services"

ShellRoot {
    id: shellRoot

    AtollFonts { id: atollFonts }

    // Atoll Settings window (FloatingWindow): opened by the notch gear, the
    // `atoll settings` command, or `quickshell ipc call settings toggle`.
    SettingsWindow {
        id: settingsWindow
    }

    // Colour-picker panel (Utilities > Color Picker, "Panel" display mode):
    // opened by the notch's eyedropper button.
    ColorPickerWindow {
        id: colorPickerWindow
    }

    // Clipboard panel (Utilities > Clipboard, "Panel" display mode): opened by
    // the notch's clipboard button.
    ClipboardPanelWindow {
        id: clipboardPanelWindow
    }

    // General > "Launch at login": keeps the autostart entry in sync with the
    // setting.
    AutostartService {
        id: autostart
        // The settings file loads asynchronously, so react to the value rather
        // than sampling it once at startup.
        property bool desired: Settings.values.launchAtLogin === true
        onDesiredChanged: apply(desired)
        Component.onCompleted: apply(desired)
    }

    Connections {
        target: Settings
        function onChanged(key) {
            if (key === "launchAtLogin") autostart.apply(Settings.values.launchAtLogin === true);
        }
    }

    // Display selection (Settings > General > Displays):
    //   preferredScreen  - a monitor name; empty = automatic
    //   showOnAllDisplays- one island per monitor
    //   otherwise        - a single island on the preferred / first monitor
    function targetScreens() {
        var screens = Quickshell.screens;
        if (!screens || screens.length === 0) return [];
        var pref = Settings.preferredScreen;
        if (pref !== "") {
            var matched = screens.filter(function (s) { return s.name === pref; });
            if (matched.length > 0) return matched;
        }
        if (Settings.showOnAllDisplays) return screens;
        return [screens[0]];
    }

    Variants {
        model: shellRoot.targetScreens()

        PanelWindow {
            id: panelWindow
            required property var modelData

            screen: modelData
            anchors { top: true }

            implicitWidth: 900
            implicitHeight: 360
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "atoll-notch"
            WlrLayershell.exclusiveZone: 0
            // The island has no text input of its own, so it never takes the
            // keyboard - except while something with a text field is open in it
            // (the clipboard popover's search, the notes editor), when it asks
            // for focus on demand so those fields can be typed into.
            WlrLayershell.keyboardFocus: notch.wantsKeyboard
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            // The window is deliberately larger than the pill (it must fit the
            // expanded card without a compositor resize during the spring).
            // Limit the wayland INPUT region to the island's live silhouette so
            // the transparent margin stops swallowing clicks around the closed
            // pill. `mask` only affects input, never rendering.
            //
            // "Extend hover area" (General) widens that region into a band across
            // the top so the island can be opened without hitting the pill.
            Item {
                id: inputRegion
                x: Settings.extendHoverArea ? (panelWindow.width - width) / 2 : notch.x
                y: 0
                width: Settings.extendHoverArea ? Math.max(notch.width + 240, 700) : notch.width
                height: Settings.extendHoverArea ? Math.max(notch.y + notch.height, 56) : (notch.y + notch.height)
            }

            mask: Region {
                item: inputRegion
            }

            NotchContainer {
                id: notch
                presentation: Settings.displayStyle === "floating" ? "island"
                            : (Settings.displayStyle === "menuBar" ? "menuBar" : "notch")
                anchors.top: parent.top
                anchors.topMargin: presentation === "island" ? Atoll.islandTopOffset : 0
                anchors.horizontalCenter: parent.horizontalCenter
                onSettingsRequested: settingsWindow.open()
                onColorPickerPanelRequested: colorPickerWindow.toggle()
                onClipboardPanelRequested: clipboardPanelWindow.toggle()
            }
        }
    }
}
