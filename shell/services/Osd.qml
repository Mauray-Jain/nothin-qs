pragma Singleton
import QtQuick

// The on-screen display: which level to show (volume or brightness) and for
// how long. modules/osd draws it on the focused monitor.
QtObject {
    property bool visible: false
    property string kind: "volume"
    property real value: 0
    property bool muted: false
    property int hideAfter: 1500

    function show(k, v, m) {
        kind = k
        value = v
        muted = m ?? false
        visible = true
        hide.restart()
    }

    property Timer hide: Timer { interval: hideAfter; onTriggered: visible = false }
}
