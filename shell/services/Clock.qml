pragma Singleton
import QtQuick

// The current time, ticking every second, and the shell's date formats.
QtObject {
    property date now: new Date()

    readonly property var days: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    readonly property var months: ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

    readonly property var longDays: ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
    readonly property var longMonths: ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY",
        "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]

    // ISO 8601 week number: weeks start on Monday; week 1 holds the first Thursday.
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        const day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7)
    }

    // "SATURDAY · 24 OCTOBER · WEEK 43"
    function formatLong(d) {
        return longDays[d.getDay()] + " · " + d.getDate() + " " + longMonths[d.getMonth()] + " · WEEK " + isoWeek(d)
    }

    function greeting(d) {
        const h = d.getHours()
        return h >= 5 && h < 12 ? "GOOD MORNING"
            : h >= 12 && h < 17 ? "GOOD AFTERNOON"
            : h >= 17 && h < 22 ? "GOOD EVENING"
            : "GOOD NIGHT"
    }

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
