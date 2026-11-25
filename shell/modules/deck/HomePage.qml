import QtQuick
import "../../core"
import "../../components"

// HOME: the desktop's layout, hero, widgets, system rows and placement.
Column {
    id: root

    readonly property var d: Config.values.desktop ?? {}
    readonly property var allWidgets: ["weather", "calendar", "player", "system"]
    readonly property var allSystem: ["cpu", "memory", "disk", "temperature"]

    // Switching an item on adds it at the end; off removes it.
    function flip(list, item) {
        return list.includes(item) ? list.filter(x => x !== item) : list.concat([item])
    }

    spacing: 4

    SettingRow {
        label: "layout"
        SettingSegmented { path: "desktop.layout"; model: ["grid", "free"]; values: ["grid", "free"]; value: root.d.layout }
    }
    SettingRow {
        label: "hero clock"
        SettingToggle { objectName: "toggle-hero_clock"; path: "desktop.hero_clock"; value: root.d.hero_clock ?? true }
    }
    SettingRow {
        label: "greeting"
        SettingToggle { objectName: "toggle-greeting"; path: "desktop.greeting"; value: root.d.greeting ?? true }
    }
    SettingRow {
        label: "widgets"
        Row {
            spacing: 6
            Repeater {
                model: root.allWidgets
                Pill {
                    required property string modelData
                    objectName: "widget-" + modelData
                    text: modelData
                    active: (root.d.widgets ?? []).includes(modelData)
                    onClicked: Config.set("desktop.widgets", root.flip(root.d.widgets ?? [], modelData))
                }
            }
        }
    }
    SettingRow {
        label: "system rows"
        Row {
            spacing: 6
            Repeater {
                model: root.allSystem
                Pill {
                    required property string modelData
                    objectName: "system-" + modelData
                    text: modelData === "temperature" ? "temp" : modelData
                    active: (root.d.system ?? []).includes(modelData)
                    onClicked: Config.set("desktop.system", root.flip(root.d.system ?? [], modelData))
                }
            }
        }
    }
    SettingRow {
        label: "place (drag)"
        height: placer.height + 12
        Placer { id: placer }
    }
    SettingRow {
        label: ""
        Pill { text: "reset places"; onClicked: Config.set("desktop.positions", {}) }
    }
}
