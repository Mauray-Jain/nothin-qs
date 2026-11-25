import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import "../../core"
import "../../components"
import "../../services"

// The polkit agent: when an app needs admin rights, ask for the password on
// the focused monitor. Only one agent can run per session, so this loads only
// when nothin owns the session services (NOTHIN_EXCLUSIVE).
Scope {
    id: root

    PolkitAgent { id: agent }

    PanelWindow {
        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: agent.isActive && agent.flow !== null
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "nothin-polkit"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 460
        implicitHeight: column.implicitHeight + 48
        color: "transparent"

        onVisibleChanged: if (visible) input.forceActiveFocus()

        Card {
            anchors.fill: parent

            Column {
                id: column
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
                spacing: 14

                Text {
                    text: "AUTHENTICATION"
                    color: Theme.label
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.letterSpacing: Theme.labelSpacing
                }
                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: agent.flow ? agent.flow.message : ""
                    color: Theme.text
                    font.family: Theme.body
                    font.pixelSize: 16
                }
                Text {
                    text: agent.flow && agent.flow.selectedIdentity ? "AS " + agent.flow.selectedIdentity.displayName.toUpperCase() : ""
                    color: Theme.textSecondary
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.letterSpacing: Theme.labelSpacing
                }
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: height / 2
                    color: Theme.surfaceHigh

                    TextInput {
                        id: input
                        anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: agent.flow && agent.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        color: Theme.text
                        font.family: Theme.mono
                        font.pixelSize: 15
                        Keys.onReturnPressed: root.send()
                        Keys.onEnterPressed: root.send()
                        Keys.onEscapePressed: agent.flow.cancelAuthenticationRequest()
                    }
                }
                Text {
                    visible: text !== ""
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: agent.flow ? agent.flow.supplementaryMessage.toUpperCase() : ""
                    color: agent.flow && agent.flow.supplementaryIsError ? Theme.accent : Theme.textSecondary
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.letterSpacing: Theme.labelSpacing
                }
                Row {
                    spacing: 8
                    Pill { text: "authenticate"; active: true; onClicked: root.send() }
                    Pill { text: "cancel"; onClicked: agent.flow.cancelAuthenticationRequest() }
                }
            }
        }
    }

    function send() {
        if (!agent.flow || input.text === "")
            return
        agent.flow.submit(input.text)
        input.text = ""
    }
}
