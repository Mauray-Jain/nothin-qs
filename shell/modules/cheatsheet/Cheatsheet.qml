import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core"
import "../../services"

// The cheatsheet overlay on the focused monitor (`nothin ipc cheatsheet
// toggle`, or the SHELL page). Escape closes it.
Scope {
    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { CheatsheetState.toggle() }
    }

    PanelWindow {
        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: CheatsheetState.open
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "nothin-cheatsheet"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: Math.min(1200, (screen ? screen.width : 1200) - 80)
        implicitHeight: Math.min(760, (screen ? screen.height : 760) - 80)
        color: "transparent"

        CheatsheetView {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: CheatsheetState.open = false
        }
    }
}
