pragma Singleton
import QtQuick

// CPU, memory, disk and temperature as the daemon samples them (every 2 s).
QtObject {
    property bool ready: false
    property real cpu: 0          // 0..1
    property var cpuHistory: []   // oldest first
    property real memory: 0       // 0..1 used
    property real memUsed: 0      // bytes
    property real memTotal: 0
    property real disk: 0         // 0..1 used, root filesystem
    property real diskUsed: 0
    property real diskTotal: 0
    property real temp: 0         // °C
    property bool hasTemp: false

    function receive(msg) {
        if (msg.type !== "system")
            return
        const s = msg.stats
        cpu = s.cpu
        cpuHistory = s.cpu_history
        memUsed = s.mem_used
        memTotal = s.mem_total
        memory = s.mem_total ? s.mem_used / s.mem_total : 0
        diskUsed = s.disk_used
        diskTotal = s.disk_total
        disk = s.disk_total ? s.disk_used / s.disk_total : 0
        temp = s.temp
        hasTemp = s.has_temp
        ready = true
    }
}
