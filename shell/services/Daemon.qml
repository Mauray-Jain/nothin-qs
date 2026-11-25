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

    property Connections actions: Connections {
        target: Compositor
        function onActionRequested(action, id) { socket.send({ type: "action", action: action, id: id }) }
    }
}
