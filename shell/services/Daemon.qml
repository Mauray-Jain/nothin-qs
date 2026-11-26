import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

// The link to the nothin daemon. Routes its messages to the singletons and
// sends Config.set writes back. shell.qml creates exactly one.
Socket {
    id: socket

    path: Quickshell.env("NOTHIN_SOCKET") ?? ""
    connected: path !== ""

    parser: SplitParser {
        onRead: line => {
            const msg = JSON.parse(line)
            if (msg.type === "config" || msg.type === "error")
                Config.receive(msg)
            else if (msg.type === "compositor")
                Compositor.receive(msg)
            else if (msg.type === "system")
                SysStats.receive(msg)
            else if (msg.type === "weather")
                Weather.receive(msg)
            else if (msg.type === "brightness")
                Brightness.receive(msg)
            else if (msg.type === "usage")
                Usage.receive(msg)
            else if (msg.type === "files")
                FileSearch.receive(msg)
            else if (msg.type === "lock")
                LockState.receive(msg)
            else if (msg.type === "inhibit")
                IdleInhibit.receive(msg)
            else if (msg.type === "procs")
                Procs.receive(msg)
            else if (msg.type === "niri-config")
                NiriConfig.receive(msg)
        }
    }

    function send(msg) {
        socket.write(JSON.stringify(msg) + "\n")
        socket.flush()
    }

    property Connections writes: Connections {
        target: Config
        function onSetRequested(key, value) { socket.send({ type: "set", path: key, value: value }) }
    }

    property Connections launches: Connections {
        target: Usage
        function onRecordRequested(id) { socket.send({ type: "launch", entry: id }) }
    }

    property Connections finds: Connections {
        target: FileSearch
        function onRequested(query, seq) { socket.send({ type: "find", query: query, seq: seq }) }
    }

    property Connections lockReports: Connections {
        target: LockState
        function onReportLocked() { socket.send({ type: "locked" }) }
    }

    property Connections procs: Connections {
        target: Procs
        function onWatchRequested(on) { socket.send({ type: "procs-watch", on: on }) }
        function onEndRequested(pid, force) { socket.send({ type: "kill", pid: pid, force: force }) }
    }

    property Connections actions: Connections {
        target: Compositor
        function onActionRequested(action, id) { socket.send({ type: "action", action: action, id: id }) }
    }
}
