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
}
