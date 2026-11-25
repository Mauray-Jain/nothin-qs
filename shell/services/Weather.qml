pragma Singleton
import QtQuick

// Current weather as the daemon fetched it (Open-Meteo, every 15 minutes).
// now: { place, temp, min, max, condition, icon, is_day, wind, humidity }
QtObject {
    property bool ready: false
    property var now: ({})

    function receive(msg) {
        if (msg.type !== "weather")
            return
        now = msg.weather
        ready = true
    }
}
