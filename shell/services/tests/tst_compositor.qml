import QtQuick
import QtTest
import "../"

TestCase {
    name: "Compositor"

    readonly property var state: ({
        focused_output: "HDMI-A-1",
        overview: true,
        outputs: [{ name: "eDP-1" }, { name: "HDMI-A-1" }],
        workspaces: [
            { id: 3, index: 1, output: "HDMI-A-1", active: true, focused: true, urgent: false },
            { id: 1, index: 1, output: "eDP-1", active: false, focused: false, urgent: false },
            { id: 2, index: 2, output: "eDP-1", active: true, focused: false, urgent: true }
        ],
        windows: [
            { id: 11, title: "Inbox", app_id: "thunderbird", workspace_id: 3, focused: true },
            { id: 12, title: "nothin", app_id: "firefox", workspace_id: 2, focused: false }
        ]
    })

    function test_empty_before_first_state() {
        compare(Compositor.focusedOutput, "")
        compare(Compositor.workspaces.length, 0)
        compare(Compositor.focusedWindow, null)
    }

    function test_receive_state() {
        Compositor.receive({ type: "compositor", state: state })
        compare(Compositor.focusedOutput, "HDMI-A-1")
        verify(Compositor.overview)
        compare(Compositor.outputs.length, 2)
        compare(Compositor.focusedWindow.app_id, "thunderbird")
    }

    function test_workspaces_on_an_output() {
        Compositor.receive({ type: "compositor", state: state })
        const ws = Compositor.workspacesOn("eDP-1")
        compare(ws.length, 2)
        compare(ws[0].id, 1)
        compare(ws[1].id, 2)
        compare(Compositor.workspacesOn("DP-9").length, 0)
    }

    function test_ignores_other_messages() {
        Compositor.receive({ type: "compositor", state: state })
        Compositor.receive({ type: "config", config: {} })
        compare(Compositor.focusedOutput, "HDMI-A-1")
    }
}
