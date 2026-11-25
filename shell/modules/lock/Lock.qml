import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import "../../core"
import "../../services"

// The lock screen: the session lock on every monitor, the password field on
// the one that had focus, checked through PAM ("login"). Lock with
// `nothin ipc lock lock`, the power menu, idle, or before sleep.
// If qs crashes while locked, niri keeps the session locked (red screen);
// switch to a TTY (Ctrl+Alt+F3) and run `nothin restart`.
Scope {
    id: root

    property string primaryName: ""
    property string message: ""
    property bool busy: false
    property string pending: ""

    readonly property var battery: UPower.displayDevice

    function submit(pw) {
        if (busy)
            return
        busy = true
        message = ""
        pending = pw
        if (!pam.active)
            pam.start()
        else if (pam.responseRequired)
            answer()
    }

    function answer() {
        if (pending === "")
            return
        pam.respond(pending)
        pending = ""
    }

    Connections {
        target: LockState
        function onLockedChanged() {
            if (LockState.locked) {
                root.primaryName = Compositor.focusedOutput
                root.message = ""
                root.busy = false
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { LockState.lock() }
    }

    PamContext {
        id: pam
        onResponseRequiredChanged: if (responseRequired) root.answer()
        onCompleted: result => {
            root.busy = false
            root.pending = ""
            if (result === PamResult.Success)
                LockState.unlock()
            else
                root.message = result === PamResult.MaxTries ? "too many tries, wait a moment" : "wrong password"
        }
        onError: error => {
            root.busy = false
            root.pending = ""
            root.message = "pam: " + PamError.toString(error)
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: LockState.locked
        onSecureChanged: if (secure) LockState.surfacesShown()

        surface: Component {
            WlSessionLockSurface {
                id: surface
                color: Theme.background

                LockView {
                    id: view
                    anchors.fill: parent
                    primary: surface.screen && (surface.screen.name === root.primaryName || root.primaryName === "")
                    busy: root.busy
                    message: root.message
                    hasBattery: root.battery && root.battery.isLaptopBattery
                    batteryPercent: root.battery ? Math.round(root.battery.percentage > 1 ? root.battery.percentage : root.battery.percentage * 100) : 0
                    charging: root.battery && (root.battery.state === UPowerDeviceState.Charging || root.battery.state === UPowerDeviceState.FullyCharged)
                    onSubmitted: pw => root.submit(pw)
                    Component.onCompleted: if (primary) focusField()
                }
            }
        }
    }
}
