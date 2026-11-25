import QtQuick
import "../../core"
import "../../components"

// A Knob for a whole number between min and max. Saves once the knob has
// been still for a moment, not on every step of a drag.
Row {
    id: root

    property string path
    property int min: 0
    property int max: 100
    property int value

    spacing: 12

    Knob {
        id: knob
        diameter: 44
        value: (root.value - root.min) / (root.max - root.min)
        onMoved: save.restart()
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        text: Math.round(root.min + knob.value * (root.max - root.min))
        color: Theme.text
        font.family: Theme.mono
        font.pixelSize: 13
    }

    Timer {
        id: save
        interval: 300
        onTriggered: {
            Config.set(root.path, Math.round(root.min + knob.value * (root.max - root.min)))
            knob.value = Qt.binding(() => (root.value - root.min) / (root.max - root.min))
        }
    }
}
