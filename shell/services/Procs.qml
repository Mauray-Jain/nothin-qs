pragma Singleton
import QtQuick

// The process list from the daemon (only sent while watched), sorted by
// cpu or memory. end() asks the daemon to end one (force: SIGKILL).
QtObject {
    property var list: []
    property string sortBy: "cpu" // cpu | memory
    readonly property var sorted: list.slice().sort((a, b) => b[sortBy] - a[sortBy] || a.pid - b.pid)

    signal watchRequested(bool on)
    signal endRequested(int pid, bool force)

    function watch(on) { watchRequested(on) }
    function end(pid, force) { endRequested(pid, force) }

    function receive(msg) {
        if (msg.type === "procs")
            list = msg.procs
    }
}
