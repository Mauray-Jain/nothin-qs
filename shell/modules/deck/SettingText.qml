import QtQuick
import "../../core"

// A text field bound to a config value; Enter saves what's typed.
Rectangle {
    id: root

    property string path
    property string value
    property string placeholder
    property int fieldWidth: 260

    width: fieldWidth
    height: 36
    radius: height / 2
    color: Theme.surfaceHigh

    TextInput {
        objectName: "text-" + root.path
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        text: root.value
        color: Theme.text
        selectionColor: Theme.accent
        font.family: Theme.mono
        font.pixelSize: 12
        onAccepted: Config.set(root.path, text)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: parent.text === ""
            text: root.placeholder.toUpperCase()
            color: Theme.label
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: Theme.labelSpacing
        }
    }
}
