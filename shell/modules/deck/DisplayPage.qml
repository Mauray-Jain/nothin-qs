import QtQuick
import "../../core"
import "../../components"
import "../../services"
import "Arrange.js" as Arrange

// DISPLAY: per monitor, applied live through niri and saved under
// [display.monitors."<name>"].
Column {
    id: root

    property int sel: Math.max(0, Compositor.outputs.findIndex(o => o.name === Compositor.focusedOutput))
    readonly property var out: Compositor.outputs[sel] ?? null
    readonly property string name: out ? out.name : ""
    readonly property var cfg: (Config.values.display?.monitors ?? {})[name] ?? {}
    readonly property string base: "display.monitors." + name + "."

    function pick(v, fallback) { return v === undefined || v === null ? fallback : v }

    spacing: 4

    Text {
        visible: !root.out
        text: "NO MONITORS REPORTED BY NIRI"
        color: Theme.label
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: Theme.labelSpacing
    }

    SettingRow {
        visible: !!root.out
        label: "monitor"
        Segmented {
            objectName: "monitor-pick"
            model: Compositor.outputs.map(o => o.name)
            currentIndex: root.sel
            onActivated: i => root.sel = i
        }
    }
    SettingRow {
        visible: !!root.out
        label: "arrange (drag)"
        height: arranger.height + 12
        MonitorArranger {
            id: arranger
            selected: root.name
            onPicked: n => root.sel = Compositor.outputs.findIndex(o => o.name === n)
        }
    }
    SettingRow {
        visible: !!root.out
        label: "on"
        SettingSegmented {
            path: root.base + "enabled"
            model: ["on", "off"]; values: [true, false]
            value: root.pick(root.cfg.enabled, root.out ? root.out.on : true)
        }
    }
    SettingRow {
        visible: !!root.out
        label: "scale"
        SettingSegmented {
            // The presets, plus the current scale if it's none of them (e.g. 1.4).
            readonly property real current: root.pick(root.cfg.scale, root.out ? root.out.scale : 1)
            readonly property var options: [1, 1.25, 1.5, 1.75, 2].concat(
                [1, 1.25, 1.5, 1.75, 2].includes(current) ? [] : [current]).sort((a, b) => a - b)
            path: root.base + "scale"
            model: options.map(String); values: options
            value: current
        }
    }
    SettingRow {
        visible: !!root.out
        label: "rotation"
        SettingSegmented {
            path: root.base + "transform"
            model: ["0°", "90°", "180°", "270°"]; values: ["normal", "90", "180", "270"]
            value: root.pick(root.cfg.transform, root.out ? root.out.transform : "normal")
        }
    }
    SettingRow {
        visible: !!root.out && root.out.vrr_supported
        label: "variable refresh"
        SettingSegmented {
            path: root.base + "vrr"
            model: ["on", "off"]; values: [true, false]
            value: root.pick(root.cfg.vrr, root.out ? root.out.vrr_enabled : false)
        }
    }
    SettingRow {
        visible: !!root.out
        label: "resolution"
        height: modes.height + 12
        Flow {
            id: modes
            width: 460
            spacing: 6
            layoutDirection: Qt.RightToLeft
            readonly property string current: root.pick(root.cfg.mode, root.out ? Arrange.currentMode(root.out) : "")

            Repeater {
                model: root.out ? Arrange.modes(root.out) : []
                Pill {
                    required property var modelData
                    objectName: "mode-" + modelData.value
                    text: modelData.label
                    active: modes.current === modelData.value
                    onClicked: Config.set(root.base + "mode", modelData.value)
                }
            }
        }
    }
}
