import QtQuick
import QtTest
import "../"

Item {
    width: 600
    height: 500

    Picker {
        id: picker
        anchors.fill: parent
        placeholder: "Search"
        items: [ { icon: "apps", title: "Firefox", subtitle: "APP" },
                 { icon: "apps", title: "Files", subtitle: "APP" },
                 { icon: "window", title: "kitty", subtitle: "WINDOW" } ]
    }
    SignalSpy { id: chosen; target: picker; signalName: "chosen" }
    SignalSpy { id: closed; target: picker; signalName: "closeRequested" }

    TestCase {
        name: "Picker"
        when: windowShown

        function init() { chosen.clear(); closed.clear(); picker.reset(); picker.forceActiveFocus() }

        function test_typing_sets_query() {
            keyClick(Qt.Key_F)
            keyClick(Qt.Key_I)
            compare(picker.query, "fi")
        }

        function test_arrows_and_enter() {
            compare(picker.current, 0)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Down) // stops at the end
            compare(picker.current, 2)
            keyClick(Qt.Key_Up)
            keyClick(Qt.Key_Return)
            compare(chosen.count, 1)
            compare(chosen.signalArguments[0][0], 1)
        }

        function test_escape_closes() {
            keyClick(Qt.Key_Escape)
            compare(closed.count, 1)
        }

        function test_click_chooses() {
            mouseClick(picker.rowAt(2))
            compare(chosen.signalArguments[0][0], 2)
        }

        function test_new_items_reset_selection() {
            keyClick(Qt.Key_Down)
            picker.items = [ { icon: "apps", title: "Only" } ]
            compare(picker.current, 0)
        }
    }
}
