import QtQuick
import "../../core"
import "../desktop/Layout.js" as Layout

// A small picture of the screen; drag a widget to place it. Dropping one
// switches the desktop to the free layout and saves desktop.positions.
Rectangle {
    id: root

    readonly property var d: Config.values.desktop ?? {}
    readonly property bool withHero: d.hero_clock || d.greeting
    readonly property var widgets: d.widgets ?? []

    width: 400
    height: width * 10 / 16
    radius: 12
    color: Theme.background
    border.width: 1
    border.color: Theme.surfaceHigh

    Rectangle {
        readonly property var r: Layout.hero(root.width, root.height)
        visible: root.withHero
        x: r.x; y: r.y; width: r.width; height: r.height
        radius: 6
        color: Theme.surface
        opacity: 0.5
        Text {
            anchors.centerIn: parent
            text: "CLOCK"
            color: Theme.label
            font.family: Theme.mono
            font.pixelSize: 9
            font.letterSpacing: Theme.labelSpacing
        }
    }

    Repeater {
        model: root.widgets

        Rectangle {
            id: box
            required property string modelData
            required property int index
            readonly property var r: Layout.place(Object.assign({}, root.d, { layout: "free" }), modelData, index, root.withHero, root.width, root.height)

            objectName: "place-" + modelData
            x: r.x; y: r.y; width: r.width; height: r.height
            radius: 6
            color: drag.drag.active ? Theme.surfaceHigh : Theme.surface
            border.width: drag.drag.active ? 1 : 0
            border.color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: box.modelData.toUpperCase()
                color: Theme.text
                font.family: Theme.mono
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }

            MouseArea {
                id: drag
                anchors.fill: parent
                drag.target: box
                drag.minimumX: 0
                drag.minimumY: 0
                drag.maximumX: root.width - box.width
                drag.maximumY: root.height - box.height
                onReleased: {
                    const place = [Math.round(box.x / root.width * 100) / 100, Math.round(box.y / root.height * 100) / 100]
                    const positions = Object.assign({}, root.d.positions ?? {})
                    positions[box.modelData] = place
                    if (root.d.layout !== "free")
                        Config.set("desktop.layout", "free")
                    Config.set("desktop.positions", positions)
                    box.x = Qt.binding(() => box.r.x)
                    box.y = Qt.binding(() => box.r.y)
                }
            }
        }
    }
}
