import QtQuick
import Quickshell.Services.UPower
import "../../core"
import "../../components"

// POWER: power profile (power-profiles-daemon) and battery. Loaded only when
// opened, since it needs Quickshell's UPower module.
Column {
    id: root

    property var deck
    readonly property var dev: UPower.displayDevice
    readonly property bool hasBattery: dev && dev.isLaptopBattery
    readonly property int percent: dev ? Math.round(dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0

    function duration(s) {
        if (!s || s <= 0) return "--"
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        return h > 0 ? h + "H " + m + "M" : m + "M"
    }

    spacing: 4

    SettingRow {
        label: "power profile"
        Segmented {
            model: PowerProfiles.hasPerformanceProfile ? ["saver", "balanced", "performance"] : ["saver", "balanced"]
            currentIndex: PowerProfiles.profile === PowerProfile.PowerSaver ? 0 : PowerProfiles.profile === PowerProfile.Balanced ? 1 : 2
            onActivated: i => PowerProfiles.profile = [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance][i]
        }
    }
    SettingRow {
        visible: root.hasBattery
        label: "battery"
        Text {
            text: root.percent + "%" + (root.dev && root.dev.state === UPowerDeviceState.Charging ? " · CHARGING" : "")
            color: Theme.text; font.family: Theme.mono; font.pixelSize: 13
        }
    }
    SettingRow {
        visible: root.hasBattery
        label: root.dev && root.dev.state === UPowerDeviceState.Charging ? "full in" : "empty in"
        Text {
            text: root.duration(root.dev && root.dev.state === UPowerDeviceState.Charging ? root.dev.timeToFull : root.dev.timeToEmpty)
            color: Theme.text; font.family: Theme.mono; font.pixelSize: 13
        }
    }
    SettingRow {
        visible: root.hasBattery && root.dev.healthSupported
        label: "health"
        Text {
            text: Math.round(root.dev.healthPercentage) + "%"
            color: Theme.text; font.family: Theme.mono; font.pixelSize: 13
        }
    }
    SettingRow {
        label: "idle and sleep"
        Pill { text: "idle settings"; onClicked: if (root.deck) root.deck.page = "idle" }
    }
}
