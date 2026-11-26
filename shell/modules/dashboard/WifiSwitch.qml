import QtQuick
import Quickshell.Networking

// Wi-Fi radio on/off. Loaded through a Loader so an older Quickshell
// without Quickshell.Networking only loses this tile.
QtObject {
    readonly property bool on: Networking.wifiEnabled
    function toggle() { Networking.wifiEnabled = !Networking.wifiEnabled }
}
