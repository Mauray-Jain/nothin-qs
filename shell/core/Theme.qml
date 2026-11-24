pragma Singleton
import QtQuick

// Every colour, font, radius and duration the shell uses. Surfaces wait for
// Config.loaded, so the fallbacks below are never on screen.
QtObject {
    readonly property color background: Config.values.theme?.background ?? "#000000"
    readonly property color accent: Config.values.theme?.accent ?? "#d71921"
    readonly property color surface: "#0f0f0f"
    readonly property color surfaceHigh: "#161616"
    readonly property color text: "#ffffff"
    readonly property color textSecondary: "#7a7a7a"
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
