import QtQuick
import "../core"

// A straight row of dots; the first `value` share of them is lit.
Row {
    id: root

    property int dots: 20
    property real value: 0
    property real dotSize: 6
    property real gap: 4
    property color color: Theme.text
    property color offColor: Theme.label

    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * dots)

    spacing: gap

    Repeater {
        model: root.dots
        Rectangle {
            required property int index
            width: root.dotSize
            height: root.dotSize
            radius: root.dotSize / 2
            color: index < root.lit ? root.color : root.offColor
        }
    }
}
