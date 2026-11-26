import QtQuick
import Quickshell.Bluetooth

// Bluetooth adapter on/off, loaded through a Loader like WifiSwitch.
QtObject {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter ? adapter.enabled : false
    function toggle() { if (adapter) adapter.enabled = !adapter.enabled }
}
