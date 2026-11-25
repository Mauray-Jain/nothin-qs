import QtQuick
import Quickshell
import "../../core"
import "../../components"
import "../../services"

// Lock, suspend (as idle.suspend_mode says), log out, reboot, shut down.
// Reboot and shut down need a second press.
PopupWindow {
    id: root

    property Item target
    property var rail

    function run(cmd) {
        visible = false
        Quickshell.execDetached(cmd)
    }

    anchor.item: target
    anchor.edges: rail ? rail.tipEdge : Edges.Right
    anchor.gravity: rail ? rail.tipEdge : Edges.Right
    grabFocus: true
    implicitWidth: column.implicitWidth + 24
    implicitHeight: column.implicitHeight + 24
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surface

        Column {
            id: column
            anchors.centerIn: parent
            spacing: 8

            Pill { width: 150; text: "lock"; onClicked: { root.visible = false; LockState.lock() } }
            Pill {
                width: 150
                text: "suspend"
                onClicked: root.run(["systemctl", Config.values.idle?.suspend_mode ?? "suspend"])
            }
            Pill { width: 150; text: "log out"; onClicked: { root.visible = false; Compositor.quit() } }
            ConfirmPill { width: 150; text: "reboot"; confirmText: "reboot? again"; onConfirmed: root.run(["systemctl", "reboot"]) }
            ConfirmPill { width: 150; text: "shut down"; confirmText: "shut down? again"; onConfirmed: root.run(["systemctl", "poweroff"]) }
        }
    }

    Item {
        focus: true
        Keys.onEscapePressed: root.visible = false
    }
}
