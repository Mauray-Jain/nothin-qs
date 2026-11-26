pragma Singleton
import QtQuick

// Colours matugen took from the wallpaper, sent by the daemon when
// theme.mode = "matugen". null when off or when matugen failed, so Theme
// falls back to the configured colours.
QtObject {
    property var colours: null // { accent, background, surface, surface_high }

    function receive(msg) {
        if (msg.type === "palette")
            colours = msg.palette
    }
}
