import QtQuick
import QtTest
import "../Layout.js" as Layout

TestCase {
    name: "DesktopLayout"

    // 1000×700 window, 30 margin, 20 gap → cells 300 wide, 200 tall
    readonly property int w: 1000
    readonly property int h: 700

    function test_cells() {
        compare(Layout.cell(0, w, h), { x: 30, y: 30, width: 300, height: 200 })
        compare(Layout.cell(4, w, h), { x: 350, y: 250, width: 300, height: 200 })
        compare(Layout.cell(8, w, h), { x: 670, y: 470, width: 300, height: 200 })
    }

    function test_hero_takes_the_top_left_two_cells() {
        compare(Layout.hero(w, h), { x: 30, y: 30, width: 620, height: 200 })
    }

    function test_widgets_fill_free_cells_in_order() {
        compare(Layout.slots(4, true), [2, 3, 4, 5])
        compare(Layout.slots(4, false), [0, 1, 2, 3])
        compare(Layout.slots(9, true).length, 7) // no more cells than the grid has
    }

    function test_place_in_grid() {
        const d = { layout: "grid", positions: {} }
        compare(Layout.place(d, "calendar", 1, true, w, h), Layout.cell(3, w, h))
    }

    function test_place_free_uses_position_and_stays_on_screen() {
        const d = { layout: "free", positions: { weather: [0.5, 0.1], player: [0.95, 0.95] } }
        compare(Layout.place(d, "weather", 0, true, w, h), { x: 500, y: 70, width: 300, height: 200 })
        compare(Layout.place(d, "player", 2, true, w, h), { x: 700, y: 500, width: 300, height: 200 })
        // no position → its grid cell
        compare(Layout.place(d, "system", 3, true, w, h), Layout.cell(5, w, h))
    }
}
