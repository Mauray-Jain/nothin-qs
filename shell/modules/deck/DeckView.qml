import QtQuick
import "../../core"
import "../../components"

// The settings deck: HOME, LOOK, IDLE, DISPLAY, WINDOWS, INPUT, SHELL, POWER. Every change is saved to
// config.toml through Config.set (comments are kept) and applies live.
Rectangle {
    id: root

    property string page: "home"
    readonly property var pages: ["home", "look", "idle", "display", "windows", "input", "shell", "power"]

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
            height: children.reduce((h, c) => c.visible ? Math.max(h, c.height) : h, 0)

            HomePage { width: parent.width; visible: root.page === "home" }
            LookPage { width: parent.width; visible: root.page === "look" }
            IdlePage { width: parent.width; visible: root.page === "idle" }
            DisplayPage { width: parent.width; visible: root.page === "display" }
            WindowsPage { width: parent.width; visible: root.page === "windows" }
            InputPage { width: parent.width; visible: root.page === "input" }
            ShellPage { width: parent.width; visible: root.page === "shell" }
            Loader {
                // Needs Quickshell's UPower, so only loaded when opened.
                width: parent.width
                visible: root.page === "power"
                active: visible
                source: "PowerPage.qml"
                onLoaded: item.deck = root
            }
        }
    }
}
