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

    SignalSpy { id: actionSpy; target: Compositor; signalName: "actionRequested" }

    function test_actions_go_to_the_daemon() {
        actionSpy.clear()
        Compositor.focusWorkspace(3)
        Compositor.toggleOverview()
        Compositor.quit()
        Compositor.focusWindow(12)
        compare(actionSpy.count, 4)
        compare(actionSpy.signalArguments[3][0], "focus-window")
        compare(actionSpy.signalArguments[3][1], 12)
        compare(actionSpy.signalArguments[0][0], "focus-workspace")
        compare(actionSpy.signalArguments[0][1], 3)
        compare(actionSpy.signalArguments[1][0], "toggle-overview")
        compare(actionSpy.signalArguments[2][0], "quit")
    }

    function test_focused_screen() {
        Compositor.receive({ type: "compositor", state: state })
        const screens = [{ name: "eDP-1" }, { name: "HDMI-A-1" }]
        compare(Compositor.focusedScreen(screens).name, "HDMI-A-1")
        compare(Compositor.focusedScreen([{ name: "DP-9" }]).name, "DP-9") // falls back to the first
    }

    function test_ignores_other_messages() {
        Compositor.receive({ type: "compositor", state: state })
        Compositor.receive({ type: "config", config: {} })
        compare(Compositor.focusedOutput, "HDMI-A-1")
    }
}
