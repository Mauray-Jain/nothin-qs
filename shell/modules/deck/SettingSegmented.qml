import QtQuick
import "../../core"
import "../../components"

// A Segmented choice bound to a config value. `values` are what gets saved;
// `model` is what is shown. A value that isn't one of them selects nothing.
Segmented {
    id: root

    property string path
    property var values: []
    property var value

    objectName: "segment-" + path
    currentIndex: values.indexOf(value)
    onActivated: i => {
        Config.set(path, values[i])
        currentIndex = Qt.binding(() => root.values.indexOf(root.value))
    }
}
