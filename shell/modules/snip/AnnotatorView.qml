import QtQuick
import "../../core"
import "../../components"
import "Snip.js" as Snip

// The annotator: the selected part of the screenshot with pen, arrow,
// rectangle, text and blur (pixelate) on top. Keys: P A R T B pick a tool,
// Ctrl+Z undoes, Enter copies, Ctrl+S saves, Escape cancels.
FocusScope {
    id: root

    property url source
    property var crop: ({ x: 0, y: 0, width: 100, height: 100 }) // logical pixels of the screen
    property real sourceScale: 1                                // image pixels per logical pixel
    property string tool: "pen"
    property color colour: Theme.accent
    property var shapes: []
    property var draft: null
    property bool editing: false

    readonly property var colours: [{ name: "accent", value: Theme.accent }, { name: "white", value: "#ffffff" }, { name: "black", value: "#000000" }]

    signal copyRequested()
    signal saveRequested()
    signal cancelled()

    function clear() { shapes = []; draft = null; editing = false }
    function add(s) { shapes = shapes.concat([s]) }
    function undo() { shapes = shapes.slice(0, -1) }

    // exportImage saves the sheet at full image resolution to path, then calls done(ok).
    function exportImage(path, done) {
        sheet.grabToImage(r => done(r.saveToFile(path)),
            Qt.size(Math.round(crop.width * sourceScale), Math.round(crop.height * sourceScale)))
    }

    focus: true
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Z && (e.modifiers & Qt.ControlModifier)) undo()
        else if (e.key === Qt.Key_S && (e.modifiers & Qt.ControlModifier)) saveRequested()
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) copyRequested()
        else if (e.key === Qt.Key_Escape) cancelled()
        else if (e.key === Qt.Key_P) tool = "pen"
        else if (e.key === Qt.Key_A) tool = "arrow"
        else if (e.key === Qt.Key_R) tool = "rect"
        else if (e.key === Qt.Key_T) tool = "text"
        else if (e.key === Qt.Key_B) tool = "blur"
        else return
        e.accepted = true
    }

    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.6 }

    Item {
        id: sheet
        objectName: "snip-sheet"
        width: root.crop.width
        height: root.crop.height
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -30
        scale: Math.min(1, (root.width - 60) / width, (root.height - 150) / height)
        clip: true

        Image {
            id: shot
            source: root.source
            x: -root.crop.x
            y: -root.crop.y
            width: implicitWidth / root.sourceScale
            height: implicitHeight / root.sourceScale
        }

        Repeater {
            model: root.shapes
            Loader {
                required property var modelData
                required property int index
                sourceComponent: modelData.type === "blur" ? blurShape : modelData.type === "text" ? textShape : null
                onLoaded: { item.shape = modelData; item.objectName = modelData.type + "-" + index }
            }
        }

        Canvas {
            id: ink
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                for (const s of root.shapes.concat(root.draft ? [root.draft] : [])) {
                    ctx.strokeStyle = s.colour
                    ctx.fillStyle = s.colour
                    ctx.lineWidth = 4
                    if (s.type === "pen" && s.points.length > 1) {
                        ctx.beginPath()
                        ctx.moveTo(s.points[0].x, s.points[0].y)
                        for (const p of s.points.slice(1)) ctx.lineTo(p.x, p.y)
                        ctx.stroke()
                    } else if (s.type === "rect") {
                        ctx.strokeRect(s.x, s.y, s.width, s.height)
                    } else if (s.type === "arrow") {
                        ctx.beginPath()
                        ctx.moveTo(s.x1, s.y1)
                        ctx.lineTo(s.x2, s.y2)
                        ctx.stroke()
                        const h = Snip.arrowHead(s.x1, s.y1, s.x2, s.y2, 18)
                        ctx.beginPath()
                        ctx.moveTo(s.x2, s.y2)
                        ctx.lineTo(h[0].x, h[0].y)
                        ctx.lineTo(h[1].x, h[1].y)
                        ctx.closePath()
                        ctx.fill()
                    } else if (s.type === "blur" && s === root.draft) {
                        ctx.lineWidth = 1
                        ctx.strokeRect(s.x, s.y, s.width, s.height)
                    }
                }
            }
            Connections {
                target: root
                function onShapesChanged() { ink.requestPaint() }
                function onDraftChanged() { ink.requestPaint() }
            }
        }

        TextInput {
            id: editor
            objectName: "text-editor"
            visible: root.editing
            color: root.colour
            font.family: Theme.body
            font.pixelSize: 22
            font.weight: Font.Medium
            Keys.onReturnPressed: commit()
            Keys.onEnterPressed: commit()
            Keys.onEscapePressed: { text = ""; done() }
            function commit() {
                if (text !== "")
                    root.add({ type: "text", x: x, y: y, text: text, colour: root.colour.toString() })
                text = ""
                done()
            }
            // Give focus back to the annotator, or tool keys would type here.
            function done() {
                root.editing = false
                focus = false
                root.forceActiveFocus()
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: !root.editing
            cursorShape: Qt.CrossCursor
            property point start
            onPressed: e => {
                start = Qt.point(e.x, e.y)
                const c = root.colour.toString()
                if (root.tool === "text") {
                    editor.x = e.x
                    editor.y = e.y - 14
                    root.editing = true
                    editor.forceActiveFocus()
                } else if (root.tool === "pen") {
                    root.draft = { type: "pen", colour: c, points: [{ x: e.x, y: e.y }] }
                }
            }
            onPositionChanged: e => {
                if (root.tool === "text") return
                const c = root.colour.toString()
                if (root.tool === "pen" && root.draft)
                    root.draft = Object.assign({}, root.draft, { points: root.draft.points.concat([{ x: e.x, y: e.y }]) })
                else if (root.tool === "arrow")
                    root.draft = { type: "arrow", colour: c, x1: start.x, y1: start.y, x2: e.x, y2: e.y }
                else
                    root.draft = Object.assign({ type: root.tool, colour: c }, Snip.rectFrom(start, Qt.point(e.x, e.y)))
            }
            onReleased: {
                const d = root.draft
                root.draft = null
                if (!d) return
                const big = d.type === "pen" ? d.points.length > 1
                    : d.type === "arrow" ? Math.hypot(d.x2 - d.x1, d.y2 - d.y1) > 4
                    : d.width > 2 && d.height > 2
                if (big) root.add(d)
            }
        }
    }

    Component {
        id: blurShape
        Item {
            property var shape
            x: shape ? shape.x : 0
            y: shape ? shape.y : 0
            width: shape ? shape.width : 0
            height: shape ? shape.height : 0
            clip: true
            Image {
                // Drawn tiny and stretched back: pixelated, no shader needed.
                source: root.source
                x: -root.crop.x - parent.x
                y: -root.crop.y - parent.y
                width: shot.width
                height: shot.height
                sourceSize: Qt.size(Math.max(1, shot.implicitWidth / 40), Math.max(1, shot.implicitHeight / 40))
                smooth: false
            }
        }
    }

    Component {
        id: textShape
        Text {
            property var shape
            x: shape ? shape.x : 0
            y: shape ? shape.y : 0
            text: shape ? shape.text : ""
            color: shape ? shape.colour : "white"
            font.family: Theme.body
            font.pixelSize: 22
            font.weight: Font.Medium
        }
    }

    // Toolbar
    Rectangle {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 28 }
        width: bar.implicitWidth + 24
        height: 56
        radius: height / 2
        color: Theme.surface

        Row {
            id: bar
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: [{ t: "pen", label: "pen" }, { t: "arrow", label: "arrow" }, { t: "rect", label: "box" },
                        { t: "text", label: "text" }, { t: "blur", label: "blur" }]
                Pill {
                    required property var modelData
                    objectName: "tool-" + modelData.t
                    text: modelData.label
                    active: root.tool === modelData.t
                    onClicked: root.tool = modelData.t
                }
            }
            Item { width: 8; height: 1 }
            Repeater {
                model: root.colours
                Rectangle {
                    required property var modelData
                    objectName: "colour-" + modelData.name
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22; height: 22; radius: 11
                    color: modelData.value
                    border.width: Qt.colorEqual(root.colour, modelData.value) ? 3 : 1
                    border.color: Theme.textSecondary
                    TapHandler { onTapped: root.colour = parent.modelData.value }
                }
            }
            Item { width: 8; height: 1 }
            Pill { text: "undo"; onClicked: root.undo() }
            Pill { text: "save"; onClicked: root.saveRequested() }
            Pill { text: "copy"; active: true; onClicked: root.copyRequested() }
        }
    }
}
