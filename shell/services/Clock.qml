pragma Singleton
import QtQuick

// The current time, ticking every second, and the shell's date formats.
QtObject {
    property date now: new Date()

    readonly property var days: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    readonly property var months: ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

    function pad(n) {
        return n < 10 ? "0" + n : String(n)
    }

    // "16:55:07", or "4:55:07 PM" when h24 is false.
    function formatTime(d, h24) {
        const rest = ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
        if (h24)
            return pad(d.getHours()) + rest
        const h = d.getHours() % 12 || 12
        return h + rest + (d.getHours() < 12 ? " AM" : " PM")
    }

    function formatDay(d) {
        return days[d.getDay()]
    }

    // "24 OCT"
    function formatDate(d) {
        return d.getDate() + " " + months[d.getMonth()]
    }

    property Timer ticker: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: now = new Date()
    }
}
