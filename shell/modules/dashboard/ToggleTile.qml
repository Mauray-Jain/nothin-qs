import QtQuick
import "../../core"
import "../../components"

// A square-ish quick toggle: icon and caps label, filled white when on.
Rectangle {
    id: root

    property string icon
    property string label
    property bool on: false
    signal clicked()

    implicitWidth: 118
    implicitHeight: 84
    radius: Theme.radius
    color: on ? Theme.text : Theme.surfaceHigh
    border.width: activeFocus ? 1 : 0
    border.color: Theme.textSecondary
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Icon {
        x: 16; y: 14
        name: root.icon
        color: root.on ? Theme.background : Theme.text
    }
    Text {
        x: 16
        width: parent.width - 28
        anchors { bottom: parent.bottom; bottomMargin: 12 }
        wrapMode: Text.Wrap
        maximumLineCount: 2
        text: root.label.toUpperCase()
        color: root.on ? Theme.background : Theme.textSecondary
        font.family: Theme.mono
        font.pixelSize: 10
        font.letterSpacing: Theme.labelSpacing
    }

    TapHandler { onTapped: root.clicked() }
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Space || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            root.clicked()
            e.accepted = true
        }
    }
}
