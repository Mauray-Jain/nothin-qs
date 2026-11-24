import QtQuick
import "../core"

// A ring of dots; the first `value` share of them is lit, clockwise.
Item {
    id: root

    property int dots: 40
    property real value: 0
    property real diameter: 64
    property real dotSize: 4
    property real startAngle: -90 // degrees; 0 is three o'clock, -90 twelve
    property real sweep: 360
    property color color: Theme.text
    property color offColor: Theme.label

    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * dots)

    implicitWidth: diameter
    implicitHeight: diameter

    // A full ring spaces dots evenly; an arc puts one on each end.
    function dotCentre(i) {
        const step = sweep >= 360 ? sweep / dots : sweep / (dots - 1)
        const a = (startAngle + i * step) * Math.PI / 180
        const r = (diameter - dotSize) / 2
        return Qt.point(diameter / 2 + r * Math.cos(a), diameter / 2 + r * Math.sin(a))
    }

    Repeater {
        model: root.dots

        Rectangle {
            required property int index
            readonly property point centre: root.dotCentre(index)
            x: centre.x - width / 2
            y: centre.y - height / 2
            width: root.dotSize
            height: root.dotSize
            radius: root.dotSize / 2
            color: index < root.lit ? root.color : root.offColor
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }
}
