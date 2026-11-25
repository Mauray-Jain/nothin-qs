import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"

// The rail: one per monitor (rail.monitors), on the rail.position edge.
Scope {
    id: root

    readonly property var settings: Config.values.rail
    property bool caffeine: false

    Variants {
        model: Quickshell.screens.filter(s => Config.onMonitor(root.settings.monitors, s.name))

        PanelWindow {
            id: panel

            required property var modelData
            readonly property string position: root.settings.position
            readonly property bool vertical: position === "left" || position === "right"
            readonly property int tipEdge: position === "left" ? Edges.Right
                : position === "right" ? Edges.Left
                : position === "top" ? Edges.Bottom : Edges.Top

            screen: modelData
            anchors {
                left: position !== "right"
                right: position !== "left"
                top: position !== "bottom"
                bottom: position !== "top"
            }
            implicitWidth: 44
            implicitHeight: 40
            color: Theme.background

            IdleInhibitor { window: panel; enabled: root.caffeine }

            GridLayout {
                anchors { fill: parent; margins: 4 }
                flow: panel.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                rows: -1
                columns: -1
                rowSpacing: 4
                columnSpacing: 4

                RailButton {
                    Layout.alignment: Qt.AlignCenter
                    rail: panel
                    icon: "grid_view"
                    tip: "overview"
                    active: Compositor.overview
                    onClicked: Compositor.toggleOverview()
                }
                WorkspaceDots {
                    Layout.alignment: Qt.AlignCenter
                    output: panel.modelData.name
                    vertical: panel.vertical
                }
                Item { Layout.fillWidth: !panel.vertical; Layout.fillHeight: panel.vertical }

                FocusedApp { Layout.alignment: Qt.AlignCenter; rail: panel; output: panel.modelData.name }
                Tray { Layout.alignment: Qt.AlignCenter; rail: panel }
                Loader {
                    Layout.alignment: Qt.AlignCenter
                    Component.onCompleted: setSource("NetworkStatus.qml", { rail: panel })
                }
                Loader {
                    Layout.alignment: Qt.AlignCenter
                    Component.onCompleted: setSource("BluetoothStatus.qml", { rail: panel })
                }
                Volume { Layout.alignment: Qt.AlignCenter; rail: panel }
                Battery { Layout.alignment: Qt.AlignCenter; rail: panel }
                RailButton {
                    Layout.alignment: Qt.AlignCenter
                    rail: panel
                    icon: "coffee"
                    active: root.caffeine
                    tip: root.caffeine ? "caffeine on: staying awake" : "caffeine off"
                    onClicked: root.caffeine = !root.caffeine
                }
                RailButton {
                    Layout.alignment: Qt.AlignCenter
                    rail: panel
                    icon: Notifs.unread > 0 ? "notifications_unread" : "notifications"
                    active: Notifs.unread > 0 || Notifs.centerOpen
                    tip: Notifs.unread > 0 ? Notifs.unread + " new" : "notifications"
                    onClicked: Notifs.toggleCenter()
                }
                RailButton {
                    Layout.alignment: Qt.AlignCenter
                    rail: panel
                    icon: "tune"
                    active: DeckState.open
                    tip: "settings"
                    onClicked: DeckState.toggle()
                }
                RailClock {
                    Layout.alignment: Qt.AlignCenter
                    vertical: panel.vertical
                    h24: root.settings.clock_24h
                }
                RailButton {
                    id: power
                    Layout.alignment: Qt.AlignCenter
                    rail: panel
                    icon: "power_settings_new"
                    tip: "power"
                    onClicked: powerMenu.visible = !powerMenu.visible
                }
            }

            PowerMenu { id: powerMenu; target: power; rail: panel }
        }
    }
}
