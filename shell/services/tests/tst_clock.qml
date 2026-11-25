import QtQuick
import QtTest
import "../"

TestCase {
    name: "Clock"

    readonly property date afternoon: new Date(2026, 9, 24, 16, 55, 7)  // Sat 24 Oct
    readonly property date midnight: new Date(2026, 0, 1, 0, 5, 9)      // Thu 1 Jan

    function test_time() {
        compare(Clock.formatTime(afternoon, true), "16:55:07")
        compare(Clock.formatTime(afternoon, false), "4:55:07 PM")
        compare(Clock.formatTime(midnight, true), "00:05:09")
        compare(Clock.formatTime(midnight, false), "12:05:09 AM")
    }

    function test_day_and_date() {
        compare(Clock.formatDay(afternoon), "SAT")
        compare(Clock.formatDate(afternoon), "24 OCT")
        compare(Clock.formatDay(midnight), "THU")
        compare(Clock.formatDate(midnight), "1 JAN")
    }

    function test_now_ticks() {
        const before = Clock.now
        wait(1100)
        verify(Clock.now > before)
    }

    function test_long_date_with_iso_week() {
        compare(Clock.formatLong(afternoon), "SATURDAY · 24 OCTOBER · WEEK 43")
        compare(Clock.formatLong(midnight), "THURSDAY · 1 JANUARY · WEEK 1")
        compare(Clock.formatLong(new Date(2027, 0, 1)), "FRIDAY · 1 JANUARY · WEEK 53")
    }

    function test_greeting_follows_the_hour() {
        compare(Clock.greeting(new Date(2026, 0, 1, 6, 0)), "GOOD MORNING")
        compare(Clock.greeting(new Date(2026, 0, 1, 12, 0)), "GOOD AFTERNOON")
        compare(Clock.greeting(new Date(2026, 0, 1, 18, 30)), "GOOD EVENING")
        compare(Clock.greeting(new Date(2026, 0, 1, 23, 0)), "GOOD NIGHT")
        compare(Clock.greeting(new Date(2026, 0, 1, 3, 0)), "GOOD NIGHT")
    }
}
