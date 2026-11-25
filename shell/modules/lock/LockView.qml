import QtQuick
import "../../core"
import "../../components"
import "../../services"

// What a lock surface shows: the dot clock, date and greeting, battery, and
// (on the monitor that had focus) the password field and PAM's messages.
Rectangle {
    id: root

    property bool primary: false
    property bool busy: false
    property string message: ""
    property bool hasBattery: false
    property int batteryPercent: 0
    property bool charging: false

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
    readonly property string batteryText: hasBattery ? batteryPercent + "%" + (charging ? " · CHARGING" : "") : ""
    readonly property bool fieldVisible: primary
    readonly property string typed: input.text

    signal submitted(string password)

    function focusField() {
        input.forceActiveFocus()
    }

    color: Theme.background

    Column {
        anchors.centerIn: parent
        spacing: 18
        opacity: root.primary ? 1 : 0.4

        DotText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeText
            dotSize: 14
            gap: 6
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            color: Theme.textSecondary
            font.family: Theme.mono
            font.pixelSize: 13
            font.letterSpacing: Theme.labelSpacing
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.greetingText
            color: Theme.text
            font.family: Theme.body
            font.pixelSize: 26
        }

        Item { width: 1; height: 24 }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.fieldVisible
            width: 360
            height: 52
            radius: height / 2
            color: Theme.surfaceHigh

            TextInput {
                id: input
                anchors { fill: parent; leftMargin: 24; rightMargin: 24 }
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                focus: root.primary
                enabled: !root.busy
                color: Theme.text
                font.family: Theme.mono
                font.pixelSize: 16
                font.letterSpacing: 4

                Keys.onReturnPressed: send()
                Keys.onEnterPressed: send()
                function send() {
                    if (root.busy || text === "")
                        return
                    const pw = text
                    text = ""
                    root.submitted(pw)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: input.text === ""
                text: root.busy ? "CHECKING…" : "PASSWORD"
                color: Theme.label
                font.family: Theme.mono
                font.pixelSize: 12
                font.letterSpacing: Theme.labelSpacing
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.fieldVisible && root.message !== ""
            text: root.message.toUpperCase()
            color: Theme.accent
            font.family: Theme.mono
            font.pixelSize: 12
            font.letterSpacing: Theme.labelSpacing
        }
    }

    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 }
        visible: root.batteryText !== ""
        text: "BATTERY " + root.batteryText
        color: root.batteryPercent <= 15 && !root.charging ? Theme.accent : Theme.textSecondary
        font.family: Theme.mono
        font.pixelSize: 12
        font.letterSpacing: Theme.labelSpacing
    }
}
