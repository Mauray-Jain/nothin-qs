pragma Singleton
import QtQuick

// Notifications nothin has received, newest first, and the center's state.
// modules/notifications feeds it from the notification server.
QtObject {
    property var items: []
    property int unread: 0
    property bool centerOpen: false

    signal arrived(var n) // a new one: show it as a popup

    function add(n) {
        items = [n].concat(items)
        if (!centerOpen)
            unread++
        arrived(n)
    }

    function remove(n) {
        items = items.filter(x => x !== n)
    }

    function clear() {
        const all = items
        items = []
        unread = 0
        all.forEach(n => n.dismiss())
    }

    function toggleCenter() {
        centerOpen = !centerOpen
        if (centerOpen)
            unread = 0
    }
}
