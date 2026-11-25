import QtQuick
import QtTest
import "../Calendar.js" as Calendar

TestCase {
    name: "Calendar"

    function test_month_starts_on_monday_columns() {
        const g = Calendar.month(2026, 9) // October 2026 starts on a Thursday
        compare(g.length, 6)
        compare(g[0], [0, 0, 0, 1, 2, 3, 4])
        compare(g[4], [26, 27, 28, 29, 30, 31, 0])
        compare(g[5], [0, 0, 0, 0, 0, 0, 0])
    }

    function test_month_starting_on_sunday() {
        const g = Calendar.month(2026, 1) // February 2026 starts on a Sunday, 28 days
        compare(g[0], [0, 0, 0, 0, 0, 0, 1])
        compare(g[4], [23, 24, 25, 26, 27, 28, 0])
    }

    function test_leap_february() {
        const g = Calendar.month(2028, 1)
        verify(g.some(week => week.includes(29)))
    }
}
