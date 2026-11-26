pragma Singleton
import QtQuick

// Caffeine: keep the screen awake. The rail holds the Wayland idle inhibitor;
// the rail button and the dashboard tile both flip this.
QtObject {
    property bool on: false
    function toggle() { on = !on }
}
