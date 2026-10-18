import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > SettingsTab.terminal.
//
// Atoll's terminal is an embedded SwiftTerm view (font, size, opacity, cursor
// style, scrollback, mouse reporting, colours...). A Wayland layer surface
// cannot host that, so those keys are not offered here at all rather than shown
// dead; what is configurable is the shell, the emulator that gets launched and
// the quick-command chips that run inside the notch's console.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Terminal"

        FormRow {
            label: "Enable terminal tab"
            FormToggle {
                checked: Settings.values.enableTerminalFeature === true
                onToggled: (v) => Settings.set("enableTerminalFeature", v)
            }
        }
        FormRow {
            label: "Shell"
            FormPicker {
                enabled: Settings.values.enableTerminalFeature === true
                options: [
                    { value: "bash", label: "bash" },
                    { value: "zsh", label: "zsh" },
                    { value: "fish", label: "fish" },
                    { value: "sh", label: "sh" }
                ]
                value: Settings.values.terminalShell
                onSelected: (v) => Settings.set("terminalShell", v)
            }
        }
        FormRow {
            label: "Terminal emulator"
            divider: false
            description: "Which emulator the tab and the Quick Action open. Auto picks "
                         + "the first one installed."
            FormPicker {
                enabled: Settings.values.enableTerminalFeature === true
                options: [
                    { value: "auto", label: "Auto (" + (TerminalService.emulator || "none found") + ")" },
                    { value: "kitty", label: "kitty" },
                    { value: "foot", label: "foot" },
                    { value: "ghostty", label: "ghostty" },
                    { value: "wezterm", label: "wezterm" },
                    { value: "alacritty", label: "alacritty" },
                    { value: "konsole", label: "konsole" },
                    { value: "xterm", label: "xterm" }
                ]
                value: Settings.values.terminalEmulator
                onSelected: (v) => Settings.set("terminalEmulator", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Quick commands"
        footer: "Comma-separated. Each becomes a chip in the tab that runs the "
                + "command in a pipe and prints its output inline."

        FormRow {
            label: "Commands"
            divider: false
            FormTextRow {
                fieldWidth: 260
                placeholder: "htop, ls -la ~, df -h"
                text: Settings.values.terminalQuickCommands
                onEdited: (v) => Settings.set("terminalQuickCommands", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Not portable"
        footer: "An embedded terminal emulator needs a native window, which a Wayland "
                + "layer surface cannot host, so Atoll's font, opacity, cursor-style, "
                + "scrollback, mouse-reporting and colour settings have no target here. "
                + "The tab launches a real terminal instead."

        FormRow {
            label: "Embedded terminal"
            divider: false
            FormLabel { text: "Unavailable on Wayland — launches your emulator" }
        }
    }
}
