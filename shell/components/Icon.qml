import QtQuick
import "../core"

// A Material Symbols icon by name, e.g. Icon { name: "battery_full" }.
Text {
    property string name
    property real size: 20

    text: name
    color: Theme.text
    font.family: Theme.icons
    font.pixelSize: size
    font.weight: Font.Light
}
