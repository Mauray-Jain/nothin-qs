pragma Singleton
import QtQuick

// What the daemon read from the user's niri config: their binds (for the
// cheatsheet), and whether config.kdl includes nothin.kdl (without it the
// deck's WINDOWS and INPUT pages can't take effect).
QtObject {
    property var binds: []
    property bool includesNothin: false
    property string kdlPath: ""
    property string error: ""

    readonly property var groupOrder: ["apps", "windows", "focus", "move", "workspaces", "screenshots", "session", "other"]
    readonly property var groups: groupOrder
        .map(g => ({ name: g, binds: binds.filter(b => b.group === g) }))
        .filter(g => g.binds.length > 0)

    function label(b) {
        return b.title || b.action
    }

    function receive(msg) {
        if (msg.type !== "niri-config")
            return
        binds = msg.binds
        includesNothin = msg.includes_nothin
        kdlPath = msg.kdl_path
        error = msg.error
    }
}
