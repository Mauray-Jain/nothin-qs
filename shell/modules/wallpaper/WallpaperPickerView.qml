import QtQuick
import QtQuick.Effects
import "../../core"
import "../../components"

// The wallpaper picker: a large preview with the chosen effect, a strip of
// thumbnails, and effect / dot size / light controls that only preview until
// APPLY (or Enter). Left/Right move, Escape closes.
FocusScope {
    id: root

    property var files: []
    property int index: 0
    property string startEffect: "dots"
    property int startDotSize: 17
    property int startLight: 50

    property string effect: startEffect
    property int dotSize: startDotSize
    property int light: startLight
    property bool thisMonitor: false
    readonly property string current: files[index] ?? ""

    signal applied(var choice)
    signal closeRequested()

    function reset(currentPath) {
        index = Math.max(0, files.indexOf(currentPath))
        effect = startEffect
        dotSize = startDotSize
        light = startLight
        thisMonitor = false
    }

    function apply() {
        if (current === "")
            return
        applied({ path: current, effect: effect, dotSize: dotSize, light: light, thisMonitor: thisMonitor })
    }

    function move(by) {
        index = Math.max(0, Math.min(files.length - 1, index + by))
        strip.positionViewAtIndex(index, ListView.Contain)
    }

    Keys.onLeftPressed: move(-1)
    Keys.onRightPressed: move(1)
    Keys.onReturnPressed: apply()
    Keys.onEnterPressed: apply()
    Keys.onEscapePressed: closeRequested()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surface
    }

    // Preview
    Rectangle {
        id: preview
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
        height: parent.height * 0.55
        radius: Theme.radius - 6
        color: Theme.background
        clip: true

        Image {
            id: big
            anchors.fill: parent
            source: root.current ? "file://" + root.current : ""
            sourceSize: Qt.size(preview.width, preview.height)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            layer.enabled: root.effect === "mono"
            layer.effect: MultiEffect { saturation: -1 }
        }
        ShaderEffectSource {
            id: bigTexture
            sourceItem: big
            hideSource: root.effect === "dots" || root.effect === "color"
        }
        Halftone {
            anchors.fill: parent
            visible: (root.effect === "dots" || root.effect === "color") && big.status === Image.Ready
            source: bigTexture
            dotSize: root.dotSize * preview.width / 1920 * 1.5 // roughly as it will look on a screen
            light: root.light / 100
            imageColours: root.effect === "color"
        }

        Text {
            objectName: "picker-empty"
            anchors.centerIn: parent
            visible: root.files.length === 0
            text: "NO IMAGES IN THE WALLPAPER FOLDER"
            color: Theme.label
            font.family: Theme.mono
            font.pixelSize: 12
            font.letterSpacing: Theme.labelSpacing
        }
    }

    // Thumbnails
    ListView {
        id: strip
        anchors { left: parent.left; right: parent.right; top: preview.bottom; topMargin: 14; leftMargin: 20; rightMargin: 20 }
        height: 92
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        model: root.files
        currentIndex: root.index

        delegate: Rectangle {
            id: thumb
            required property string modelData
            required property int index
            objectName: "thumb-" + index
            width: 140
            height: 88
            radius: 10
            color: Theme.surfaceHigh
            border.width: index === root.index ? 2 : 0
            border.color: Theme.accent
            clip: true

            Image {
                anchors { fill: parent; margins: 3 }
                source: "file://" + thumb.modelData
                sourceSize: Qt.size(280, 176)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            TapHandler { onTapped: root.index = thumb.index }
        }
    }

    // Controls
    Row {
        anchors { left: parent.left; leftMargin: 20; bottom: parent.bottom; bottomMargin: 20 }
        spacing: 18

        Segmented {
            objectName: "picker-effect"
            anchors.verticalCenter: parent.verticalCenter
            model: ["dots", "color", "mono", "none"]
            currentIndex: ["dots", "color", "mono", "none"].indexOf(root.effect)
            onActivated: i => root.effect = ["dots", "color", "mono", "none"][i]
        }
        Column {
            spacing: 2
            Knob { diameter: 44; value: (root.dotSize - 4) / 60; onMoved: root.dotSize = Math.round(4 + value * 60) }
            Text { text: "DOTS " + root.dotSize; color: Theme.label; font.family: Theme.mono; font.pixelSize: 9 }
        }
        Column {
            spacing: 2
            Knob { diameter: 44; value: root.light / 100; onMoved: root.light = Math.round(value * 100) }
            Text { text: "LIGHT " + root.light; color: Theme.label; font.family: Theme.mono; font.pixelSize: 9 }
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 20; bottom: parent.bottom; bottomMargin: 26 }
        spacing: 10

        Pill {
            objectName: "picker-this-monitor"
            text: "this monitor only"
            active: root.thisMonitor
            onClicked: root.thisMonitor = !root.thisMonitor
        }
        Pill {
            objectName: "picker-apply"
            text: "apply"
            color: Theme.accent
            onClicked: root.apply()
        }
    }
}
