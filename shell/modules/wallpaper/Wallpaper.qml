import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../components"
import "Look.js" as Look

// The wallpaper on every monitor, on the background layer, drawn with the
// [wallpaper] effect (or that monitor's override). Changes apply live.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property var look: Look.forOutput(Config.values.wallpaper, modelData.name)
            readonly property bool halftoned: look.effect === "dots" || look.effect === "color"

            screen: modelData
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "nothin-wallpaper"
            exclusionMode: ExclusionMode.Ignore
            anchors { left: true; right: true; top: true; bottom: true }
            color: Theme.background

            Image {
                id: image
                anchors.fill: parent
                source: win.look.path ? "file://" + win.look.path : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(win.width, win.height)
                asynchronous: true
                layer.enabled: win.look.effect === "mono"
                layer.effect: MultiEffect { saturation: -1 }
            }

            // The halftone samples a texture of the image; the image itself is
            // hidden while the halftone shows.
            ShaderEffectSource {
                id: texture
                sourceItem: image
                hideSource: win.halftoned
            }

            Halftone {
                anchors.fill: parent
                visible: win.halftoned && image.status === Image.Ready
                source: texture
                dotSize: win.look.dotSize
                light: win.look.light
                imageColours: win.look.effect === "color"
            }
        }
    }
}
