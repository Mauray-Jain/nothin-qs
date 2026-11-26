import QtQuick
import "../core"

// A pill that needs two presses: the first arms it and shows confirmText,
// the second within `timeout` ms emits confirmed.
FocusScope {
    id: root

    property string text
    property string confirmText
    property int timeout: 3000
    property bool armed: false
    property color idleColor: Theme.surfaceHigh // set to Theme.surface on surfaceHigh cards
    readonly property string label: armed ? confirmText : text
    signal confirmed()

    function press() {
        if (armed) {
            armed = false
            confirmed()
        } else {
            armed = true
            disarm.restart()
        }
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight
    activeFocusOnTab: true

    Pill {
        id: pill
        anchors.fill: parent
        focus: true
        text: root.label
        active: root.armed
        color: root.armed ? Theme.text : root.idleColor
        onClicked: root.press()
    }

    Timer { id: disarm; interval: root.timeout; onTriggered: root.armed = false }
}
