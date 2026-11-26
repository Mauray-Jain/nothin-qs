import QtQuick
import "../../core"
import "../../services"

// Your own niri binds, grouped by what they do, read from your config.
// Nothing here is suggested or written.
Rectangle {
    id: root

    readonly property int sectionCount: NiriConfig.groups.length

    readonly property var named: ({
        Slash: "/", Comma: ",", Period: ".", Minus: "-", Equal: "=", BracketLeft: "[", BracketRight: "]",
        Semicolon: ";", Apostrophe: "'", Grave: "`", Backslash: "\\", Space: "SPACE", Return: "ENTER",
        Left: "←", Right: "→", Up: "↑", Down: "↓", Page_Up: "PG UP", Page_Down: "PG DN",
        WheelScrollDown: "WHEEL ↓", WheelScrollUp: "WHEEL ↑", WheelScrollLeft: "WHEEL ←", WheelScrollRight: "WHEEL →",
        XF86AudioRaiseVolume: "VOLUME UP", XF86AudioLowerVolume: "VOLUME DOWN", XF86AudioMute: "MUTE",
        XF86AudioMicMute: "MIC MUTE", XF86AudioPlay: "PLAY", XF86AudioPause: "PAUSE", XF86AudioNext: "NEXT",
        XF86AudioPrev: "PREVIOUS", XF86MonBrightnessUp: "BRIGHTNESS UP", XF86MonBrightnessDown: "BRIGHTNESS DOWN",
        Print: "PRINT"
    })

    function keyText(k) {
        return k.split("+").map(p => root.named[p] ?? p.replace(/^XF86/, "").toUpperCase()).join(" + ")
    }

    radius: Theme.radius
    color: Theme.surface

    Text {
        x: 28; y: 24
        text: "YOUR NIRI BINDS"
        color: Theme.label
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: Theme.labelSpacing
    }

    Text {
        objectName: "cheatsheet-message"
        anchors.centerIn: parent
        visible: root.sectionCount === 0
        width: parent.width - 80
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: (NiriConfig.error || "No binds found in your niri config").toUpperCase()
        color: NiriConfig.error ? Theme.accent : Theme.label
        font.family: Theme.mono
        font.pixelSize: 12
        font.letterSpacing: Theme.labelSpacing
    }

    Flickable {
        anchors { fill: parent; margins: 28; topMargin: 60 }
        contentHeight: flow.height
        clip: true

        Flow {
            id: flow
            width: parent.width
            spacing: 28

            Repeater {
                model: NiriConfig.groups

                Column {
                    required property var modelData
                    width: 340
                    spacing: 6

                    Text {
                        text: modelData.name.toUpperCase()
                        color: Theme.accent
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.letterSpacing: Theme.labelSpacing
                        bottomPadding: 4
                    }
                    Repeater {
                        model: parent.modelData.binds
                        Item {
                            required property var modelData
                            objectName: "bind-" + modelData.key
                            width: 340
                            height: 22
                            Text {
                                width: 150
                                elide: Text.ElideRight
                                text: root.keyText(parent.modelData.key)
                                color: Theme.text
                                font.family: Theme.mono
                                font.pixelSize: 11
                            }
                            Text {
                                x: 160
                                width: 180
                                elide: Text.ElideRight
                                text: NiriConfig.label(parent.modelData)
                                color: Theme.textSecondary
                                font.family: Theme.body
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }
}
