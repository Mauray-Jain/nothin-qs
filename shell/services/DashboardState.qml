pragma Singleton
import QtQuick

// Whether the dashboard is open (rail button, `nothin ipc dashboard toggle`).
QtObject {
    property bool open: false
    function toggle() { open = !open }
}
