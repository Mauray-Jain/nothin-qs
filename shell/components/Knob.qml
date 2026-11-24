import QtQuick
import "../core"

// A dotted knob, 0 to 1. Drag up or down (a full height is the whole range),
// scroll, or use the arrow keys.
Item {
    id: root

    property real value: 0
    property real step: 0.05
    property real diameter: 72
    signal moved()

    function setValue(v) {
        v = Math.max(0, Math.min(1, v))
        if (v === value)
            return
        value = v
        moved()
    }

    implicitWidth: diameter
    implicitHeight: diameter
    activeFocusOnTab: true

    DotRing {
        anchors.fill: parent
        diameter: root.diameter
        dots: 28
        startAngle: 135
        sweep: 270
        value: root.value
        color: root.activeFocus ? Theme.accent : Theme.text
    }

    MouseArea {
        anchors.fill: parent
        property real startY
        property real startValue
        onPressed: e => { startY = e.y; startValue = root.value }
        onPositionChanged: e => root.setValue(startValue + (startY - e.y) / root.height)
        onWheel: e => root.setValue(root.value + (e.angleDelta.y > 0 ? root.step : -root.step))
    }

    Keys.onUpPressed: setValue(value + step)
    Keys.onRightPressed: setValue(value + step)
    Keys.onDownPressed: setValue(value - step)
    Keys.onLeftPressed: setValue(value - step)
}
