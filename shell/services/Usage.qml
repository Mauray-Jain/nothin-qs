pragma Singleton
import QtQuick

// How much each launcher entry is used (id → frecency score), from the daemon.
// launched() reports a launch; the daemon records it and sends new scores.
QtObject {
    property var scores: ({})

    signal recordRequested(string id)

    function launched(id) {
        recordRequested(id)
    }

    function receive(msg) {
        if (msg.type === "usage")
            scores = msg.scores
    }
}
