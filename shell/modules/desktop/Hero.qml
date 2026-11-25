import QtQuick
import "../../core"
import "../../components"
import "../../services"

// The big dot clock (blinking colon), the long date and the greeting.
Column {
    id: root

    readonly property bool h24: Config.values.rail?.clock_24h ?? true
    readonly property string timeText: {
        const t = Clock.formatTime(Clock.now, h24).split(" ")[0]
        return t.slice(0, t.lastIndexOf(":"))
    }
    readonly property string dateText: Clock.formatLong(Clock.now)
    readonly property string greetingText: {
        const name = Config.values.general?.name ?? ""
        const g = Clock.greeting(Clock.now)
        return name ? g + ", " + name.toUpperCase() : g
    }
    readonly property bool showClock: Config.values.desktop?.hero_clock ?? true
    readonly property bool showGreeting: Config.values.desktop?.greeting ?? true

    spacing: 14

    Row {
        visible: root.showClock
        spacing: dot.pitch
        readonly property var parts: root.timeText.split(":")

        DotText { id: dot; text: parent.parts[0]; dotSize: 10; gap: 4 }
        DotText {
            text: ":"
            dotSize: 10
            gap: 4
            opacity: Clock.now.getSeconds() % 2 === 0 ? 1 : 0.25
            Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        }
        DotText { text: parent.parts[1]; dotSize: 10; gap: 4 }
    }

    Text {
        visible: root.showClock
        text: root.dateText
        color: Theme.textSecondary
        font.family: Theme.mono
        font.pixelSize: 12
        font.letterSpacing: Theme.labelSpacing
    }

    Text {
        visible: root.showGreeting
        text: root.greetingText
        color: Theme.text
        font.family: Theme.body
        font.pixelSize: 28
    }
}
