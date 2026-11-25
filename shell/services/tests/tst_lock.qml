import QtQuick
import QtTest
import "../"

TestCase {
    name: "LockState"

    SignalSpy { id: reported; target: LockState; signalName: "reportLocked" }

    function init() { LockState.locked = false; reported.clear() }

    function test_daemon_request_locks_and_is_answered() {
        LockState.receive({ type: "lock" })
        verify(LockState.locked)
        LockState.surfacesShown()
        compare(reported.count, 1)
    }

    function test_already_locked_still_answers() {
        LockState.lock()
        LockState.surfacesShown()
        LockState.receive({ type: "lock" })
        compare(reported.count, 2) // so a sleep waiting on it can go on
    }

    function test_unlock() {
        LockState.lock()
        LockState.unlock()
        verify(!LockState.locked)
    }

    function test_inhibitors() {
        IdleInhibit.receive({ type: "inhibit", inhibitors: [{ app: "mpv", reason: "video" }] })
        verify(IdleInhibit.active)
        compare(IdleInhibit.inhibitors[0].app, "mpv")
        IdleInhibit.receive({ type: "inhibit", inhibitors: [] })
        verify(!IdleInhibit.active)
    }
}
