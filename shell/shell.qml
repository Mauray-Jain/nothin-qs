import QtQuick
import Quickshell
import "services"
import "modules/toast"
import "modules/testpage"
import "modules/rail"
import "modules/wallpaper"
import "modules/desktop"
import "modules/notifications"
import "modules/osd"
import "modules/launcher"
import "modules/clipboard"
import "modules/lock"
import "modules/idle"
import "modules/polkit"
import "modules/deck"
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
            Rail {}
            Notifications {}
            OsdWindow {}
            Launcher {}
            Clipboard {}
            Lock {}
            Deck {}
        }
    }

    // The test page from phases 1.1–1.2, for `nothin run --dev` only.
    LazyLoader {
        active: Config.loaded && Quickshell.env("NOTHIN_DEV") === "1"
        TestPage {}
    }

    // One per session: these wait until nothin owns the session services
    // (always for `nothin run`; with --exclusive under --dev).
    LazyLoader {
        active: Config.loaded && Quickshell.env("NOTHIN_EXCLUSIVE") === "1"

        Scope {
            Idle {}
            PolkitDialog {}
        }
    }
}
