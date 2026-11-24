import QtQuick
import "../core"

// A pill switch. Click, tap, Space or Enter flips it.
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    function toggle() {
        checked = !checked
        toggled()
    }

    implicitWidth: 44
    implicitHeight: 24
    radius: height / 2
    color: checked ? Theme.text : Theme.surfaceHigh
    border.width: activeFocus ? 1 : 0
    border.color: Theme.textSecondary
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 4 : 4
        color: root.checked ? Theme.background : Theme.textSecondary
        Behavior on x { NumberAnimation { duration: Theme.fast } }
    }

    TapHandler { onTapped: root.toggle() }
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Space || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            root.toggle()
            e.accepted = true
        }
    }
}
