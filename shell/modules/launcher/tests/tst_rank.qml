import QtQuick
import QtTest
import "../Rank.js" as Rank
import "../Results.js" as Results

TestCase {
    name: "Rank"

    readonly property var apps: [
        { id: "firefox.desktop", name: "Firefox", genericName: "Web Browser", keywords: ["internet"] },
        { id: "fileroller.desktop", name: "File Roller", genericName: "Archive Manager", keywords: [] },
        { id: "nautilus.desktop", name: "Files", genericName: "File Manager", keywords: ["folder"] },
        { id: "gimp.desktop", name: "GNU Image Manipulation Program", genericName: "Image Editor", keywords: [] },
        { id: "kitty.desktop", name: "kitty", genericName: "Terminal", keywords: ["shell"] }
    ]

    function ids(list) { return list.map(a => a.id) }

    function test_prefix_beats_word_beats_contains() {
        compare(ids(Rank.apps("fi", apps, {})), ["fileroller.desktop", "nautilus.desktop", "firefox.desktop"])
        compare(ids(Rank.apps("manip", apps, {})), ["gimp.desktop"])
        compare(ids(Rank.apps("browser", apps, {})), ["firefox.desktop"])   // generic name
        compare(ids(Rank.apps("shell", apps, {})), ["kitty.desktop"])       // keyword
        compare(ids(Rank.apps("gimp", apps, {})), ["gimp.desktop"])         // its id, and g-i-m-p in order
        compare(ids(Rank.apps("zzz", apps, {})), [])
    }

    function test_frecency_breaks_ties() {
        // all three start with "fi": the most used wins, then the name
        compare(ids(Rank.apps("fi", apps, { "firefox.desktop": 12 }))[0], "firefox.desktop")
        compare(ids(Rank.apps("fi", apps, { "nautilus.desktop": 5 })).slice(0, 2), ["nautilus.desktop", "fileroller.desktop"])
    }

    function test_empty_query_lists_by_use_then_name() {
        compare(ids(Rank.apps("", apps, { "kitty.desktop": 3, "gimp.desktop": 1 })),
                ["kitty.desktop", "gimp.desktop", "fileroller.desktop", "nautilus.desktop", "firefox.desktop"])
    }

    function test_subsequence_is_last_resort() {
        compare(ids(Rank.apps("ffx", apps, {})), ["firefox.desktop"])
    }

    function test_results_order() {
        const windows = [{ id: 7, title: "Inbox — Thunderbird", app_id: "thunderbird" }, { id: 8, title: "~", app_id: "kitty" }]
        const r = Results.build("2*3", apps, {}, windows)
        compare(r[0].kind, "calc")
        compare(r[0].title, "6")
        const k = Results.build("kitty", apps, {}, windows)
        compare(k.map(x => x.kind), ["app", "window"])
        compare(k[1].win.id, 8)
        compare(Results.build("", apps, {}, windows).filter(x => x.kind === "window").length, 0)
    }
}
