import QtQuick
import Quickshell.Services.Pipewire

// Output volume: click to mute, scroll to change by 5%.
RailButton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int percent: audio ? Math.round(audio.volume * 100) : 0

    visible: audio !== null
    icon: !audio || audio.muted || percent === 0 ? "volume_off" : percent < 50 ? "volume_down" : "volume_up"
    tip: audio && audio.muted ? "volume muted" : "volume " + percent + "%"
    onClicked: audio.muted = !audio.muted
    onScrolled: steps => audio.volume = Math.max(0, Math.min(1, audio.volume + steps * 0.05))

    PwObjectTracker { objects: [root.sink] }
}
