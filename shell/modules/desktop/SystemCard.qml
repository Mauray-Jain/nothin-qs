import QtQuick
import "../../core"
import "../../components"
import "../../services"

// The rows chosen in desktop.system: cpu, memory, disk, temperature.
Card {
    id: root

    readonly property var rows: Config.values.desktop?.system ?? []

    function gb(bytes) {
        return (bytes / 1073741824).toFixed(bytes < 10737418240 ? 1 : 0)
    }

    Text {
        x: 24; y: 22
        text: "SYSTEM"
        color: Theme.label
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: Theme.labelSpacing
    }

    Column {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 24 }
        spacing: 12

        Repeater {
            model: root.rows

            Item {
                required property string modelData
                width: parent.width
                height: 24

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ({ cpu: "CPU", memory: "MEM", disk: "DISK", temperature: "TEMP" })[parent.modelData]
                    color: Theme.textSecondary
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.letterSpacing: Theme.labelSpacing
                }

                DotSpark {
                    visible: parent.modelData === "cpu"
                    x: 60
                    anchors.verticalCenter: parent.verticalCenter
                    values: SysStats.cpuHistory.length > 1 ? SysStats.cpuHistory : [0, 0]
                    rows: 4
                    dotSize: 3
                    gap: 2
                }
                DotRing {
                    visible: parent.modelData === "memory" || parent.modelData === "disk"
                    x: 60
                    anchors.verticalCenter: parent.verticalCenter
                    diameter: 22
                    dots: 20
                    dotSize: 2.5
                    value: parent.modelData === "memory" ? SysStats.memory : SysStats.disk
                }

                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: !SysStats.ready ? "--"
                        : parent.modelData === "cpu" ? Math.round(SysStats.cpu * 100) + "%"
                        : parent.modelData === "memory" ? root.gb(SysStats.memUsed) + " / " + root.gb(SysStats.memTotal) + " GB"
                        : parent.modelData === "disk" ? root.gb(SysStats.diskUsed) + " / " + root.gb(SysStats.diskTotal) + " GB"
                        : SysStats.hasTemp ? Math.round(SysStats.temp) + "°C" : "N/A"
                    color: parent.modelData === "temperature" && SysStats.temp >= 90 ? Theme.accent : Theme.text
                    font.family: Theme.mono
                    font.pixelSize: 13
                }
            }
        }
    }
}
