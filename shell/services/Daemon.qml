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

    property Connections writes: Connections {
        target: Config
        function onSetRequested(key, value) {
            socket.write(JSON.stringify({ type: "set", path: key, value: value }) + "\n")
            socket.flush()
        }
    }
}
