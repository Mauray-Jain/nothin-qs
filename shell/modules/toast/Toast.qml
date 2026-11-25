import QtQuick
import Quickshell
import "../../core"
import "../../services"

// Shows daemon errors (a bad config.toml, a refused save) for a few seconds.
PanelWindow {
    id: toast

    property string message: ""

    screen: Compositor.focusedScreen(Quickshell.screens)
    visible: message !== ""
    anchors { top: true; right: true }
    margins { top: 16; right: 16 }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 440
    implicitHeight: body.implicitHeight + 32
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surfaceHigh

        Rectangle {
            id: dot
            x: 20; y: 22
            width: 8; height: 8; radius: 4
            color: Theme.accent
        }

        Text {
            id: body
            anchors { left: dot.right; leftMargin: 12; right: parent.right; rightMargin: 20; top: parent.top; topMargin: 16 }
            text: toast.message
            wrapMode: Text.Wrap
            color: Theme.text
            font.family: Theme.mono
            font.pixelSize: 13
        }
    }

    Timer { id: hide; interval: 6000; onTriggered: toast.message = "" }

    Connections {
        target: Config
        function onFailed(message) {
            toast.message = message
            hide.restart()
        }
    }
}
