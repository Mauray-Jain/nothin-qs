import QtQuick
import "../../core"
import "../../services"

// Shown on WINDOWS and INPUT until config.kdl includes nothin.kdl.
Text {
    objectName: "include-hint"
    visible: !NiriConfig.includesNothin
    width: parent ? parent.width : 400
    wrapMode: Text.Wrap
    bottomPadding: 12
    text: "READ-ONLY. ADD THIS LINE AT THE END OF ~/.CONFIG/NIRI/CONFIG.KDL TO USE THESE:\n\ninclude \"nothin.kdl\""
    color: Theme.accent
    font.family: Theme.mono
    font.pixelSize: 11
    font.letterSpacing: 1
}
