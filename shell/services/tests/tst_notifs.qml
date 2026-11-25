import QtQuick
import QtTest
import "../"

TestCase {
    name: "Notifs"

    function note(summary) {
        return { summary: summary, dismissed: false, dismiss() { this.dismissed = true } }
    }

    function init() {
        Notifs.items = []
        Notifs.unread = 0
        Notifs.centerOpen = false
    }

    SignalSpy { id: popups; target: Notifs; signalName: "arrived" }

    function test_newest_first_and_unread() {
        Notifs.add(note("a"))
        Notifs.add(note("b"))
        compare(Notifs.items.map(n => n.summary), ["b", "a"])
        compare(Notifs.unread, 2)
        compare(popups.count, 2)
    }

    function test_opening_the_center_marks_read() {
        Notifs.add(note("a"))
        Notifs.toggleCenter()
        verify(Notifs.centerOpen)
        compare(Notifs.unread, 0)
        Notifs.add(note("b"))
        compare(Notifs.unread, 0) // seen while the center is open
    }

    function test_remove_and_clear() {
        const a = note("a"), b = note("b")
        Notifs.add(a)
        Notifs.add(b)
        Notifs.remove(a)
        compare(Notifs.items.length, 1)
        Notifs.clear()
        compare(Notifs.items.length, 0)
        verify(b.dismissed)
        compare(Notifs.unread, 0)
    }
}
