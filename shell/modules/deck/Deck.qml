import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core"
import "../../services"

// The settings deck window on the focused monitor. Opens from the rail's
// tune button, SETTINGS in the power menu, or `nothin ipc deck toggle`.
// Escape closes it.
Scope {
    IpcHandler {
        target: "deck"
        function toggle(): void { DeckState.toggle() }
    }

    PanelWindow {
        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: DeckState.open
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "nothin-deck"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 900
        implicitHeight: 640
        color: "transparent"

        DeckView {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: DeckState.open = false
        }
    }
}
