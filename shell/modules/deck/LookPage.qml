import QtQuick
import "../../core"
import "../../components"

// LOOK: accent, wallpaper effect, dots and light, rail position and clock.
Column {
    id: root

    readonly property var swatches: ["#d71921", "#ff7a00", "#ffd400", "#2fbf71", "#3b82f6", "#ffffff"]
    readonly property var w: Config.values.wallpaper ?? {}
    readonly property var rail: Config.values.rail ?? {}

    spacing: 4

    SettingRow {
        label: "accent"
        Row {
            spacing: 10
            Repeater {
                model: root.swatches
                Rectangle {
                    required property string modelData
                    objectName: "swatch-" + modelData
                    width: 26
                    height: 26
                    radius: 13
                    color: modelData
                    border.width: Qt.colorEqual(Theme.accent, modelData) ? 3 : 0
                    border.color: Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    TapHandler { onTapped: Config.set("theme.accent", parent.modelData) }
                }
            }
            Rectangle {
                width: 110
                height: 32
                radius: 16
                color: Theme.surfaceHigh
                anchors.verticalCenter: parent.verticalCenter
                TextInput {
                    objectName: "accent-field"
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    text: Config.values.theme?.accent ?? ""
                    color: Theme.text
                    font.family: Theme.mono
                    font.pixelSize: 12
                    onAccepted: if (/^#[0-9a-fA-F]{6}$/.test(text)) Config.set("theme.accent", text.toLowerCase())
                }
            }
        }
    }
    SettingRow {
        label: "wallpaper"
        SettingSegmented {
            path: "wallpaper.effect"
            model: ["dots", "color", "mono", "none"]
            values: ["dots", "color", "mono", "none"]
            value: root.w.effect
        }
    }
    SettingRow {
        label: "dot size"
        SettingKnob { path: "wallpaper.dot_size"; min: 4; max: 64; value: root.w.dot_size ?? 17 }
    }
    SettingRow {
        label: "light"
        SettingKnob { path: "wallpaper.light"; min: 0; max: 100; value: root.w.light ?? 50 }
    }
    SettingRow {
        label: "rail"
        SettingSegmented {
            path: "rail.position"
            model: ["left", "top", "right", "bottom"]
            values: ["left", "top", "right", "bottom"]
            value: root.rail.position
        }
    }
    SettingRow {
        label: "24-hour clock"
        SettingToggle { path: "rail.clock_24h"; value: root.rail.clock_24h ?? true }
    }
}
