import QtQuick
import "../core"
import "Glyphs.js" as Glyphs

// Text drawn as circles on a 5×7 grid: clocks, counters, section titles.
Item {
    id: root

    property string text
    property real dotSize: 6
    property real gap: 2
    property color color: Theme.text

    readonly property var grid: Glyphs.layout(text)
    readonly property real pitch: dotSize + gap

    implicitWidth: Math.max(0, grid.columns * pitch - gap)
    implicitHeight: 7 * pitch - gap

    Repeater {
        model: root.grid.dots

        Rectangle {
            required property var modelData
            x: modelData.x * root.pitch
            y: modelData.y * root.pitch
            width: root.dotSize
            height: root.dotSize
            radius: root.dotSize / 2
            color: root.color
        }
    }
}
