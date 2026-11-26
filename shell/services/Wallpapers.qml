pragma Singleton
import QtQuick

// The images in wallpaper.dir, from the daemon, and whether the picker is
// open. Opening it asks for a fresh list.
QtObject {
    property string dir: ""
    property var files: []
    property bool pickerOpen: false

    signal listRequested()

    function togglePicker() {
        pickerOpen = !pickerOpen
        if (pickerOpen)
            listRequested()
    }

    function receive(msg) {
        if (msg.type !== "wallpapers")
            return
        dir = msg.dir
        files = msg.files
    }
}
