import QtQuick
import Quickshell.Services.UPower

// Battery level and charging, hidden on machines without a battery.
RailButton {
    readonly property var dev: UPower.displayDevice
    // Older Quickshell reports 0-100, newer 0-1.
    readonly property int percent: dev ? Math.round(dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0
    readonly property bool charging: dev && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged)

    visible: dev !== null && dev.isLaptopBattery
    icon: charging ? "battery_charging_full"
        : percent >= 95 ? "battery_full"
        : "battery_" + Math.max(0, Math.min(6, Math.floor(percent / 100 * 7))) + "_bar"
    active: !charging && percent <= 15
    tip: "battery " + percent + "%" + (charging ? " · charging" : "")
}
