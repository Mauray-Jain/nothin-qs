pragma Singleton
import QtQuick

// Every colour, font, radius and duration the shell uses. Surfaces wait for
// Config.loaded, so the fallbacks below are never on screen. In matugen mode
// the accent (and with theme.matugen = "full" the background and surfaces)
// come from the wallpaper.
QtObject {
    id: theme

    readonly property var wall: Config.values.theme?.mode === "matugen" ? Matugen.colours : null
    readonly property bool full: wall !== null && Config.values.theme?.matugen === "full"

    readonly property color background: full ? wall.background : (Config.values.theme?.background ?? "#000000")
    readonly property color accent: wall ? wall.accent : (Config.values.theme?.accent ?? "#d71921")
    readonly property color surface: full ? wall.surface : "#0f0f0f"
    readonly property color surfaceHigh: full ? wall.surface_high : "#161616"
    readonly property color text: "#ffffff"
    readonly property color textSecondary: "#7a7a7a"
    // Text drawn on the accent: dark on a light accent (matugen's usually are).
    readonly property real accentLuminance: 0.2126 * theme.accent.r + 0.7152 * theme.accent.g + 0.0722 * theme.accent.b
    readonly property color textOnAccent: theme.accentLuminance > 0.55 ? theme.background : theme.text
    readonly property color label: "#4a4a4a"

    readonly property real radius: 20
    readonly property int fast: 120
    readonly property int normal: 240

    readonly property string mono: monoLoader.name
    readonly property string body: bodyLoader.name
    readonly property string icons: iconLoader.name

    readonly property real labelSpacing: 2 // letter spacing for caps labels

    property FontLoader monoLoader: FontLoader { source: Qt.resolvedUrl("../assets/fonts/SpaceMono-Regular.ttf") }
    property FontLoader monoBoldLoader: FontLoader { source: Qt.resolvedUrl("../assets/fonts/SpaceMono-Bold.ttf") }
    property FontLoader bodyLoader: FontLoader { source: Qt.resolvedUrl("../assets/fonts/SpaceGrotesk.ttf") }
    property FontLoader iconLoader: FontLoader { source: Qt.resolvedUrl("../assets/fonts/MaterialSymbolsOutlined.ttf") }
}
