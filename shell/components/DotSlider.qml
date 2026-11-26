import QtQuick
import "../core"

// A horizontal dot level you can set: click or drag along it, or use the
// arrow keys. It doesn't change `value` itself; it emits moved(v) and the
// owner (volume, brightness) sets value from the real level.
Item {
    id: root

    property real value: 0
    property real step: 0.05
    signal moved(real v)

    function ask(v) {
        moved(Math.max(0, Math.min(1, v)))
    }

    implicitWidth: 240
    implicitHeight: 24
    activeFocusOnTab: true

    DotBar {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        dots: Math.max(4, Math.floor((parent.width + gap) / (dotSize + gap)))
        value: root.value
        color: root.activeFocus ? Theme.accent : Theme.text
    }

    MouseArea {
        anchors.fill: parent
        onPressed: e => root.ask(e.x / width)
        onPositionChanged: e => { if (pressed) root.ask(e.x / width) }
        onWheel: e => root.ask(root.value + (e.angleDelta.y > 0 ? root.step : -root.step))
    }

    Keys.onRightPressed: ask(value + step)
    Keys.onUpPressed: ask(value + step)
    Keys.onLeftPressed: ask(value - step)
    Keys.onDownPressed: ask(value - step)
}
