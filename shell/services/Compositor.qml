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

    signal actionRequested(string action, int id)

    function focusWorkspace(id) { actionRequested("focus-workspace", id) }
    function toggleOverview() { actionRequested("toggle-overview", 0) }
    function quit() { actionRequested("quit", 0) } // log out; niri asks to confirm

    readonly property var focusedWindow: windows.find(w => w.focused) ?? null

    // focusedScreen picks the focused output from a list of screens (pass
    // Quickshell.screens), or the first one if none matches.
    function focusedScreen(screens) {
        return screens.find(s => s.name === focusedOutput) ?? screens[0]
    }

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
