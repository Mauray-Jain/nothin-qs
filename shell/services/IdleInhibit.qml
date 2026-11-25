pragma Singleton
import QtQuick

// Apps keeping the screen awake through org.freedesktop.ScreenSaver, as the
// daemon reports them. While any are active, idle does nothing.
QtObject {
    property var inhibitors: []
    readonly property bool active: inhibitors.length > 0

    function receive(msg) {
        if (msg.type === "inhibit")
            inhibitors = msg.inhibitors
    }
}
