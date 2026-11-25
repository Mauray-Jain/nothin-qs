import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core"
import "../../components"
import "../../services"
import "Results.js" as Results

// The launcher, on the focused monitor: apps (by frecency), open windows, a
// calculator and web search; ":" emoji, "/" files, "?" web.
//   nothin ipc launcher toggle
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
        } else if (r.kind === "emoji") {
            Quickshell.execDetached(["wl-copy", r.emoji])
        } else if (r.kind === "file") {
            Quickshell.execDetached(["xdg-open", r.path])
        } else if (r.kind === "web") {
            Quickshell.execDetached(["xdg-open", r.url])
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
            readonly property var results: Results.build(query, {
                apps: apps, scores: Usage.scores, windows: Compositor.windows, files: FileSearch.results,
                searchUrl: Config.values.launcher?.search_url ?? "https://duckduckgo.com/?q=%s",
                home: Quickshell.env("HOME") ?? ""
            })

            onQueryChanged: FileSearch.search(Results.fileQuery(query))

            anchors.fill: parent
            focus: true
            placeholder: "Apps, 2+2   :emoji   /files   ?web"
            items: results.map(r => r.kind === "app"
                ? Object.assign({}, r, { iconSource: Quickshell.iconPath(r.app.icon, true) || "", icon: "apps" })
                : r)
            onChosen: i => root.activate(results[i])
            onCloseRequested: root.open = false
        }
    }
}
