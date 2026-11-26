pragma Singleton
import QtQuick

// Whether the binds cheatsheet is open (`nothin ipc cheatsheet toggle`, SHELL page).
QtObject {
    property bool open: false
    function toggle() { open = !open }
}
