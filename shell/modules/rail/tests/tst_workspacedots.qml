import QtQuick
import QtTest
import "../"
import "../../../core"
import "../../../services"

Item {
    width: 300
    height: 300

    WorkspaceDots { id: dots; output: "eDP-1" }
    SignalSpy { id: actions; target: Compositor; signalName: "actionRequested" }

    TestCase {
        name: "WorkspaceDots"
        when: windowShown

        function init() {
            Compositor.receive({ type: "compositor", state: {
                focused_output: "eDP-1", overview: false, outputs: [], windows: [],
                workspaces: [
                    { id: 7, index: 1, output: "HDMI-A-1", active: true, focused: false, urgent: false },
                    { id: 1, index: 1, output: "eDP-1", active: true, focused: true, urgent: false },
                    { id: 2, index: 2, output: "eDP-1", active: false, focused: false, urgent: true },
                    { id: 3, index: 3, output: "eDP-1", active: false, focused: false, urgent: false }
                ] } })
            actions.clear()
        }

        function test_one_dot_per_workspace_on_this_output() {
            compare(dots.count, 3)
        }

        function test_colours() {
            compare(dots.dotAt(0).color, Theme.accent)       // focused
            compare(dots.dotAt(2).color, Theme.label)        // idle
            Compositor.receive({ type: "compositor", state: {
                focused_output: "HDMI-A-1", overview: false, outputs: [], windows: [],
                workspaces: [
                    { id: 7, index: 1, output: "HDMI-A-1", active: true, focused: true, urgent: false },
                    { id: 1, index: 1, output: "eDP-1", active: true, focused: false, urgent: false }
                ] } })
            compare(dots.dotAt(0).color, Theme.text)         // shown here, focus elsewhere
        }

        function test_urgent_blinks() {
            verify(dots.dotAt(1).blinking)
            verify(!dots.dotAt(0).blinking)
        }

        function test_click_switches_workspace() {
            mouseClick(dots.dotAt(2))
            compare(actions.count, 1)
            compare(actions.signalArguments[0][0], "focus-workspace")
            compare(actions.signalArguments[0][1], 3)
        }

        function test_vertical_stacks_dots() {
            dots.vertical = true
            verify(dots.implicitHeight > dots.implicitWidth)
            dots.vertical = false
            verify(dots.implicitWidth > dots.implicitHeight)
        }
    }
}
