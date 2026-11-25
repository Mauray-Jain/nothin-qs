import QtQuick
import QtTest
import "../"
import "../../../services"

TestCase {
    name: "RailClock"

    RailClock { id: clock }

    function init() {
        Clock.ticker.running = false
        Clock.now = new Date(2026, 9, 24, 16, 55, 7)
    }

    function test_vertical_stacks_time_and_date() {
        clock.vertical = true
        clock.h24 = true
        compare(clock.lines, ["16", "55", "07", "SAT", "24", "OCT"])
        clock.h24 = false
        compare(clock.lines, ["4", "55", "07", "PM", "SAT", "24", "OCT"])
    }

    function test_horizontal_is_one_line() {
        clock.vertical = false
        clock.h24 = true
        compare(clock.lines, ["16:55:07", "SAT 24 OCT"])
        clock.h24 = false
        compare(clock.lines, ["4:55:07 PM", "SAT 24 OCT"])
    }
}
