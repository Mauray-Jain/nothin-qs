import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../../core"
import "../../components"
import "../../services"

// Volume and brightness levels near the bottom of the focused monitor, and
// the IPC targets for your media keys:
//   nothin ipc volume up | down | mute
//   nothin ipc brightness up | down
//   nothin ipc media playPause | next | previous
Scope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function setVolume(v) {
        if (!audio)
            return
        audio.muted = false
        audio.volume = Math.max(0, Math.min(1, v))
    }

    PwObjectTracker { objects: [root.sink] }

    // Any volume change shows the OSD, whoever made it.
    Connections {
        target: root.audio
        function onVolumeChanged() { Osd.show("volume", root.audio.volume, root.audio.muted) }
        function onMutedChanged() { Osd.show("volume", root.audio.volume, root.audio.muted) }
    }

    Connections {
        target: Brightness
        function onChangeRequested(step) { Quickshell.execDetached(["brightnessctl", "set", step]) }
    }

    IpcHandler {
        target: "volume"
        function up(): void { root.setVolume(root.audio.volume + 0.05) }
        function down(): void { root.setVolume(root.audio.volume - 0.05) }
        function mute(): void { if (root.audio) root.audio.muted = !root.audio.muted }
    }

    IpcHandler {
        target: "brightness"
        function up(): void { Brightness.up() }
        function down(): void { Brightness.down() }
    }

    IpcHandler {
        target: "media"
        function playPause(): void { if (root.player) root.player.togglePlaying() }
        function next(): void { if (root.player) root.player.next() }
        function previous(): void { if (root.player) root.player.previous() }
    }

    PanelWindow {
        screen: Compositor.focusedScreen(Quickshell.screens)
        visible: Osd.visible
        anchors.bottom: true
        margins.bottom: 80
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: row.implicitWidth + 48
        implicitHeight: 56
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.surface

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 16

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Osd.kind === "brightness" ? "light_mode"
                        : Osd.muted || Osd.value === 0 ? "volume_off" : "volume_up"
                }
                DotBar {
                    anchors.verticalCenter: parent.verticalCenter
                    value: Osd.muted ? 0 : Osd.value
                    color: Osd.muted ? Theme.label : Theme.text
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    horizontalAlignment: Text.AlignRight
                    text: Osd.muted ? "MUTE" : Math.round(Osd.value * 100) + "%"
                    color: Theme.text
                    font.family: Theme.mono
                    font.pixelSize: 13
                }
            }
        }
    }
}
