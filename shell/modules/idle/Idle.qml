import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import "../../core"
import "../../services"
import "IdlePlan.js" as IdlePlan

// Idle: after [idle.ac] or [idle.battery] seconds without input, fade to black
// and lock, switch the screens off, and suspend. Apps keeping the screen awake
// (Wayland idle inhibitors, org.freedesktop.ScreenSaver, caffeine) stop it.
// Loaded only when nothin owns the session services (NOTHIN_EXCLUSIVE).
Scope {
    id: root

    readonly property var p: IdlePlan.plan(Config.values.idle, UPower.onBattery)
    readonly property bool allowed: !IdleInhibit.active
    property bool fading: false

    function startFade() {
        if (p.fadeFor <= 0) {
            LockState.lock()
            return
        }
        fading = true
        fadeDone.restart()
    }

    function cancelFade() {
        fading = false
        fadeDone.stop()
    }

    Timer {
        id: fadeDone
        interval: root.p.fadeFor * 1000
        onTriggered: {
            root.fading = false
            LockState.lock()
        }
    }

    IdleMonitor {
        enabled: root.allowed && root.p.fadeAt > 0 && !LockState.locked
        timeout: root.p.fadeAt
        respectInhibitors: true
        onIsIdleChanged: isIdle ? root.startFade() : root.cancelFade()
    }

    IdleMonitor {
        enabled: root.allowed && root.p.screenOff > 0
        timeout: root.p.screenOff
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Compositor.powerOffMonitors()
    }

    IdleMonitor {
        enabled: root.allowed && root.p.suspend > 0
        timeout: root.p.suspend
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(root.p.suspendCommand)
    }

    IdleMonitor {
        enabled: LockState.locked && root.p.lockScreenOff > 0
        timeout: root.p.lockScreenOff
        respectInhibitors: false
        onIsIdleChanged: if (isIdle) Compositor.powerOffMonitors()
    }

    // The fade: a black layer on every screen that takes no input, so any
    // movement both reaches your windows and cancels the lock.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.fading
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nothin-fade"
            exclusionMode: ExclusionMode.Ignore
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: root.fading ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: root.p.fadeFor * 1000 } }
            }
        }
    }
}
