import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../core"

// Tray icons in greyscale. Left click activates (or opens the menu for
// menu-only items), right click opens the menu, scroll is passed on.
Grid {
    id: root

    property var rail

    columns: rail && rail.vertical ? 1 : Math.max(1, repeater.count)
    spacing: 0

    Repeater {
        id: repeater
        model: SystemTray.items

        Item {
            id: slot
            required property SystemTrayItem modelData
            implicitWidth: 36
            implicitHeight: 36

            // Open the item's menu just off the rail, beside this icon.
            function openMenu() {
                const p = slot.mapToItem(null, 0, 0)
                const pos = root.rail.position
                slot.modelData.display(root.rail,
                    pos === "left" ? p.x + width : p.x,
                    pos === "top" ? p.y + height : p.y)
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: slot.modelData.icon
                layer.enabled: true
                layer.effect: MultiEffect { saturation: -1 }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                hoverEnabled: true
                onClicked: e => {
                    if (e.button === Qt.RightButton || (slot.modelData.onlyMenu && slot.modelData.hasMenu))
                        slot.openMenu()
                    else if (e.button === Qt.MiddleButton)
                        slot.modelData.secondaryActivate()
                    else
                        slot.modelData.activate()
                }
                onWheel: e => slot.modelData.scroll(e.angleDelta.y, false)
            }

            Tooltip {
                target: slot
                rail: root.rail
                text: slot.modelData.tooltipTitle || slot.modelData.title
                shown: mouse.containsMouse
            }
        }
    }
}
