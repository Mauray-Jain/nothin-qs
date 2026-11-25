import QtQuick
import Quickshell.Bluetooth

// Bluetooth on, off or connected. Click turns the adapter on or off.
RailButton {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

    visible: adapter !== null
    icon: !adapter || !adapter.enabled ? "bluetooth_disabled" : connected.length > 0 ? "bluetooth_connected" : "bluetooth"
    tip: !adapter || !adapter.enabled ? "bluetooth off"
        : connected.length > 0 ? connected.map(d => d.name).join(", ") : "bluetooth on"
    onClicked: adapter.enabled = !adapter.enabled
}
