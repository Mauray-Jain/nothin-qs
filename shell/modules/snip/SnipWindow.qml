import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core"
import "../../services"
import "Snip.js" as Snip

// Screenshots: `nothin ipc snip region` freezes the focused monitor (grim)
// and lets you drag an area; `nothin ipc snip screen` takes all of it. Then
// the annotator: Enter copies, Ctrl+S also saves to snip.dir.
Scope {
    id: root

    property string mode: ""        // "" | "region" | "annotate"
    property bool wantRegion: true
    property string output: ""
    property url shot
    property var crop: ({ x: 0, y: 0, width: 1, height: 1 })
    readonly property string dir: (Quickshell.env("XDG_RUNTIME_DIR") ?? "/tmp") + "/nothin"
    readonly property real outputScale: (Compositor.outputs.find(o => o.name === output) ?? { scale: 1 }).scale
    property string shotPath: ""

    function start(region) {
        if (mode !== "" || capture.running)
            return
        wantRegion = region
        output = Compositor.focusedOutput
        shotPath = dir + "/snip-" + Date.now() + ".png"
        capture.command = ["sh", "-c", "mkdir -p \"$1\" && rm -f \"$1\"/snip-*.png && grim -o \"$2\" \"$3\"",
                           "sh", dir, output, shotPath]
        capture.running = true
    }

    function finish(save) {
        const out = dir + "/snip-out.png"
        annotator.exportImage(out, ok => {
            if (!ok) {
                Config.failed("couldn't write the screenshot")
            } else if (save) {
                const folder = Config.values.snip?.path ?? ""
                Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && cp \"$2\" \"$1/$3\" && wl-copy -t image/png < \"$2\"",
                                         "sh", folder, out, Snip.fileName(new Date())])
            } else {
                Quickshell.execDetached(["sh", "-c", "wl-copy -t image/png < \"$1\"", "sh", out])
            }
            root.mode = ""
        })
    }

    IpcHandler {
        target: "snip"
        function region(): void { root.start(true) }
        function screen(): void { root.start(false) }
    }

    Process {
        id: capture
        onExited: code => {
            if (code !== 0) {
                Config.failed("screenshot failed: is grim installed?")
                return
            }
            root.shot = "file://" + root.shotPath
            root.crop = { x: 0, y: 0, width: win.width, height: win.height }
            root.mode = root.wantRegion ? "region" : "annotate"
        }
    }

    PanelWindow {
        id: win

        screen: Quickshell.screens.find(s => s.name === root.output) ?? Compositor.focusedScreen(Quickshell.screens)
        visible: root.mode !== ""
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "nothin-snip"
        exclusionMode: ExclusionMode.Ignore
        anchors { left: true; right: true; top: true; bottom: true }
        color: "black"

        RegionView {
            anchors.fill: parent
            visible: root.mode === "region"
            focus: visible
            source: root.shot
            onChosen: r => { root.crop = r; root.mode = "annotate"; annotator.clear(); annotator.forceActiveFocus() }
            onCancelled: root.mode = ""
        }

        AnnotatorView {
            id: annotator
            anchors.fill: parent
            visible: root.mode === "annotate"
            focus: visible
            source: root.shot
            crop: root.crop
            sourceScale: root.outputScale
            onCopyRequested: root.finish(false)
            onSaveRequested: root.finish(true)
            onCancelled: root.mode = ""
        }
    }
}
