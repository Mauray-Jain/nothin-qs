import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

// Development page for checking the config round trip and, later, the design kit.
//   nothin ipc testpage toggle    show or hide it
//   nothin ipc testpage name      print general.name as the shell sees it
Scope {
    id: root

    property bool shown: false

    IpcHandler {
        target: "testpage"
        function toggle(): void { root.shown = !root.shown }
        function name(): string { return Config.values.general?.name ?? "" }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.shown
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 520
            implicitHeight: 200
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.surface

                Column {
                    anchors { fill: parent; margins: 28 }
                    spacing: 18

                    Text {
                        text: "HELLO, " + (Config.values.general?.name || "STRANGER").toUpperCase()
                        color: Theme.text
                        font.family: Theme.mono
                        font.pixelSize: 22
                        font.letterSpacing: Theme.labelSpacing
                    }

                    Text {
                        text: "GENERAL.NAME · TYPE AND PRESS ENTER TO SAVE"
                        color: Theme.label
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.letterSpacing: Theme.labelSpacing
                    }

                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 22
                        color: Theme.surfaceHigh

                        TextInput {
                            anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                            verticalAlignment: TextInput.AlignVCenter
                            text: Config.values.general?.name ?? ""
                            color: Theme.text
                            selectionColor: Theme.accent
                            font.family: Theme.body
                            font.pixelSize: 16
                            focus: true
                            onAccepted: Config.set("general.name", text)
                        }
                    }
                }
            }
        }
    }
}
