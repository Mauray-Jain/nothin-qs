import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core"
import "../../components"
import "../../services"
import "Cliphist.js" as Cliphist

// Clipboard history from cliphist; choosing an entry copies it again.
// Needs cliphist and wl-clipboard, with `wl-paste --watch cliphist store`
// running.   nothin ipc clipboard toggle
Scope {
    id: root

    property bool open: false
    property var entries: []

    onOpenChanged: if (open) history.running = true

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.open = !root.open }
    }

    Process {
        id: history
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: root.entries = Cliphist.parse(text) }
    }

    PanelWindow {
        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: root.open
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "nothin-clipboard"
        exclusionMode: ExclusionMode.Ignore
        anchors.top: true
        margins.top: 160
        implicitWidth: 640
        implicitHeight: 500
        color: "transparent"

        onVisibleChanged: if (visible) picker.reset()

        Picker {
            id: picker

            readonly property var shown: Cliphist.filter(root.entries, query)

            anchors.fill: parent
            focus: true
            placeholder: "Clipboard history"
            items: shown.slice(0, 100).map(e => ({ icon: e.image ? "image" : "content_paste", title: e.text }))
            onChosen: i => {
                // The id goes in as an argument, never into the shell text.
                Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", shown[i].id])
                root.open = false
            }
            onCloseRequested: root.open = false
        }
    }
}
