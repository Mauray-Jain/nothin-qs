import QtQuick
import QtTest
import "../"
import "../../../core"

Item {
    width: 1100
    height: 700

    WallpaperPickerView {
        id: view
        anchors.fill: parent
        files: ["/w/a.png", "/w/b.png", "/w/c.png"]
        startEffect: "dots"
        startDotSize: 17
        startLight: 50
    }
    SignalSpy { id: applied; target: view; signalName: "applied" }
    SignalSpy { id: closed; target: view; signalName: "closeRequested" }

    TestCase {
        name: "WallpaperPickerView"
        when: windowShown

        function init() {
            Config.receive({ type: "config", config: { theme: { accent: "#d71921", background: "#000000" } } })
            view.reset("/w/b.png")
            applied.clear(); closed.clear()
            view.forceActiveFocus()
        }

        function test_starts_on_the_current_wallpaper() {
            compare(view.index, 1)
        }

        function test_arrows_and_enter() {
            keyClick(Qt.Key_Right)
            keyClick(Qt.Key_Right) // stops at the end
            compare(view.index, 2)
            keyClick(Qt.Key_Left)
            keyClick(Qt.Key_Return)
            compare(applied.count, 1)
            const c = applied.signalArguments[0][0]
            compare(c.path, "/w/b.png")
            compare(c.effect, "dots")
            compare(c.thisMonitor, false)
        }

        function test_preview_settings_go_with_the_choice() {
            findChild(view, "picker-effect").activated(1)   // color
            mouseClick(findChild(view, "picker-this-monitor"))
            mouseClick(findChild(view, "picker-apply"))
            const c = applied.signalArguments[0][0]
            compare(c.effect, "color")
            compare(c.thisMonitor, true)
        }

        function test_click_thumbnail_selects() {
            mouseClick(findChild(view, "thumb-0"))
            compare(view.index, 0)
        }

        function test_escape() {
            keyClick(Qt.Key_Escape)
            compare(closed.count, 1)
        }

        function test_empty_folder_message() {
            view.files = []
            verify(findChild(view, "picker-empty").visible)
            keyClick(Qt.Key_Return)
            compare(applied.count, 0)
            view.files = ["/w/a.png", "/w/b.png", "/w/c.png"]
        }
    }
}
