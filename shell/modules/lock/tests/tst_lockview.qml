import QtQuick
import QtTest
import "../"
import "../../../core"
import "../../../services"

Item {
    width: 1200
    height: 800

    LockView { id: view; anchors.fill: parent; primary: true; batteryPercent: 64; charging: true; hasBattery: true }
    LockView { id: other; width: 400; height: 300; primary: false; hasBattery: false }
    SignalSpy { id: submitted; target: view; signalName: "submitted" }

    TestCase {
        name: "LockView"
        when: windowShown

        function init() {
            Clock.ticker.running = false
            Clock.now = new Date(2026, 9, 24, 21, 5, 0)
            Config.receive({ type: "config", config: { general: { name: "ada" }, theme: { accent: "#d71921", background: "#000000" }, rail: { clock_24h: true } } })
            submitted.clear()
            view.message = ""
            view.busy = false
        }

        function test_texts() {
            compare(view.timeText, "21:05")
            compare(view.dateText, "SATURDAY · 24 OCTOBER · WEEK 43")
            compare(view.greetingText, "GOOD EVENING, ADA")
            compare(view.batteryText, "64% · CHARGING")
        }

        function test_typing_and_enter_submits() {
            view.focusField()
            keyClick(Qt.Key_S)
            keyClick(Qt.Key_E)
            keyClick(Qt.Key_Return)
            compare(submitted.count, 1)
            compare(submitted.signalArguments[0][0], "se")
            compare(view.typed, "") // cleared after sending
        }

        function test_nothing_submitted_while_busy_or_empty() {
            view.focusField()
            keyClick(Qt.Key_Return)
            view.busy = true
            keyClick(Qt.Key_A)
            keyClick(Qt.Key_Return)
            compare(submitted.count, 0)
        }

        function test_other_screens_have_no_field() {
            verify(!other.fieldVisible)
            verify(view.fieldVisible)
            compare(other.batteryText, "")
        }
    }
}
