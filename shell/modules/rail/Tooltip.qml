import QtQuick
import Quickshell
import "../../core"

// A caps label beside `target`, on the side away from the screen edge.
PopupWindow {
    id: root

    property Item target
    property var rail
    property string text
    property bool shown: false

    anchor.item: target
    anchor.edges: rail ? rail.tipEdge : Edges.Right
    anchor.gravity: rail ? rail.tipEdge : Edges.Right
    visible: shown && text !== ""
    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceHigh

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text.toUpperCase()
            color: Theme.text
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: Theme.labelSpacing
        }
    }
}
