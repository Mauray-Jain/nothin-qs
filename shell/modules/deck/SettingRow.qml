import QtQuick
import "../../core"

// A label on the left, its control on the right.
Item {
    id: row

    property string label
    default property alias content: slot.data

    width: parent ? parent.width : 400
    height: Math.max(44, slot.childrenRect.height)

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: row.label.toUpperCase()
        color: Theme.textSecondary
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: Theme.labelSpacing
    }

    Item {
        id: slot
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: childrenRect.width
        height: childrenRect.height
    }
}
