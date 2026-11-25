import QtQuick
import "../../core"
import "../../components"
import "../../services"

Card {
    id: root

    readonly property bool hasData: Weather.ready
    readonly property var w: Weather.now
    readonly property string tempText: hasData ? Math.round(w.temp) + "°" : "--"

    Text {
        x: 24; y: 22
        text: "WEATHER" + (root.hasData ? " · " + root.w.place.toUpperCase() : "")
        color: Theme.label
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: Theme.labelSpacing
    }

    Row {
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 20

        DotText { text: root.tempText; dotSize: 7; gap: 3; anchors.verticalCenter: parent.verticalCenter }
        Icon {
            visible: root.hasData
            name: root.w.icon ?? ""
            size: 48
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Column {
        x: 24
        anchors { bottom: parent.bottom; bottomMargin: 22 }
        spacing: 4
        visible: root.hasData

        Text {
            text: (root.w.condition ?? "").toUpperCase()
            color: Theme.text
            font.family: Theme.mono
            font.pixelSize: 12
            font.letterSpacing: Theme.labelSpacing
        }
        Text {
            text: "L " + Math.round(root.w.min) + "°  H " + Math.round(root.w.max) + "°"
            color: Theme.textSecondary
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: Theme.labelSpacing
        }
    }
}
