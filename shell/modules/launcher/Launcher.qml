import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core"
import "../../components"
import "../../services"
import "Results.js" as Results

// The launcher: apps (by frecency), open windows and a calculator in one
// search, on the focused monitor.   nothin ipc launcher toggle
Scope {
    id: root

    property bool open: false

    function activate(r) {
        open = false
        if (r.kind === "app") {
            r.app.execute()
            Usage.launched(r.app.id)
        } else if (r.kind === "window") {
            Compositor.focusWindow(r.win.id)
        } else if (r.kind === "calc") {
            Quickshell.execDetached(["wl-copy", r.title])
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open = !root.open }
    }

    PanelWindow {
        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: root.open
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "nothin-launcher"
        exclusionMode: ExclusionMode.Ignore
        anchors.top: true
        margins.top: 160
        implicitWidth: 640
        implicitHeight: 500
        color: "transparent"

        onVisibleChanged: if (visible) picker.reset()

        Picker {
            id: picker

            readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
            readonly property var results: Results.build(query, apps, Usage.scores, Compositor.windows)

            anchors.fill: parent
            focus: true
            placeholder: "Apps, windows, 2+2"
            items: results.map(r => r.kind === "app"
                ? Object.assign({}, r, { iconSource: Quickshell.iconPath(r.app.icon, true) || "", icon: "apps" })
                : r)
            onChosen: i => root.activate(results[i])
            onCloseRequested: root.open = false
        }
    }
}
