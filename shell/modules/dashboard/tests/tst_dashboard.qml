import QtQuick
import QtTest
import "../"
import "../../../core"
import "../../../services"

Item {
    width: 1200
    height: 520

    DashboardView {
        id: view
        anchors.fill: parent
        wifiOn: true
        bluetoothOn: false
        caffeineOn: false
        volume: 0.4
        brightness: 0.7
        hasBrightness: true
    }
    SignalSpy { id: toggled; target: view; signalName: "toggleRequested" }
    SignalSpy { id: vol; target: view; signalName: "volumeRequested" }
    SignalSpy { id: ended; target: Procs; signalName: "endRequested" }

    TestCase {
        name: "DashboardView"
        when: windowShown

        function init() {
            Config.receive({ type: "config", config: { theme: { accent: "#d71921", background: "#000000" }, desktop: { system: ["cpu", "memory"] } } })
            Procs.receive({ type: "procs", procs: [
                { pid: 20, name: "firefox", command: "/usr/lib/firefox/firefox", cpu: 0.3, memory: 900e6, mine: true },
                { pid: 40, name: "sshd", command: "", cpu: 0.4, memory: 10e6, mine: false } ] })
            toggled.clear(); vol.clear(); ended.clear()
            Notifs.dnd = false
        }

        function test_toggles_ask_their_owner() {
            mouseClick(findChild(view, "toggle-wifi"))
            mouseClick(findChild(view, "toggle-bluetooth"))
            mouseClick(findChild(view, "toggle-caffeine"))
            compare(toggled.signalArguments.map(a => a[0]), ["wifi", "bluetooth", "caffeine"])
        }

        function test_dnd_is_set_here() {
            mouseClick(findChild(view, "toggle-dnd"))
            verify(Notifs.dnd)
            mouseClick(findChild(view, "toggle-dnd"))
            verify(!Notifs.dnd)
        }

        function test_volume_slider() {
            const s = findChild(view, "slider-volume")
            mouseClick(s, s.width * 0.8, s.height / 2)
            fuzzyCompare(vol.signalArguments[0][0], 0.8, 0.06)
        }

        function test_only_own_processes_can_be_ended() {
            const mine = findChild(view, "end-20")
            verify(mine && mine.visible)
            const theirs = findChild(view, "end-40")
            verify(!theirs || !theirs.visible)
            mouseClick(mine)   // arms
            compare(ended.count, 0)
            mouseClick(mine)   // confirms
            compare(ended.signalArguments[0][0], 20)
            compare(ended.signalArguments[0][1], false)
        }

        function test_sort_switch() {
            const seg = findChild(view, "proc-sort")
            seg.activated(1)
            compare(Procs.sortBy, "memory")
            seg.activated(0)
        }
    }
}
