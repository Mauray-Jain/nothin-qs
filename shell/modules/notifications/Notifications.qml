import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../../core"
import "../../services"
import "Timeout.js" as Timeout

// The notification server (only when NOTHIN_EXCLUSIVE=1: one per session,
// and DMS has it under --dev), popups on the focused monitor, and the center.
//   nothin ipc notifications toggle | clear
Scope {
    id: root

    property var popups: []

    LazyLoader {
        active: Quickshell.env("NOTHIN_EXCLUSIVE") === "1"

        NotificationServer {
            keepOnReload: true
            bodySupported: true
            actionsSupported: true
            imageSupported: true

            onNotification: n => {
                n.tracked = true
                n.closed.connect(() => {
                    Notifs.remove(n)
                    root.popups = root.popups.filter(p => p !== n)
                })
                Notifs.add(n)
            }
        }
    }

    Connections {
        target: Notifs
        function onArrived(n) {
            if (Notifs.wantsPopup())
                root.popups = [n].concat(root.popups).slice(0, 4)
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { Notifs.toggleCenter() }
        function clear(): void { Notifs.clear() }
    }

    // Popups, newest on top, top-right of the focused monitor.
    PanelWindow {
        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: root.popups.length > 0
        anchors { top: true; right: true }
        margins { top: 16; right: 16 }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 380
        implicitHeight: popupColumn.implicitHeight
        color: "transparent"

        Column {
            id: popupColumn
            width: parent.width
            spacing: 8

            Repeater {
                model: root.popups

                NotificationCard {
                    id: card
                    required property var modelData
                    width: parent.width
                    notification: modelData

                    Timer {
                        readonly property int ms: Timeout.forPopup(card.modelData.expireTimeout, card.critical)
                        running: ms > 0
                        interval: ms
                        onTriggered: root.popups = root.popups.filter(p => p !== card.modelData)
                    }
                }
            }
        }
    }

    // The center: every notification since start, on the right of the
    // focused monitor.
    PanelWindow {
        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: Notifs.centerOpen
        anchors { top: true; right: true; bottom: true }
        margins { top: 16; right: 16; bottom: 16 }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 400
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.surface

            Row {
                id: header
                x: 20; y: 18
                width: parent.width - 40
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - clear.width - close.width - 16
                    text: "NOTIFICATIONS · " + Notifs.items.length
                    color: Theme.label
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.letterSpacing: Theme.labelSpacing
                }
                Pill { id: clear; text: "clear"; onClicked: Notifs.clear() }
                Pill { id: close; text: "close"; onClicked: Notifs.toggleCenter() }
            }

            ListView {
                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: 16 }
                clip: true
                spacing: 8
                model: Notifs.items

                delegate: NotificationCard {
                    required property var modelData
                    width: ListView.view.width
                    notification: modelData
                }
            }

            Text {
                anchors.centerIn: parent
                visible: Notifs.items.length === 0
                text: "NOTHING NEW"
                color: Theme.label
                font.family: Theme.mono
                font.pixelSize: 12
                font.letterSpacing: Theme.labelSpacing
            }
        }
    }
}
