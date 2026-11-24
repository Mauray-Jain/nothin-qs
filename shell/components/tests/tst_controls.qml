import QtQuick
import QtTest
import "../"
import "../../core"

Item {
    width: 600
    height: 400

    Column {
        Toggle { id: toggle }
        Segmented { id: seg; model: ["GRID", "FREE"] }
        Pill { id: pill; text: "CAFFEINE" }
        Knob { id: knob; value: 0.5 }
        Card { id: card; width: 200; height: 100 }
    }

    SignalSpy { id: toggledSpy; target: toggle; signalName: "toggled" }
    SignalSpy { id: activatedSpy; target: seg; signalName: "activated" }
    SignalSpy { id: pillSpy; target: pill; signalName: "clicked" }
    SignalSpy { id: knobSpy; target: knob; signalName: "moved" }

    TestCase {
        name: "Controls"
        when: windowShown

        function test_toggle_by_click_and_keys() {
            mouseClick(toggle)
            verify(toggle.checked)
            toggle.forceActiveFocus()
            keyClick(Qt.Key_Space)
            verify(!toggle.checked)
            keyClick(Qt.Key_Return)
            verify(toggle.checked)
            compare(toggledSpy.count, 3)
        }

        function test_segmented_by_click_and_keys() {
            compare(seg.currentIndex, 0)
            mouseClick(seg, seg.width * 0.75, seg.height / 2)
            compare(seg.currentIndex, 1)
            seg.forceActiveFocus()
            keyClick(Qt.Key_Left)
            compare(seg.currentIndex, 0)
            keyClick(Qt.Key_Left)
            compare(seg.currentIndex, 0)
            compare(activatedSpy.count, 2)
        }

        function test_pill_clicks() {
            mouseClick(pill)
            pill.forceActiveFocus()
            keyClick(Qt.Key_Space)
            compare(pillSpy.count, 2)
        }

        function test_knob_keys_and_drag() {
            knob.forceActiveFocus()
            keyClick(Qt.Key_Up)
            fuzzyCompare(knob.value, 0.55, 0.0001)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Down)
            fuzzyCompare(knob.value, 0.45, 0.0001)
            // Dragging up by the knob's height adds the full range, clamped at 1.
            mouseDrag(knob, knob.width / 2, knob.height / 2, 0, -knob.height)
            compare(knob.value, 1)
            verify(knobSpy.count >= 4)
        }

        function test_card_uses_theme() {
            compare(card.color, Theme.surface)
            compare(card.radius, Theme.radius)
        }
    }
}
