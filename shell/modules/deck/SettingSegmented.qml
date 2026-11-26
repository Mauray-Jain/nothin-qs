import QtQuick
import "../../core"
import "../../components"

// A Segmented choice bound to a config value. `values` are what gets saved;
// `model` is what is shown. A value that isn't one of them selects nothing.
// With `clearable`, a × beside it removes the key (back to the default).
Segmented {
    id: root

    property string path
    property var values: []
    property var value
    property bool clearable: false

    objectName: "segment-" + path
    currentIndex: values.indexOf(value)
    onActivated: i => {
        Config.set(path, values[i])
        currentIndex = Qt.binding(() => root.values.indexOf(root.value))
    }

    Icon {
        objectName: "clear-" + root.path
        visible: root.clearable && root.value !== undefined && root.value !== null
        x: -28
        anchors.verticalCenter: parent.verticalCenter
        name: "close"
        size: 18
        color: Theme.textSecondary
        TapHandler { onTapped: Config.set(root.path, null) }
    }
}
