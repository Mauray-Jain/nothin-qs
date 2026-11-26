import QtQuick
import "../../core"
import "../../services"
import "Arrange.js" as Arrange

// The monitors that are on, to scale. Drag one to move it; it snaps to the
// others' edges. Dropping saves its x and y.
Rectangle {
    id: root

    property string selected
    readonly property var outs: Compositor.outputs.filter(o => o.on)
    readonly property real minX: Math.min(...outs.map(o => o.x), 0)
    readonly property real minY: Math.min(...outs.map(o => o.y), 0)
    readonly property real spanW: Math.max(...outs.map(o => o.x + o.width), 1) - minX
    readonly property real spanH: Math.max(...outs.map(o => o.y + o.height), 1) - minY
    readonly property real k: Math.min((width - 40) / spanW, (height - 40) / spanH)

    signal picked(string name)

    width: 460
    height: 220
    radius: 12
    color: Theme.background

    Repeater {
        model: root.outs

        Rectangle {
            id: box
            required property var modelData
            readonly property real homeX: 20 + (modelData.x - root.minX) * root.k
            readonly property real homeY: 20 + (modelData.y - root.minY) * root.k

            objectName: "arrange-" + modelData.name
            x: homeX
            y: homeY
            width: modelData.width * root.k
            height: modelData.height * root.k
            radius: 6
            color: modelData.name === root.selected ? Theme.surfaceHigh : Theme.surface
            border.width: modelData.name === root.selected ? 1 : 0
            border.color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: box.modelData.name.toUpperCase()
                color: Theme.text
                font.family: Theme.mono
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }

            MouseArea {
                anchors.fill: parent
                drag.target: box
                onPressed: root.picked(box.modelData.name)
                onReleased: {
                    const me = box.modelData
                    const want = {
                        x: Math.round((box.x - 20) / root.k + root.minX),
                        y: Math.round((box.y - 20) / root.k + root.minY),
                        width: me.width, height: me.height
                    }
                    const p = Arrange.snap(want, root.outs.filter(o => o.name !== me.name), 80)
                    Config.set("display.monitors." + me.name + ".x", p.x)
                    Config.set("display.monitors." + me.name + ".y", p.y)
                    box.x = Qt.binding(() => box.homeX)
                    box.y = Qt.binding(() => box.homeY)
                }
            }
        }
    }
}
