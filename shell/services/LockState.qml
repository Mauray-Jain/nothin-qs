pragma Singleton
import QtQuick

// Whether the screen is locked. modules/lock shows the lock surfaces while
// `locked`; once they are up it calls surfacesShown(), and the daemon is told
// (it may be holding sleep until then).
QtObject {
    property bool locked: false
    property bool shown: false

    signal reportLocked()

    function lock() {
        locked = true
    }

    function unlock() {
        locked = false
        shown = false
    }

    function surfacesShown() {
        shown = true
        if (locked)
            reportLocked()
    }

    function receive(msg) {
        if (msg.type !== "lock")
            return
        if (locked && shown)
            reportLocked()
        else
            lock()
    }
}
