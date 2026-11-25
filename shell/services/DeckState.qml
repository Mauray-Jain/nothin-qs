pragma Singleton
import QtQuick

// Whether the settings deck is open (rail button, power menu, `nothin ipc deck toggle`).
QtObject {
    property bool open: false
    function toggle() { open = !open }
}
