pragma Singleton
import QtQuick

// Settings as the nothin daemon sent them. Read: Config.values.theme.accent.
// Write: Config.set("theme.accent", "#ffffff"). The daemon owns the file;
// services/Daemon.qml carries messages both ways.
QtObject {
    property var values: ({})
    property bool loaded: false

    signal setRequested(string path, var value)
    signal failed(string message)

    function set(path, value) {
        setRequested(path, value)
    }

    // Takes one parsed daemon message of type "config" or "error".
    function receive(msg) {
        if (msg.type === "config") {
            values = msg.config
            loaded = true
        } else if (msg.type === "error") {
            failed(msg.error)
        }
    }
}
