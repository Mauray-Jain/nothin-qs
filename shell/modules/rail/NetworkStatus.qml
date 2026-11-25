import QtQuick
import Quickshell.Networking

// Wi-Fi strength or wired link from NetworkManager. Loaded through a Loader
// so a Quickshell without Quickshell.Networking only loses this icon.
RailButton {
    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var network: wifi ? wifi.networks.values.find(n => n.connected) ?? null : null
    readonly property real strength: network ? network.signalStrength : 0

    icon: wired ? "lan" : !wifi ? "wifi_off" : strength > 0.66 ? "wifi" : strength > 0.33 ? "wifi_2_bar" : "wifi_1_bar"
    tip: wired ? "wired" : network ? network.name + " " + Math.round(strength * 100) + "%" : "offline"
}
