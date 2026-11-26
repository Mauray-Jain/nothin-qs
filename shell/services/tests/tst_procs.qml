import QtQuick
import QtTest
import "../"

TestCase {
    name: "Procs"

    SignalSpy { id: watched; target: Procs; signalName: "watchRequested" }
    SignalSpy { id: ended; target: Procs; signalName: "endRequested" }

    readonly property var list: [
        { pid: 10, name: "kitty", cpu: 0.02, memory: 90e6, mine: true },
        { pid: 20, name: "firefox", cpu: 0.30, memory: 900e6, mine: true },
        { pid: 30, name: "Xwayland", cpu: 0.05, memory: 300e6, mine: true },
        { pid: 40, name: "sshd", cpu: 0.40, memory: 10e6, mine: false }
    ]

    function init() { watched.clear(); ended.clear(); Procs.sortBy = "cpu" }

    function test_sorting() {
        Procs.receive({ type: "procs", procs: list })
        compare(Procs.sorted.map(p => p.pid), [40, 20, 30, 10])
        Procs.sortBy = "memory"
        compare(Procs.sorted.map(p => p.pid), [20, 30, 10, 40])
    }

    function test_watch_and_end() {
        Procs.watch(true)
        compare(watched.signalArguments[0][0], true)
        Procs.end(20, false)
        compare(ended.signalArguments[0][0], 20)
        compare(ended.signalArguments[0][1], false)
    }

    function test_dnd_holds_popups() {
        Notifs.centerOpen = false
        Notifs.dnd = false
        verify(Notifs.wantsPopup())
        Notifs.dnd = true
        verify(!Notifs.wantsPopup())
        Notifs.dnd = false
        Notifs.centerOpen = true
        verify(!Notifs.wantsPopup())
        Notifs.centerOpen = false
    }
}
