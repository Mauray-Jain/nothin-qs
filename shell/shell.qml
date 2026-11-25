import QtQuick
import Quickshell
import "services"
import "modules/toast"
import "modules/testpage"
import "modules/rail"
import "modules/wallpaper"
import "modules/desktop"
import "core"

ShellRoot {
    Daemon {}

    // Surfaces wait for the first config so Theme never shows fallbacks.
    LazyLoader {
        active: Config.loaded

        Scope {
            Wallpaper {}
            Desktop {}
            Toast {}
            TestPage {}
            Rail {}
        }
    }
}
