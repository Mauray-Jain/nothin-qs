import QtQuick
import "../../core"
import "../../components"
import "../../services"

// WINDOWS: niri layout settings, written to nothin.kdl. Read-only until
// config.kdl includes that file. × puts one back to niri's own value.
Column {
    id: root

    readonly property var n: Config.values.niri ?? {}

    spacing: 4

    IncludeHint {}

    Column {
        objectName: "niri-controls"
        width: root.width
        spacing: 4
        enabled: NiriConfig.includesNothin
        opacity: enabled ? 1 : 0.4

        SettingRow {
            label: "gaps"
            SettingSegmented { path: "niri.gaps"; clearable: true; model: ["0", "4", "8", "12", "16", "24"]; values: [0, 4, 8, 12, 16, 24]; value: root.n.gaps }
        }
        SettingRow {
            label: "border"
            SettingSegmented { path: "niri.border_width"; clearable: true; model: ["off", "1", "2", "4"]; values: [0, 1, 2, 4]; value: root.n.border_width }
        }
        SettingRow {
            label: "focus ring"
            SettingSegmented { path: "niri.focus_ring"; clearable: true; model: ["on", "off"]; values: [true, false]; value: root.n.focus_ring }
        }
        SettingRow {
            label: "focus ring width"
            SettingSegmented { path: "niri.focus_ring_width"; clearable: true; model: ["1", "2", "4", "6"]; values: [1, 2, 4, 6]; value: root.n.focus_ring_width }
        }
        SettingRow {
            label: "rounded corners"
            SettingSegmented { path: "niri.corner_radius"; clearable: true; model: ["0", "6", "12", "20"]; values: [0, 6, 12, 20]; value: root.n.corner_radius }
        }
    }
}
