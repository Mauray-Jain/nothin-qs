import QtQuick
import "../../core"
import "../../components"

// One notification: app name, summary, body, its actions as pills, and a
// close button. Critical ones get an accent dot.
Card {
    id: root

    property var notification
    readonly property string header: (notification?.appName || "notification").toUpperCase()
    readonly property string summaryText: notification?.summary ?? ""
    readonly property string bodyText: notification?.body ?? ""
    readonly property bool critical: notification?.urgency === 2

    implicitHeight: column.implicitHeight + 36
    color: Theme.surfaceHigh

    Column {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 6

        Row {
            spacing: 8
            Rectangle {
                visible: root.critical
                width: 8; height: 8; radius: 4
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: root.header
                color: Theme.label
                font.family: Theme.mono
                font.pixelSize: 10
                font.letterSpacing: Theme.labelSpacing
            }
        }

        Text {
            width: parent.width - 28
            text: root.summaryText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.body
            font.pixelSize: 15
        }

        Text {
            visible: text !== ""
            width: parent.width
            text: root.bodyText
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            color: Theme.textSecondary
            font.family: Theme.body
            font.pixelSize: 13
        }

        Flow {
            visible: (root.notification?.actions ?? []).length > 0
            width: parent.width
            spacing: 6
            topPadding: 6

            Repeater {
                model: root.notification?.actions ?? []
                Pill {
                    required property var modelData
                    objectName: "action-" + modelData.identifier
                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }
    }

    Icon {
        objectName: "close"
        anchors { right: parent.right; top: parent.top; margins: 14 }
        name: "close"
        size: 18
        color: Theme.textSecondary
        TapHandler { onTapped: root.notification.dismiss() }
    }
}
