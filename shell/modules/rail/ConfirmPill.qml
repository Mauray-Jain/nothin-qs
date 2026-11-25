import QtQuick
import "../../components"

// A pill that needs two presses: the first arms it and shows confirmText,
// the second within `timeout` ms emits confirmed.
FocusScope {
    id: root

    property string text
    property string confirmText
    property int timeout: 3000
    property bool armed: false
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
        onClicked: root.press()
    }

    Timer { id: disarm; interval: root.timeout; onTriggered: root.armed = false }
}
