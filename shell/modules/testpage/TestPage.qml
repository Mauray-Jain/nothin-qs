import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../../components"
import "../../services"

// Development page: the config round trip (1.1) and the design kit (1.2).
//   nothin ipc testpage toggle    show or hide it
//   nothin ipc testpage name      print general.name as the shell sees it
//   nothin ipc testpage desktop   print outputs, workspaces and focus as the shell sees them
Scope {
    id: root

    property bool shown: false

    IpcHandler {
        target: "testpage"
        function toggle(): void { root.shown = !root.shown }
        function name(): string { return Config.values.general?.name ?? "" }
        function desktop(): string {
            const outs = Compositor.outputs.map(o => {
                const ws = Compositor.workspacesOn(o.name)
                    .map(w => w.index + (w.focused ? "*" : w.active ? "·" : "") + (w.urgent ? "!" : ""))
                return o.name + (o.name === Compositor.focusedOutput ? "*" : "") + " [" + ws.join(" ") + "]"
            })
            const w = Compositor.focusedWindow
            return outs.join(" | ") + " | focus: " + (w ? w.app_id + " \"" + w.title + "\"" : "none")
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.shown
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 640
            implicitHeight: 560
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

                    Row {
                        spacing: 24

                        DotText { text: "16:55"; dotSize: 7; gap: 3; anchors.verticalCenter: parent.verticalCenter }
                        DotRing { value: 0.7; diameter: 88; anchors.verticalCenter: parent.verticalCenter }

                        Item {
                            width: 140
                            height: 140

                            Rectangle {
                                id: art
                                anchors.fill: parent
                                visible: false
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "white" }
                                    GradientStop { position: 1; color: "black" }
                                }
                            }
                            Halftone {
                                anchors.fill: parent
                                dotSize: 10
                                source: ShaderEffectSource { sourceItem: art; hideSource: true }
                            }
                        }
                    }

                    Row {
                        spacing: 12
                        DotSpark { values: [3, 5, 4, 7, 6, 9, 5, 8, 10, 7]; anchors.verticalCenter: parent.verticalCenter }
                        Toggle { anchors.verticalCenter: parent.verticalCenter }
                        Segmented { model: ["GRID", "FREE"] }
                        Pill { text: "caffeine"; anchors.verticalCenter: parent.verticalCenter; onClicked: active = !active }
                        Knob { diameter: 48; value: 0.5 }
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
