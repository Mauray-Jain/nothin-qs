import QtQuick
import "../core"

// A search box over a list: type to filter (the owner turns `query` into
// `items`), Up/Down/Tab to move, Enter or click to choose, Escape to close.
// items: [{ title, subtitle, icon (Material Symbols name) or iconSource (url) }]
FocusScope {
    id: root

    property string placeholder: "Search"
    property var items: []
    property int current: 0
    readonly property string query: input.text

    signal chosen(int index)
    signal closeRequested()

    function reset() {
        input.text = ""
        current = 0
        input.forceActiveFocus()
    }

    function rowAt(i) {
        return list.itemAtIndex(i)
    }

    function move(by) {
        current = Math.max(0, Math.min(items.length - 1, current + by))
        list.positionViewAtIndex(current, ListView.Contain)
    }

    onItemsChanged: current = 0

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surface
    }

    Rectangle {
        id: field
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        height: 52
        radius: height / 2
        color: Theme.surfaceHigh

        TextInput {
            id: input
            anchors { fill: parent; leftMargin: 22; rightMargin: 22 }
            verticalAlignment: TextInput.AlignVCenter
            focus: true
            color: Theme.text
            selectionColor: Theme.accent
            font.family: Theme.body
            font.pixelSize: 18

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) {
                    root.move(1)
                } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) {
                    root.move(-1)
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    if (root.items.length > 0)
                        root.chosen(root.current)
                } else if (e.key === Qt.Key_Escape) {
                    root.closeRequested()
                } else {
                    return
                }
                e.accepted = true
            }
        }

        Text {
            anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
            visible: input.text === ""
            text: root.placeholder.toUpperCase()
            color: Theme.label
            font.family: Theme.mono
            font.pixelSize: 13
            font.letterSpacing: Theme.labelSpacing
        }
    }

    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: field.bottom; bottom: parent.bottom; margins: 14 }
        clip: true
        model: root.items
        currentIndex: root.current

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            width: ListView.view.width
            height: 52
            radius: height / 2
            color: index === root.current ? Theme.surfaceHigh : "transparent"

            Item {
                id: iconBox
                x: 14
                width: 28
                height: 28
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    visible: !!row.modelData.iconSource
                    source: row.modelData.iconSource ?? ""
                    sourceSize: Qt.size(56, 56)
                }
                Icon {
                    anchors.centerIn: parent
                    visible: !row.modelData.iconSource
                    name: row.modelData.icon ?? ""
                    size: 22
                    color: row.index === root.current ? Theme.accent : Theme.text
                }
            }

            Text {
                anchors { left: iconBox.right; leftMargin: 14; right: sub.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                text: row.modelData.title
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Theme.text
                font.family: Theme.body
                font.pixelSize: 15
            }
            Text {
                id: sub
                anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                width: Math.min(implicitWidth, 200)
                elide: Text.ElideRight
                text: (row.modelData.subtitle ?? "").toUpperCase()
                color: Theme.label
                font.family: Theme.mono
                font.pixelSize: 10
                font.letterSpacing: Theme.labelSpacing
            }

            TapHandler { onTapped: root.chosen(row.index) }
        }
    }
}
