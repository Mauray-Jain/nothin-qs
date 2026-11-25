import QtQuick
import QtTest
import "../"
import "../../../core"
import "../../../services"

Item {
    width: 900
    height: 400

    CalendarCard { id: calendar; width: 300; height: 260 }
    SystemCard { id: system; x: 310; width: 300; height: 260 }
    WeatherCard { id: weather; x: 620; width: 280; height: 260 }
    Hero { id: hero; y: 270; width: 600; height: 130 }

    TestCase {
        name: "Cards"
        when: windowShown

        function init() {
            Clock.ticker.running = false
            Clock.now = new Date(2026, 9, 24, 16, 55, 7)
            Config.receive({ type: "config", config: {
                general: { name: "ada" }, theme: { accent: "#d71921", background: "#000000" },
                rail: { clock_24h: true },
                desktop: { system: ["cpu", "temperature"], hero_clock: true, greeting: true } } })
        }

        function test_calendar_marks_today() {
            compare(calendar.title, "OCTOBER 2026")
            compare(calendar.today, 24)
        }

        function test_system_shows_only_configured_rows() {
            compare(system.rows, ["cpu", "temperature"])
            Config.receive({ type: "config", config: { theme: {}, desktop: { system: ["disk"] } } })
            compare(system.rows, ["disk"])
        }

        function test_weather_waits_for_data() {
            verify(!weather.hasData)
            Weather.receive({ type: "weather", weather: { place: "Pune", temp: 17.4, min: 15.2, max: 29.8,
                condition: "Partly cloudy", icon: "partly_cloudy_night" } })
            verify(weather.hasData)
            compare(weather.tempText, "17°")
        }

        function test_hero_text() {
            compare(hero.timeText, "16:55")
            compare(hero.dateText, "SATURDAY · 24 OCTOBER · WEEK 43")
            compare(hero.greetingText, "GOOD AFTERNOON, ADA")
        }

        function test_greeting_without_a_name() {
            Config.receive({ type: "config", config: { general: { name: "" }, theme: {}, rail: {}, desktop: {} } })
            compare(hero.greetingText, "GOOD AFTERNOON")
        }
    }
}
