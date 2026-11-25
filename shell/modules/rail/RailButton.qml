import QtQuick
import "../../core"
import "../../components"

// An icon on the rail: tap to act, scroll for steps, a tooltip on hover.
Item {
    id: root

    property var rail
    property string icon
    property string tip
    property bool active: false
    readonly property bool hovered: hover.hovered
    signal clicked()
    signal scrolled(int steps)

    implicitWidth: 36
    implicitHeight: 36

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: height / 2
        color: hover.hovered ? Theme.surfaceHigh : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        color: root.active ? Theme.accent : Theme.text
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.clicked() }
    WheelHandler { onWheel: e => root.scrolled(e.angleDelta.y > 0 ? 1 : -1) }

    Tooltip { target: root; rail: root.rail; text: root.tip; shown: hover.hovered }
}
