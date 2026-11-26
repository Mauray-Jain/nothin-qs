import QtQuick
import QtTest
import "../"

TestCase {
    name: "Feeds"

    function test_system_stats() {
        verify(!SysStats.ready)
        SysStats.receive({ type: "system", stats: { cpu: 0.25, cpu_history: [0.1, 0.25], mem_used: 4, mem_total: 16,
                                                    disk_used: 50, disk_total: 200, temp: 48.5, has_temp: true } })
        verify(SysStats.ready)
        compare(SysStats.cpu, 0.25)
        compare(SysStats.memory, 0.25)
        compare(SysStats.disk, 0.25)
        compare(SysStats.temp, 48.5)
        verify(SysStats.hasTemp)
        compare(SysStats.cpuHistory, [0.1, 0.25])
        SysStats.receive({ type: "weather", weather: {} })
        compare(SysStats.cpu, 0.25)
    }

    function test_weather() {
        verify(!Weather.ready)
        Weather.receive({ type: "weather", weather: { place: "Pune", temp: 17.4, min: 15.2, max: 29.8,
                                                     condition: "Partly cloudy", icon: "partly_cloudy_night" } })
        verify(Weather.ready)
        compare(Weather.now.place, "Pune")
        compare(Weather.now.icon, "partly_cloudy_night")
    }

    SignalSpy { id: recorded; target: Usage; signalName: "recordRequested" }

    function test_usage() {
        Usage.receive({ type: "usage", scores: { "firefox.desktop": 8 } })
        compare(Usage.scores["firefox.desktop"], 8)
        Usage.launched("kitty.desktop")
        compare(recorded.signalArguments[0][0], "kitty.desktop")
    }

    SignalSpy { id: finds; target: FileSearch; signalName: "requested" }

    function test_file_search_keeps_only_the_latest_reply() {
        FileSearch.search("rep")
        FileSearch.search("repo")
        compare(finds.count, 2)
        const old = finds.signalArguments[0][1], latest = finds.signalArguments[1][1]
        FileSearch.receive({ type: "files", seq: latest, query: "repo", results: ["/a/report"] })
        FileSearch.receive({ type: "files", seq: old, query: "rep", results: ["/stale"] })
        compare(FileSearch.results, ["/a/report"])
        FileSearch.search("")
        compare(FileSearch.results, [])
    }

    SignalSpy { id: listAsked; target: Wallpapers; signalName: "listRequested" }

    function test_wallpapers() {
        Wallpapers.togglePicker()
        verify(Wallpapers.pickerOpen)
        compare(listAsked.count, 1) // opening asks for a fresh list
        Wallpapers.receive({ type: "wallpapers", dir: "/w", files: ["/w/a.png"] })
        compare(Wallpapers.files, ["/w/a.png"])
        compare(Wallpapers.dir, "/w")
        Wallpapers.togglePicker()
        verify(!Wallpapers.pickerOpen)
    }
}
