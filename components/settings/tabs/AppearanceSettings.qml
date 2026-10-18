import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > Appearance.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Style"

        FormRow {
            label: "Accent colour"
            FormColorRow {
                value: Settings.values.accentColor
                onSelected: (c) => Settings.set("accentColor", c)
            }
        }
        FormRow {
            label: "Drop shadow"
            FormToggle {
                checked: Settings.values.enableShadow
                onToggled: (v) => Settings.set("enableShadow", v)
            }
        }
        FormRow {
            label: "Scale corner radius"
            description: "Grow the corner radius as the notch expands."
            FormToggle {
                checked: Settings.values.cornerRadiusScaling
                onToggled: (v) => Settings.set("cornerRadiusScaling", v)
            }
        }
        FormRow {
            label: "Modern close animation"
            FormToggle {
                checked: Settings.values.useModernCloseAnimation
                onToggled: (v) => Settings.set("useModernCloseAnimation", v)
            }
        }
        FormRow {
            label: "Lighting effect"
            FormToggle {
                checked: Settings.values.lightingEffect
                onToggled: (v) => Settings.set("lightingEffect", v)
            }
        }
        FormRow {
            label: "Tint album art by player"
            divider: false
            FormToggle {
                checked: Settings.values.playerColorTinting
                onToggled: (v) => Settings.set("playerColorTinting", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Notch size"
        footer: "Sizes are logical pixels. Open/closed widths apply to notch-style layouts."

        FormRow {
            label: "Notch height mode"
            FormPicker {
                options: [
                    { value: "matchRealNotchSize", label: "Match real notch" },
                    { value: "custom", label: "Custom" }
                ]
                value: Settings.values.notchHeightMode
                onSelected: (v) => Settings.set("notchHeightMode", v)
            }
        }
        FormRow {
            label: "Notch height"
            FormStepper {
                value: Settings.values.notchHeight
                from: 20
                to: 80
                onChanged: (v) => Settings.set("notchHeight", v)
            }
        }
        FormRow {
            label: "Non-notch height mode"
            FormPicker {
                options: [
                    { value: "matchMenuBar", label: "Match menu bar" },
                    { value: "custom", label: "Custom" }
                ]
                value: Settings.values.nonNotchHeightMode
                onSelected: (v) => Settings.set("nonNotchHeightMode", v)
            }
        }
        FormRow {
            label: "Non-notch height"
            FormStepper {
                value: Settings.values.nonNotchHeight
                from: 20
                to: 80
                onChanged: (v) => Settings.set("nonNotchHeight", v)
            }
        }
        FormRow {
            label: "Open width"
            FormStepper {
                value: Settings.values.openNotchWidth
                from: 320
                to: 1200
                step: 10
                onChanged: (v) => Settings.set("openNotchWidth", v)
            }
        }
        FormRow {
            label: "Closed width"
            FormStepper {
                value: Settings.values.closedNotchWidth
                from: 90
                to: 400
                step: 5
                onChanged: (v) => Settings.set("closedNotchWidth", v)
            }
        }
        FormRow {
            label: "Customise physical notch width"
            divider: false
            FormToggle {
                checked: Settings.values.customizePhysicalNotchWidth
                onToggled: (v) => Settings.set("customizePhysicalNotchWidth", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Media visuals"

        FormRow {
            label: "Music visualiser"
            FormToggle {
                checked: Settings.values.useMusicVisualizer
                onToggled: (v) => Settings.set("useMusicVisualizer", v)
            }
        }
        FormRow {
            label: "Visualiser bars"
            FormStepper {
                value: Settings.values.visualizerBarCount
                from: 2
                to: 8
                onChanged: (v) => Settings.set("visualizerBarCount", v)
            }
        }
        FormRow {
            label: "Waveform scrubber"
            FormToggle {
                checked: Settings.values.enableWaveformScrubber
                onToggled: (v) => Settings.set("enableWaveformScrubber", v)
            }
        }
        FormRow {
            label: "Slider colour"
            FormPicker {
                options: [
                    { value: "white", label: "White" },
                    { value: "accent", label: "Accent" },
                    { value: "player", label: "Match player" }
                ]
                value: Settings.values.sliderColor
                onSelected: (v) => Settings.set("sliderColor", v)
            }
        }
        FormRow {
            label: "Shuffle & repeat buttons"
            FormToggle {
                checked: Settings.values.showShuffleAndRepeat
                onToggled: (v) => Settings.set("showShuffleAndRepeat", v)
            }
        }
        FormRow {
            label: "Media output control"
            FormToggle {
                checked: Settings.values.showMediaOutputControl
                onToggled: (v) => Settings.set("showMediaOutputControl", v)
            }
        }
        FormRow {
            label: "Colour extraction"
            divider: false
            FormPicker {
                options: [
                    { value: "vibrant", label: "Vibrant" },
                    { value: "muted", label: "Muted" },
                    { value: "average", label: "Average" }
                ]
                value: Settings.values.colorExtractionMode
                onSelected: (v) => Settings.set("colorExtractionMode", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Desktop"

        FormRow {
            label: "Show emoji picker"
            FormToggle {
                checked: Settings.values.showEmojis
                onToggled: (v) => Settings.set("showEmojis", v)
            }
        }
        FormRow {
            label: "Show mirror"
            description: "A camera preview in the opened notch."
            settingKey: "showMirror"
            FormToggle {
                checked: Settings.values.showMirror
                onToggled: (v) => Settings.set("showMirror", v)
            }
        }
        FormRow {
            label: "Mirror shape"
            settingKey: "mirrorShape"
            FormPicker {
                options: [
                    { value: "rectangle", label: "Rectangle" },
                    { value: "circle", label: "Circle" }
                ]
                value: Settings.values.mirrorShape
                onSelected: (v) => Settings.set("mirrorShape", v)
            }
        }
        FormRow {
            label: "Hide from screen capture"
            description: "Keep the island out of recordings and screenshots."
            settingKey: "hideDynamicIslandFromScreenCapture"
            FormToggle {
                checked: Settings.values.hideDynamicIslandFromScreenCapture
                onToggled: (v) => Settings.set("hideDynamicIslandFromScreenCapture", v)
            }
        }
        FormRow {
            label: "Show labels in tiles"
            divider: false
            FormToggle {
                checked: Settings.values.tileShowLabels
                onToggled: (v) => Settings.set("tileShowLabels", v)
            }
        }
    }
}
