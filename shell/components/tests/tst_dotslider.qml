import QtQuick
import QtTest
import "../"

Item {
    width: 400
    height: 100

    DotSlider { id: slider; width: 300; value: 0.5 }
    SignalSpy { id: moved; target: slider; signalName: "moved" }

    TestCase {
        name: "DotSlider"
        when: windowShown

        function init() { slider.value = 0.5; moved.clear() }

        function test_click_sets_value() {
            mouseClick(slider, slider.width * 0.25, slider.height / 2)
            fuzzyCompare(moved.signalArguments[0][0], 0.25, 0.05)
        }

        function test_drag_to_the_end_clamps() {
            mouseDrag(slider, slider.width / 2, slider.height / 2, slider.width, 0)
            compare(moved.signalArguments[moved.count - 1][0], 1)
        }

        function test_keys() {
            slider.forceActiveFocus()
            keyClick(Qt.Key_Right)
            fuzzyCompare(moved.signalArguments[0][0], 0.55, 1e-9)
            keyClick(Qt.Key_Left)
            fuzzyCompare(moved.signalArguments[1][0], 0.45, 1e-9) // from the bound 0.5
        }

        function test_value_is_owned_by_the_caller() {
            mouseClick(slider, slider.width * 0.9, slider.height / 2)
            compare(slider.value, 0.5) // the slider asks; the owner sets value
        }
    }
}
