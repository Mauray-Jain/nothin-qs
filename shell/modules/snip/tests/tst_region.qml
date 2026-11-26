import QtQuick
import QtTest
import "../"
import "../../../core"

Item {
    width: 800
    height: 500

    RegionView { id: region; anchors.fill: parent }
    SignalSpy { id: chosen; target: region; signalName: "chosen" }
    SignalSpy { id: cancelled; target: region; signalName: "cancelled" }

    TestCase {
        name: "RegionView"
        when: windowShown

        function init() { chosen.clear(); cancelled.clear(); region.forceActiveFocus() }

        function test_drag_selects_an_area() {
            mouseDrag(region, 300, 200, -200, -100)
            compare(chosen.count, 1)
            compare(chosen.signalArguments[0][0], { x: 100, y: 100, width: 200, height: 100 })
        }

        function test_a_click_is_not_a_selection() {
            mouseClick(region, 50, 50)
            compare(chosen.count, 0)
        }

        function test_enter_takes_the_whole_screen() {
            keyClick(Qt.Key_Return)
            compare(chosen.signalArguments[0][0], { x: 0, y: 0, width: 800, height: 500 })
        }

        function test_escape_cancels() {
            keyClick(Qt.Key_Escape)
            compare(cancelled.count, 1)
        }
    }
}
