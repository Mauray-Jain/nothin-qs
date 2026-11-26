import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core"
import "../../services"
import "Apply.js" as Apply
import "Look.js" as Look

// The picker window on the focused monitor (`nothin ipc picker toggle`, or
// LOOK → CHOOSE WALLPAPER). Applying saves to config.toml and closes.
Scope {
    IpcHandler {
        target: "picker"
        function toggle(): void { Wallpapers.togglePicker() }
    }

    PanelWindow {
        id: win

        readonly property string monitor: Compositor.focusedOutput
        readonly property var look: Look.forOutput(Config.values.wallpaper, monitor)

        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: Wallpapers.pickerOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "nothin-picker"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: Math.min(1100, (screen ? screen.width : 1100) - 80)
        implicitHeight: 700
        color: "transparent"

        onVisibleChanged: if (visible) view.reset(look.path)

        WallpaperPickerView {
            id: view
            anchors.fill: parent
            focus: true
            files: Wallpapers.files
            startEffect: win.look.effect
            startDotSize: win.look.dotSize
            startLight: Math.round(win.look.light * 100)
            onFilesChanged: reset(win.look.path)
            onApplied: choice => {
                for (const [path, value] of Apply.changes(choice, Wallpapers.dir, win.monitor))
                    Config.set(path, value)
                Wallpapers.pickerOpen = false
            }
            onCloseRequested: Wallpapers.pickerOpen = false
        }
    }
}
