import QtQuick
import QtTest
import "../"

TestCase {
    name: "NiriConfig"

    function test_receive_and_groups() {
        verify(!NiriConfig.includesNothin)
        NiriConfig.receive({ type: "niri-config", includes_nothin: true, kdl_path: "/h/.config/niri/nothin.kdl", error: "",
            binds: [
                { key: "Mod+T", action: "spawn \"kitty\"", title: "Terminal", group: "apps" },
                { key: "Mod+1", action: "focus-workspace 1", title: "", group: "workspaces" },
                { key: "Mod+D", action: "spawn \"fuzzel\"", title: "", group: "apps" }
            ] })
        verify(NiriConfig.includesNothin)
        compare(NiriConfig.groups.map(g => g.name), ["apps", "workspaces"])
        compare(NiriConfig.groups[0].binds.length, 2)
        compare(NiriConfig.label(NiriConfig.groups[0].binds[0]), "Terminal")
        compare(NiriConfig.label(NiriConfig.groups[0].binds[1]), "spawn \"fuzzel\"")
    }
}
