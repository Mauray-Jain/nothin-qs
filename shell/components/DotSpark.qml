import QtQuick
import "../core"

// A dotted sparkline: one column per value, the dot at its level lit.
Item {
    id: root

    property var values: []
    property int rows: 5
    property real dotSize: 4
    property real gap: 2
    property color color: Theme.text
    property color offColor: Theme.surfaceHigh

    readonly property real pitch: dotSize + gap
    readonly property real lo: Math.min(...values)
    readonly property real hi: Math.max(...values)

    implicitWidth: Math.max(0, values.length * pitch - gap)
    implicitHeight: rows * pitch - gap

    // level of value i, 0 (bottom) to rows - 1. A flat series sits in the middle.
    function level(i) {
        if (hi === lo)
            return Math.floor(rows / 2)
        return Math.round((values[i] - lo) / (hi - lo) * (rows - 1))
    }

    Repeater {
        model: root.values.length * root.rows

        Rectangle {
            required property int index
            readonly property int column: Math.floor(index / root.rows)
            readonly property int row: index % root.rows
            x: column * root.pitch
            y: (root.rows - 1 - row) * root.pitch
            width: root.dotSize
            height: root.dotSize
            radius: root.dotSize / 2
            color: root.level(column) === row ? root.color : root.offColor
        }
    }
}
