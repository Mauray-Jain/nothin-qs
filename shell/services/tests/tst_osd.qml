import QtQuick
import QtTest
import "../"

TestCase {
    name: "Osd"

    SignalSpy { id: asked; target: Brightness; signalName: "changeRequested" }

    function init() {
        Brightness.ready = false
        Osd.visible = false
        asked.clear()
    }

    function test_show_then_hide() {
        Osd.hideAfter = 200
        Osd.show("volume", 0.4, false)
        verify(Osd.visible)
        compare(Osd.kind, "volume")
        compare(Osd.value, 0.4)
        tryVerify(() => !Osd.visible, 1000)
    }

    function test_brightness_feed_and_steps() {
        verify(!Brightness.ready)
        Brightness.receive({ type: "brightness", brightness: 0.5 })
        verify(Brightness.ready)
        compare(Brightness.value, 0.5)
        Brightness.up()
        Brightness.down()
        compare(asked.signalArguments[0][0], "5%+")
        compare(asked.signalArguments[1][0], "5%-")
    }

    // Brightness changes after the first reading show the OSD.
    function test_brightness_change_shows_osd() {
        Brightness.receive({ type: "brightness", brightness: 0.3 })
        verify(!Osd.visible) // the first reading at start is not a change
        Brightness.receive({ type: "brightness", brightness: 0.7 })
        verify(Osd.visible)
        compare(Osd.kind, "brightness")
        compare(Osd.value, 0.7)
    }
}
