import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../core"
import "../../services"

// The focused window's app icon (greyscale), with its title beside it on a
// horizontal rail or on hover on a vertical one. Shown on the focused output.
Item {
    id: root

    property var rail
    property string output
    readonly property var win: Compositor.focusedOutput === output ? Compositor.focusedWindow : null

    visible: win !== null
    implicitWidth: rail && rail.vertical ? 36 : 36 + (title.visible ? title.implicitWidth + 4 : 0)
    implicitHeight: 36

    IconImage {
        id: icon
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 20
        source: root.win ? Quickshell.iconPath(root.win.app_id, "application-x-executable") : ""
        layer.enabled: true
        layer.effect: MultiEffect { saturation: -1 }
    }

    Text {
        id: title
        visible: root.rail && !root.rail.vertical
        anchors { left: icon.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
        width: Math.min(implicitWidth, 260)
        elide: Text.ElideRight
        text: root.win ? root.win.title : ""
        color: Theme.text
        font.family: Theme.body
        font.pixelSize: 13
    }

    HoverHandler { id: hover }
    Tooltip {
        target: root
        rail: root.rail
        text: root.win ? root.win.title : ""
        shown: hover.hovered && root.rail && root.rail.vertical
    }
}
