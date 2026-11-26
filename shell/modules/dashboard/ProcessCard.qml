import QtQuick
import "../../core"
import "../../components"
import "../../services"

// The busiest processes. Your own get END (SIGTERM, press twice); after an
// END, FORCE (SIGKILL, press twice) appears in case it doesn't go.
Card {
    id: root

    property var ended: ({})

    function size(bytes) {
        return bytes >= 1073741824 ? (bytes / 1073741824).toFixed(1) + "G" : Math.round(bytes / 1048576) + "M"
    }

    Text {
        x: 24; y: 22
        text: "PROCESSES"
        color: Theme.label
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: Theme.labelSpacing
    }

    Segmented {
        objectName: "proc-sort"
        anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 12 }
        height: 32
        model: ["cpu", "mem"]
        currentIndex: Procs.sortBy === "memory" ? 1 : 0
        onActivated: i => Procs.sortBy = i === 1 ? "memory" : "cpu"
    }

    ListView {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 16; topMargin: 56 }
        clip: true
        spacing: 2
        model: Procs.sorted.slice(0, 40)

        delegate: Item {
            id: row
            required property var modelData
            width: ListView.view.width
            height: 36

            Text {
                anchors { left: parent.left; leftMargin: 8; right: cpu.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: row.modelData.name
                elide: Text.ElideRight
                color: row.modelData.mine ? Theme.text : Theme.textSecondary
                font.family: Theme.body
                font.pixelSize: 13
            }
            Text {
                id: cpu
                anchors { right: mem.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                width: 44
                horizontalAlignment: Text.AlignRight
                text: Math.round(row.modelData.cpu * 100) + "%"
                color: Theme.text
                font.family: Theme.mono
                font.pixelSize: 11
            }
            Text {
                id: mem
                anchors { right: actions.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                width: 48
                horizontalAlignment: Text.AlignRight
                text: root.size(row.modelData.memory)
                color: Theme.textSecondary
                font.family: Theme.mono
                font.pixelSize: 11
            }
            Row {
                id: actions
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 4
                width: 128
                layoutDirection: Qt.RightToLeft

                ConfirmPill {
                    objectName: "end-" + row.modelData.pid
                    visible: row.modelData.mine
                    height: 28
                    idleColor: Theme.surface
                    text: "end"
                    confirmText: "end?"
                    onConfirmed: {
                        Procs.end(row.modelData.pid, false)
                        const e = Object.assign({}, root.ended)
                        e[row.modelData.pid] = true
                        root.ended = e
                    }
                }
                ConfirmPill {
                    objectName: "force-" + row.modelData.pid
                    visible: row.modelData.mine && root.ended[row.modelData.pid] === true
                    height: 28
                    idleColor: Theme.surface
                    text: "force"
                    confirmText: "kill?"
                    onConfirmed: Procs.end(row.modelData.pid, true)
                }
            }
        }
    }
}
