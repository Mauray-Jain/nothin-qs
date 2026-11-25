import QtQuick
import "../core"

// Draws `source` (an Image or ShaderEffectSource) as a halftone dot field.
ShaderEffect {
    property var source
    property real dotSize: 17
    property real light: 0.5
    property color ink: Theme.text
    property color paper: Theme.background
    property bool imageColours: false // dots in the image's colours, not ink
    readonly property real colorMode: imageColours ? 1 : 0
    readonly property vector2d resolution: Qt.vector2d(width, height)

    fragmentShader: Qt.resolvedUrl("../shaders/halftone.frag.qsb")
}
