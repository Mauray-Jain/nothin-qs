pragma Singleton
import QtQuick

// The launcher's file search: search() asks the daemon (which keeps the
// index), and only the reply to the latest request is kept.
QtObject {
    property var results: []
    property int seq: 0

    signal requested(string query, int seq)

    function search(q) {
        seq++
        if (q === "") {
            results = []
            return
        }
        requested(q, seq)
    }

    function receive(msg) {
        if (msg.type === "files" && msg.seq === seq)
            results = msg.results
    }
}
