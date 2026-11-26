import QtQuick
import "../../core"
import "../../components"
import "../../services"

// INPUT: keyboard, touchpad and mouse, written to nothin.kdl. niri replaces
// a whole touchpad or mouse section from an included file, so setting any
// touchpad key here replaces your config.kdl's touchpad section.
Column {
    id: root

    readonly property var n: Config.values.niri ?? {}
    readonly property var onOff: ["on", "off"]
    readonly property var bools: [true, false]
    readonly property var speeds: [-0.5, -0.25, 0, 0.25, 0.5]

    spacing: 4

    IncludeHint {}

    Column {
        width: root.width
        spacing: 4
        enabled: NiriConfig.includesNothin
        opacity: enabled ? 1 : 0.4

        SettingRow {
            label: "keyboard layout"
            SettingText { path: "niri.keyboard_layout"; value: root.n.keyboard_layout ?? ""; placeholder: "niri's own (e.g. us,de)"; fieldWidth: 220 }
        }
        SettingRow {
            label: "repeat delay"
            SettingSegmented { path: "niri.repeat_delay"; clearable: true; model: ["200", "300", "400", "600", "800"]; values: [200, 300, 400, 600, 800]; value: root.n.repeat_delay }
        }
        SettingRow {
            label: "repeat rate"
            SettingSegmented { path: "niri.repeat_rate"; clearable: true; model: ["15", "25", "35", "50"]; values: [15, 25, 35, 50]; value: root.n.repeat_rate }
        }
        SettingRow {
            label: "touchpad tap"
            SettingSegmented { path: "niri.touchpad_tap"; clearable: true; model: root.onOff; values: root.bools; value: root.n.touchpad_tap }
        }
        SettingRow {
            label: "touchpad natural scroll"
            SettingSegmented { path: "niri.touchpad_natural_scroll"; clearable: true; model: root.onOff; values: root.bools; value: root.n.touchpad_natural_scroll }
        }
        SettingRow {
            label: "off while typing"
            SettingSegmented { path: "niri.touchpad_dwt"; clearable: true; model: root.onOff; values: root.bools; value: root.n.touchpad_dwt }
        }
        SettingRow {
            label: "touchpad speed"
            SettingSegmented { path: "niri.touchpad_speed"; clearable: true; model: ["--", "-", "0", "+", "++"]; values: root.speeds; value: root.n.touchpad_speed }
        }
        SettingRow {
            label: "mouse speed"
            SettingSegmented { path: "niri.mouse_speed"; clearable: true; model: ["--", "-", "0", "+", "++"]; values: root.speeds; value: root.n.mouse_speed }
        }
        SettingRow {
            label: "mouse acceleration"
            SettingSegmented { path: "niri.mouse_accel"; clearable: true; model: ["adaptive", "flat"]; values: ["adaptive", "flat"]; value: root.n.mouse_accel }
        }
        SettingRow {
            label: "mouse natural scroll"
            SettingSegmented { path: "niri.mouse_natural_scroll"; clearable: true; model: root.onOff; values: root.bools; value: root.n.mouse_natural_scroll }
        }
        Text {
            width: parent.width
            wrapMode: Text.Wrap
            topPadding: 8
            text: "SETTING ANY TOUCHPAD OR MOUSE OPTION HERE REPLACES THAT WHOLE SECTION OF YOUR NIRI CONFIG (NIRI DOESN'T MERGE THEM)."
            color: Theme.label
            font.family: Theme.mono
            font.pixelSize: 10
            font.letterSpacing: 1
        }
    }
}
