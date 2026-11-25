pragma Singleton
import QtQuick

// Workspaces, windows, outputs and focus, as the nothin daemon reports them.
// The only way QML learns about the compositor; it never calls niri itself.
QtObject {
    property string focusedOutput: ""
    property bool overview: false
    property var outputs: []
    property var workspaces: [] // by output, then index
    property var windows: []

    readonly property var focusedWindow: windows.find(w => w.focused) ?? null

    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output)
    }

    // Takes one parsed daemon message; only "compositor" ones matter here.
    function receive(msg) {
        if (msg.type !== "compositor")
            return
        const s = msg.state
        focusedOutput = s.focused_output
        overview = s.overview
        outputs = s.outputs
        workspaces = s.workspaces
        windows = s.windows
    }
}
