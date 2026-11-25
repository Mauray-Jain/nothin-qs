import QtQuick
import "../../core"
import "../../components"

// The settings deck: HOME, LOOK and IDLE. Every change is saved to
// config.toml through Config.set (comments are kept) and applies live.
Rectangle {
    id: root

    property string page: "home"
    readonly property var pages: ["home", "look", "idle"]

    radius: Theme.radius
    color: Theme.surface

    Column {
        id: nav
        x: 24; y: 24
        spacing: 8

        Text {
            text: "SETTINGS"
            color: Theme.label
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: Theme.labelSpacing
            bottomPadding: 8
        }
        Repeater {
            model: root.pages
            Pill {
                required property string modelData
                objectName: "nav-" + modelData
                width: 110
                text: modelData
                active: root.page === modelData
                onClicked: root.page = modelData
            }
        }
    }

    Flickable {
        anchors { left: nav.right; leftMargin: 32; right: parent.right; rightMargin: 24; top: parent.top; topMargin: 24; bottom: parent.bottom; bottomMargin: 24 }
        contentHeight: current.height
        clip: true

        Item {
            id: current
            width: parent.width
            height: home.visible ? home.height : look.visible ? look.height : idle.height

            HomePage { id: home; width: parent.width; visible: root.page === "home" }
            LookPage { id: look; width: parent.width; visible: root.page === "look" }
            IdlePage { id: idle; width: parent.width; visible: root.page === "idle" }
        }
    }
}
