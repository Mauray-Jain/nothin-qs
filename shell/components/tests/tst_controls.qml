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

        function test_knob_takes_focus_when_pressed() {
            toggle.forceActiveFocus()
            mouseClick(knob)
            verify(knob.activeFocus)
        }

        // The first dot of the arc (bottom left) is lit at any value above 0.
        function test_focused_knob_lights_in_accent() {
            Config.receive({ type: "config", config: { theme: { accent: "#00ff00", background: "#000000" } } })
            knob.value = 0.5
            knob.forceActiveFocus()
            wait(Theme.fast * 2) // colour animation
            const c = knob.children[0].dotCentre(0)
            const img = grabImage(knob)
            const px = img.pixel(Math.round(c.x), Math.round(c.y))
            verify(Qt.colorEqual(px, "#00ff00"), "lit dot is " + px)
        }

        function test_card_uses_theme() {
            compare(card.color, Theme.surface)
            compare(card.radius, Theme.radius)
        }
    }
}
