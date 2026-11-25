import QtQuick
import "../../core"
import "../../services"

// One dot per workspace on `output`: focused in accent, shown-on-this-output
// white, others grey, urgent ones blinking. Click or tap to switch.
Grid {
    id: root

    property string output
    property bool vertical: false
    readonly property int count: repeater.count

    function dotAt(i) {
        return repeater.itemAt(i)
    }

    columns: vertical ? 1 : Math.max(1, count)
    spacing: 2

    Repeater {
        id: repeater
        model: Compositor.workspacesOn(root.output)

        Item {
            required property var modelData
            readonly property color color: modelData.focused ? Theme.accent : modelData.active ? Theme.text : Theme.label
            readonly property bool blinking: modelData.urgent && !modelData.focused

            width: 20
            height: 20

            Rectangle {
                anchors.centerIn: parent
                width: parent.modelData.focused ? 10 : 8
                height: width
                radius: width / 2
                color: parent.color
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                SequentialAnimation on opacity {
                    running: parent.parent.blinking
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { to: 0.2; duration: 500 }
                    NumberAnimation { to: 1; duration: 500 }
                }
            }

            TapHandler { onTapped: Compositor.focusWorkspace(parent.modelData.id) }
        }
    }
}
