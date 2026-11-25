import QtQuick
import Quickshell.Io

Scope {
    IpcHandler {
        target: "volume"
        function up(): void { root.setVolume(root.audio.volume + 0.05) }
        function down(): void { if (x) { y() } }
        function mute(): void { if (root.audio) root.audio.muted = !root.audio.muted }
    }

    function notIpc(): void {}

    IpcHandler {
        target: "lock"
        function lock(): void { LockState.lock() }
        function named(name: string): string { return name }
    }
}
