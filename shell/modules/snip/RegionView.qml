import QtQuick
import "../../core"
import "Snip.js" as Snip

// The frozen screen: drag to pick an area, Enter for all of it, Escape to
// cancel. Draws the screenshot (`source`) dimmed outside the selection.
FocusScope {
    id: root

    property url source
    property var sel: null

    signal chosen(var rect)
    signal cancelled()

    focus: true
    Keys.onReturnPressed: chosen({ x: 0, y: 0, width: width, height: height })
    Keys.onEnterPressed: chosen({ x: 0, y: 0, width: width, height: height })
    Keys.onEscapePressed: cancelled()

    Image {
        anchors.fill: parent
        source: root.source
        fillMode: Image.Stretch
    }

    // Dim everything but the selection.
    Repeater {
        model: root.sel ? [
            { x: 0, y: 0, width: root.width, height: root.sel.y },
            { x: 0, y: root.sel.y + root.sel.height, width: root.width, height: root.height - root.sel.y - root.sel.height },
            { x: 0, y: root.sel.y, width: root.sel.x, height: root.sel.height },
            { x: root.sel.x + root.sel.width, y: root.sel.y, width: root.width - root.sel.x - root.sel.width, height: root.sel.height }
        ] : [{ x: 0, y: 0, width: root.width, height: root.height }]
        Rectangle {
            required property var modelData
            x: modelData.x; y: modelData.y; width: modelData.width; height: modelData.height
            color: "black"
            opacity: 0.45
        }
    }

    Rectangle {
        visible: root.sel !== null
        x: root.sel ? root.sel.x : 0
        y: root.sel ? root.sel.y : 0
        width: root.sel ? root.sel.width : 0
        height: root.sel ? root.sel.height : 0
        color: "transparent"
        border.width: 1
        border.color: Theme.accent
    }

    Text {
        x: 24; y: 20
        text: root.sel ? Math.round(root.sel.width) + " × " + Math.round(root.sel.height)
                       : "DRAG TO SELECT · ENTER FOR THE WHOLE SCREEN · ESC TO CANCEL"
        color: "white"
        style: Text.Outline
        styleColor: "black"
        font.family: Theme.mono
        font.pixelSize: 12
        font.letterSpacing: Theme.labelSpacing
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        property point start
        onPressed: e => { start = Qt.point(e.x, e.y); root.sel = null }
        onPositionChanged: e => root.sel = Snip.rectFrom(start, Qt.point(e.x, e.y))
        onReleased: e => {
            const r = Snip.rectFrom(start, Qt.point(e.x, e.y))
            if (r.width > 4 && r.height > 4)
                root.chosen(r)
            else
                root.sel = null
        }
    }
}
