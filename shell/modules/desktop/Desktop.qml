import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "Layout.js" as Layout

// The desktop home on each monitor in desktop.monitors: hero clock and
// greeting, and the widgets in desktop.widgets. It sits above the wallpaper
// and below windows, and only the widget cards take input.
Scope {
    Variants {
        model: Quickshell.screens.filter(s => Config.onMonitor(Config.values.desktop.monitors, s.name))

        PanelWindow {
            id: win

            required property var modelData
            readonly property var d: Config.values.desktop
            readonly property bool withHero: d.hero_clock || d.greeting

            screen: modelData
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "nothin-desktop"
            exclusionMode: ExclusionMode.Normal
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"

            mask: Region {
                Region { item: widgets.count > 0 ? widgets.itemAt(0) : null }
                Region { item: widgets.count > 1 ? widgets.itemAt(1) : null }
                Region { item: widgets.count > 2 ? widgets.itemAt(2) : null }
                Region { item: widgets.count > 3 ? widgets.itemAt(3) : null }
            }

            Hero {
                readonly property var r: Layout.hero(win.width, win.height)
                visible: win.withHero
                x: r.x
                y: r.y
            }

            Repeater {
                id: widgets
                model: win.d.widgets

                Loader {
                    required property string modelData
                    required property int index
                    readonly property var r: Layout.place(win.d, modelData, index, win.withHero, win.width, win.height)

                    x: r.x
                    y: r.y
                    width: r.width
                    height: r.height
                    sourceComponent: ({ weather: weather, calendar: calendar, player: player, system: system })[modelData]
                }
            }

            Component { id: weather; WeatherCard {} }
            Component { id: calendar; CalendarCard {} }
            Component { id: player; PlayerCard {} }
            Component { id: system; SystemCard {} }
        }
    }
}
