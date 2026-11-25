import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../../core"
import "../../components"

// The MPRIS player that is playing (else the first one): art in greyscale,
// title, artist, and previous / play-pause (accent) / next.
Card {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

    Text {
        x: 24; y: 22
        text: root.player ? "NOW PLAYING · " + root.player.identity.toUpperCase() : "NOTHING PLAYING"
        color: Theme.label
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: Theme.labelSpacing
    }

    Image {
        id: art
        visible: root.player && root.player.trackArtUrl
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(96, root.height - 110)
        height: width
        source: root.player ? root.player.trackArtUrl : ""
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectCrop
        layer.enabled: true
        layer.effect: MultiEffect { saturation: -1 }
    }

    Column {
        anchors {
            left: art.visible ? art.right : parent.left
            leftMargin: art.visible ? 16 : 24
            right: parent.right
            rightMargin: 24
            verticalCenter: parent.verticalCenter
        }
        spacing: 4
        visible: root.player !== null

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.player ? root.player.trackTitle : ""
            color: Theme.text
            font.family: Theme.body
            font.pixelSize: 17
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.player ? root.player.trackArtist : ""
            color: Theme.textSecondary
            font.family: Theme.body
            font.pixelSize: 13
        }
    }

    Row {
        anchors { left: parent.left; leftMargin: 18; bottom: parent.bottom; bottomMargin: 14 }
        spacing: 4
        visible: root.player !== null

        Repeater {
            model: [
                { icon: "skip_previous", act: () => root.player.previous(), on: root.player && root.player.canGoPrevious },
                { icon: root.player && root.player.isPlaying ? "pause" : "play_arrow", act: () => root.player.togglePlaying(),
                  on: root.player && root.player.canTogglePlaying, accent: true },
                { icon: "skip_next", act: () => root.player.next(), on: root.player && root.player.canGoNext }
            ]

            Item {
                required property var modelData
                width: 36
                height: 36
                opacity: modelData.on ? 1 : 0.3

                Icon {
                    anchors.centerIn: parent
                    name: parent.modelData.icon
                    size: 24
                    color: parent.modelData.accent ? Theme.accent : Theme.text
                }
                TapHandler { enabled: parent.modelData.on; onTapped: parent.modelData.act() }
            }
        }
    }
}
