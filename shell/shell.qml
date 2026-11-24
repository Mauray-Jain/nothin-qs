import QtQuick
import Quickshell
import "services"
import "modules/toast"
import "modules/testpage"
import "core"

ShellRoot {
    Daemon {}

    // Surfaces wait for the first config so Theme never shows fallbacks.
    LazyLoader {
        active: Config.loaded

        Scope {
            Toast {}
            TestPage {}
        }
    }
}
