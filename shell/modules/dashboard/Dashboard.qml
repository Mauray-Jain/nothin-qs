import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../../core"
import "../../services"
import "../desktop"

// The dashboard: a sheet that slides up from the bottom of the focused
// monitor. Opens from the rail and `nothin ipc dashboard toggle`; Escape
// closes it. The process list is only sampled while it is open.
Scope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null

    PwObjectTracker { objects: [root.sink] }

    Loader { id: wifi; source: "WifiSwitch.qml" }
    Loader { id: bluetooth; source: "BluetoothSwitch.qml" }

    Connections {
        target: DashboardState
        function onOpenChanged() { Procs.watch(DashboardState.open) }
    }

    IpcHandler {
        target: "dashboard"
        function toggle(): void { DashboardState.toggle() }
    }

    PanelWindow {
        id: win

        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: DashboardState.open || sheet.y < win.height
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "nothin-dashboard"
        exclusionMode: ExclusionMode.Ignore
        anchors.bottom: true
        implicitWidth: Math.min(1200, (screen ? screen.width : 1200) - 40)
        implicitHeight: 520
        color: "transparent"

        DashboardView {
            id: sheet
            width: parent.width
            height: parent.height - 16
            y: DashboardState.open ? 0 : win.height
            Behavior on y { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

            focus: true
            Keys.onEscapePressed: DashboardState.open = false

            wifiOn: wifi.item ? wifi.item.on : false
            bluetoothOn: bluetooth.item ? bluetooth.item.on : false
            caffeineOn: Caffeine.on
            volume: root.audio ? root.audio.volume : 0
            brightness: Brightness.value
            hasBrightness: Brightness.ready

            onToggleRequested: name => {
                if (name === "wifi" && wifi.item) wifi.item.toggle()
                else if (name === "bluetooth" && bluetooth.item) bluetooth.item.toggle()
                else if (name === "caffeine") Caffeine.toggle()
            }
            onVolumeRequested: v => { if (root.audio) { root.audio.muted = false; root.audio.volume = v } }
            onBrightnessRequested: v => Brightness.set(v)

            PlayerCard {
                parent: sheet.mediaSlot
                anchors.fill: parent
                color: Theme.surfaceHigh
            }
        }
    }
}
