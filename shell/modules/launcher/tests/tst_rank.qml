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

    readonly property var ctx: ({
        apps: apps, scores: {}, windows: [{ id: 7, title: "Inbox — Thunderbird", app_id: "thunderbird" }, { id: 8, title: "~", app_id: "kitty" }],
        files: [], searchUrl: "https://duckduckgo.com/?q=%s", home: "/home/ada"
    })

    function test_results_order() {
        const r = Results.build("2*3", ctx)
        compare(r[0].kind, "calc")
        compare(r[0].title, "6")
        const k = Results.build("kitty", ctx)
        compare(k.map(x => x.kind), ["app", "window", "web"])  // the web row comes last
        compare(k[1].win.id, 8)
        compare(Results.build("", ctx).filter(x => x.kind === "window" || x.kind === "web").length, 0)
    }

    function test_emoji_prefix() {
        const r = Results.build(":thumbs up", ctx)
        verify(r.length > 0)
        verify(r.every(x => x.kind === "emoji"))
        compare(r[0].emoji, "👍")
        compare(Results.build(":", ctx).length, 0)
    }

    function test_file_prefix_uses_daemon_results() {
        const c = Object.assign({}, ctx, { files: ["/home/ada/Documents/report.pdf", "/srv/report.txt"] })
        const r = Results.build("/report", c)
        compare(r.map(x => x.kind), ["file", "file"])
        compare(r[0].title, "report.pdf")
        compare(r[0].subtitle, "~/Documents")
        compare(r[1].subtitle, "/srv")
        compare(r[0].path, "/home/ada/Documents/report.pdf")
    }

    function test_web_prefix() {
        const r = Results.build("?nothing phone (3)", ctx)
        compare(r.length, 1)
        compare(r[0].kind, "web")
        compare(r[0].url, "https://duckduckgo.com/?q=nothing%20phone%20(3)")
    }

    function test_fileQuery() {
        compare(Results.fileQuery("/report"), "report")
        compare(Results.fileQuery("report"), "")
    }
}
