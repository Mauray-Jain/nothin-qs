import QtQuick
import QtTest
import "../Snip.js" as Snip

TestCase {
    name: "SnipJs"

    function test_rect_from_any_corner() {
        compare(Snip.rectFrom({ x: 300, y: 200 }, { x: 100, y: 50 }), { x: 100, y: 50, width: 200, height: 150 })
        compare(Snip.rectFrom({ x: 1, y: 1 }, { x: 1, y: 1 }), { x: 1, y: 1, width: 0, height: 0 })
    }

    function test_to_pixels() {
        compare(Snip.toPixels({ x: 10.2, y: 20.6, width: 100, height: 50.5 }, 1.5), { x: 15, y: 31, width: 150, height: 76 })
    }

    function test_arrow_head_points_back_along_the_line() {
        const h = Snip.arrowHead(0, 0, 100, 0, 20)
        fuzzyCompare(h[0].x, 100 - 20 * Math.cos(Math.PI / 7), 1e-9)
        fuzzyCompare(h[0].y, -h[1].y, 1e-9)
        verify(h[0].x < 100 && h[1].x < 100)
    }

    function test_file_name() {
        compare(Snip.fileName(new Date(2026, 10, 26, 15, 4, 9)), "nothin-2026-11-26-150409.png")
    }
}
