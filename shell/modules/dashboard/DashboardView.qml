import QtQuick
import "../../core"
import "../../components"
import "../../services"
import "../desktop"

// The dashboard's contents. Toggles and sliders only ask (the owner knows
// how to switch Wi-Fi or set volume); do-not-disturb lives in Notifs.
// mediaSlot is where Dashboard.qml puts the player card.
Rectangle {
    id: root

    property bool wifiOn: false
    property bool bluetoothOn: false
    property bool caffeineOn: false
    property real volume: 0
    property real brightness: 0
    property bool hasBrightness: false
    property alias mediaSlot: media

    signal toggleRequested(string name) // wifi | bluetooth | caffeine
    signal volumeRequested(real v)
    signal brightnessRequested(real v)

    radius: Theme.radius
    color: Theme.surface

    Row {
        id: top
        x: 20; y: 20
        spacing: 10

        ToggleTile { objectName: "toggle-wifi"; icon: "wifi"; label: "wi-fi"; on: root.wifiOn; onClicked: root.toggleRequested("wifi") }
        ToggleTile { objectName: "toggle-bluetooth"; icon: "bluetooth"; label: "bluetooth"; on: root.bluetoothOn; onClicked: root.toggleRequested("bluetooth") }
        ToggleTile { objectName: "toggle-caffeine"; icon: "coffee"; label: "caffeine"; on: root.caffeineOn; onClicked: root.toggleRequested("caffeine") }
        ToggleTile { objectName: "toggle-dnd"; icon: "do_not_disturb_on"; label: "do not disturb"; on: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 20
            spacing: 14

            Row {
                spacing: 14
                Icon { name: "volume_up"; size: 20; anchors.verticalCenter: parent.verticalCenter }
                DotSlider {
                    objectName: "slider-volume"
                    width: root.width - top.x - 4 * 128 - 140
                    value: root.volume
                    onMoved: v => root.volumeRequested(v)
                }
            }
            Row {
                visible: root.hasBrightness
                spacing: 14
                Icon { name: "light_mode"; size: 20; anchors.verticalCenter: parent.verticalCenter }
                DotSlider {
                    objectName: "slider-brightness"
                    width: root.width - top.x - 4 * 128 - 140
                    value: root.brightness
                    onMoved: v => root.brightnessRequested(v)
                }
            }
        }
    }

    Row {
        anchors { left: parent.left; right: parent.right; top: top.bottom; bottom: parent.bottom; margins: 20 }
        spacing: 12
        readonly property real third: (width - 2 * spacing) / 3

        Item { id: media; width: parent.third; height: parent.height }
        SystemCard { width: parent.third; height: parent.height; color: Theme.surfaceHigh }
        ProcessCard { width: parent.third; height: parent.height; color: Theme.surfaceHigh }
    }
}
