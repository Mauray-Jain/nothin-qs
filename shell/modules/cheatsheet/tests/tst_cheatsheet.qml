import QtQuick
import QtTest
import "../"
import "../../../core"
import "../../../services"

Item {
    width: 1200
    height: 700

    CheatsheetView { id: view; anchors.fill: parent }

    TestCase {
        name: "Cheatsheet"
        when: windowShown

        function test_groups_and_keys() {
            Config.receive({ type: "config", config: { theme: { accent: "#d71921", background: "#000000" } } })
            NiriConfig.receive({ type: "niri-config", includes_nothin: true, kdl_path: "", error: "", binds: [
                { key: "Mod+T", action: "spawn \"kitty\"", title: "Terminal", group: "apps" },
                { key: "Mod+1", action: "focus-workspace 1", title: "", group: "workspaces" } ] })
            compare(view.sectionCount, 2)
            verify(findChild(view, "bind-Mod+T"))
            compare(view.keyText("Mod+Shift+Slash"), "MOD + SHIFT + /")
            compare(view.keyText("XF86AudioRaiseVolume"), "VOLUME UP")
        }

        function test_empty_or_broken_config() {
            NiriConfig.receive({ type: "niri-config", includes_nothin: false, kdl_path: "", error: "niri config.kdl line 3: missing }", binds: [] })
            compare(view.sectionCount, 0)
            verify(findChild(view, "cheatsheet-message").text.toLowerCase().includes("line 3"))
        }
    }
}
