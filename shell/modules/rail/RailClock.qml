import QtQuick
import "../../core"
import "../../services"

// Time with seconds, day and date. Stacked on a vertical rail, one line on a
// horizontal one.
Column {
    id: root

    property bool vertical: true
    property bool h24: true

    readonly property var lines: {
        const t = Clock.formatTime(Clock.now, h24)
        const day = Clock.formatDay(Clock.now)
        const date = Clock.formatDate(Clock.now)
        if (!vertical)
            return [t, day + " " + date]
        const [hms, ampm] = t.split(" ")
        return hms.split(":").concat(ampm ? [ampm] : [], [day], date.split(" "))
    }
    // On a vertical rail the first three lines are h, m, s; the rest are labels.
    readonly property int timeLines: vertical ? 3 : 1

    spacing: vertical ? 0 : 2

    Repeater {
        model: root.lines

        Text {
            required property string modelData
            required property int index
            anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            text: modelData
            color: index < root.timeLines ? (index === 2 ? Theme.textSecondary : Theme.text) : Theme.textSecondary
            font.family: Theme.mono
            font.pixelSize: index < root.timeLines ? 13 : 9
            font.letterSpacing: index < root.timeLines ? 0 : 1
            topPadding: root.vertical && index === root.timeLines ? 6 : 0
        }
    }
}
