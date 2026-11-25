import QtQuick
import "../../core"
import "../../components"

// IDLE: timeouts on AC and on battery, fade and suspend mode.
Column {
    id: root

    readonly property var idle: Config.values.idle ?? {}
    readonly property var labels: ["off", "1m", "2m", "3m", "5m", "10m", "15m", "30m"]
    readonly property var seconds: [0, 60, 120, 180, 300, 600, 900, 1800]
    readonly property var steps: [
        { key: "lock", label: "lock" },
        { key: "screen_off", label: "screen off" },
        { key: "suspend", label: "suspend" },
        { key: "lock_screen_off", label: "off when locked" }
    ]

    spacing: 4

    Repeater {
        model: ["ac", "battery"]

        Column {
            id: section
            required property string modelData
            width: root.width
            spacing: 4

            Text {
                topPadding: 8
                text: section.modelData === "ac" ? "ON AC" : "ON BATTERY"
                color: Theme.label
                font.family: Theme.mono
                font.pixelSize: 10
                font.letterSpacing: Theme.labelSpacing
            }

            Repeater {
                model: root.steps
                SettingRow {
                    required property var modelData
                    label: modelData.label
                    SettingSegmented {
                        path: "idle." + section.modelData + "." + parent.parent.modelData.key
                        model: root.labels
                        values: root.seconds
                        value: (root.idle[section.modelData] ?? {})[parent.parent.modelData.key]
                    }
                }
            }
        }
    }

    SettingRow {
        label: "fade before lock"
        SettingSegmented { path: "idle.fade"; model: ["off", "5s", "10s"]; values: [0, 5, 10]; value: root.idle.fade }
    }
    SettingRow {
        label: "suspend means"
        SettingSegmented {
            path: "idle.suspend_mode"
            model: ["suspend", "hibernate", "both"]
            values: ["suspend", "hibernate", "suspend-then-hibernate"]
            value: root.idle.suspend_mode
        }
    }
}
