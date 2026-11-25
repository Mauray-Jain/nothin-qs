import QtQuick
import "../../core"
import "../../components"
import "../../services"
import "Calendar.js" as Calendar

// This month, Monday first, today in accent.
Card {
    id: root

    readonly property int year: Clock.now.getFullYear()
    readonly property int month: Clock.now.getMonth()
    readonly property int today: Clock.now.getDate()
    readonly property string title: Clock.longMonths[month] + " " + year
    readonly property var weeks: Calendar.month(year, month).filter(w => w.some(d => d > 0))

    Text {
        x: 24; y: 22
        text: root.title
        color: Theme.label
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: Theme.labelSpacing
    }

    Grid {
        id: grid
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 20; topMargin: 0 }
        columns: 7
        readonly property real cellW: width / 7
        readonly property real cellH: Math.min(26, (root.height - 70) / (root.weeks.length + 1))

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Text {
                required property string modelData
                width: grid.cellW
                height: grid.cellH
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: Theme.label
                font.family: Theme.mono
                font.pixelSize: 10
            }
        }

        Repeater {
            model: [].concat(...root.weeks)
            Item {
                required property int modelData
                width: grid.cellW
                height: grid.cellH

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    radius: width / 2
                    color: Theme.accent
                    visible: parent.modelData === root.today
                }
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData > 0 ? parent.modelData : ""
                    color: parent.modelData === root.today ? Theme.text : Theme.textSecondary
                    font.family: Theme.mono
                    font.pixelSize: 11
                }
            }
        }
    }
}
