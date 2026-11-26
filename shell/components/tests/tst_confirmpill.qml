import QtQuick
import QtTest
import "../"

Item {
    width: 300
    height: 100

    ConfirmPill { id: pill; text: "reboot"; confirmText: "reboot?"; timeout: 300 }
    SignalSpy { id: spy; target: pill; signalName: "confirmed" }

    TestCase {
        name: "ConfirmPill"
        when: windowShown

        function init() { spy.clear(); pill.armed = false }

        function test_second_press_confirms() {
            mouseClick(pill)
            verify(pill.armed)
            compare(pill.label, "reboot?")
            compare(spy.count, 0)
            mouseClick(pill)
            compare(spy.count, 1)
            verify(!pill.armed)
        }

        function test_disarms_after_timeout() {
            mouseClick(pill)
            tryVerify(() => !pill.armed, 1000)
            mouseClick(pill)
            compare(spy.count, 0)
        }

        function test_keyboard() {
            pill.forceActiveFocus()
            keyClick(Qt.Key_Return)
            keyClick(Qt.Key_Return)
            compare(spy.count, 1)
        }
    }
}
