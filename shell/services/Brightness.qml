pragma Singleton
import QtQuick

// Screen brightness (0..1) as the daemon reads it from /sys/class/backlight.
// up() and down() ask modules/osd to run brightnessctl; the new level comes
// back from the daemon and shows the OSD, so hardware keys show it too.
QtObject {
    property bool ready: false
    property real value: 0

    signal changeRequested(string step) // brightnessctl set <step>

    function up() { changeRequested("5%+") }
    function down() { changeRequested("5%-") }
    // set(v) asks for an absolute level, 0..1; never fully dark.
    function set(v) { changeRequested(Math.max(1, Math.round(v * 100)) + "%") }

    function receive(msg) {
        if (msg.type !== "brightness")
            return
        const first = !ready
        value = msg.brightness
        ready = true
        if (!first)
            Osd.show("brightness", value)
    }
}
