import QtQuick
import "../../core"
import "../../components"

// A Toggle bound to a config value; flipping it saves it.
Toggle {
    id: root

    property string path
    property bool value

    checked: value
    onToggled: {
        Config.set(path, checked)
        checked = Qt.binding(() => root.value) // follow the file again
    }
}
