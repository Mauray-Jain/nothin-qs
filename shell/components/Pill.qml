import QtQuick
import "../core"

// A rounded caps label that can be pressed. `active` fills it.
Rectangle {
    id: root

    property string text
    property bool active: false
    signal clicked()

    implicitWidth: label.implicitWidth + 32
    implicitHeight: 32
    radius: height / 2
    color: active ? Theme.text : Theme.surfaceHigh
    border.width: activeFocus ? 1 : 0
    border.color: Theme.textSecondary
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text.toUpperCase()
        color: root.active ? Theme.background : Theme.text
        font.family: Theme.mono
        font.pixelSize: 11
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
