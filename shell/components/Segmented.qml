import QtQuick
import "../core"

// Equal-width options in one track; one is current (or none, at -1).
// Click, tap or Left/Right.
Rectangle {
    id: root

    property var model: []
    property int currentIndex: 0
    readonly property bool highlightVisible: currentIndex >= 0 && currentIndex < model.length
    signal activated(int index)

    function pick(i) {
        i = Math.max(0, Math.min(model.length - 1, i))
        if (i === currentIndex)
            return
        currentIndex = i
        activated(i)
    }

    readonly property real segmentWidth: {
        let w = 0
        for (let i = 0; i < measure.count; i++)
            w = Math.max(w, measure.itemAt(i).implicitWidth)
        return w + 32
    }

    implicitWidth: segmentWidth * model.length + 8
    implicitHeight: 40
    radius: height / 2
    color: Theme.surfaceHigh
    border.width: activeFocus ? 1 : 0
    border.color: Theme.textSecondary
    activeFocusOnTab: true

    Repeater {
        id: measure
        model: root.model
        Text {
            visible: false
            text: modelData.toUpperCase()
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: Theme.labelSpacing
        }
    }

    Rectangle {
        visible: root.highlightVisible
        x: 4 + root.currentIndex * root.segmentWidth
        y: 4
        width: root.segmentWidth
        height: root.height - 8
        radius: height / 2
        color: Theme.text
        Behavior on x { NumberAnimation { duration: Theme.fast } }
    }

    Row {
        x: 4
        y: 4
        Repeater {
            model: root.model
            Item {
                required property int index
                required property string modelData
                width: root.segmentWidth
                height: root.height - 8

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData.toUpperCase()
                    color: parent.index === root.currentIndex ? Theme.background : Theme.textSecondary
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.letterSpacing: Theme.labelSpacing
                }
                TapHandler { onTapped: root.pick(parent.index) }
            }
        }
    }

    Keys.onLeftPressed: pick(currentIndex - 1)
    Keys.onRightPressed: pick(currentIndex + 1)
}
