import QtQuick
import QtTest
import "../"
import "../Glyphs.js" as Glyphs

TestCase {
    name: "DotText"

    DotText { id: clock; text: "16:55"; dotSize: 4; gap: 2 }

    function test_every_glyph_is_seven_rows_of_equal_width() {
        for (const ch in Glyphs.font) {
            const rows = Glyphs.font[ch]
            compare(rows.length, 7, "rows of " + ch)
            for (const r of rows)
                compare(r.length, rows[0].length, "row width of " + ch)
        }
    }

    function test_covers_clock_date_and_labels() {
        for (const ch of "0123456789:ABCDEFGHIJKLMNOPQRSTUVWXYZ .-/%°")
            verify(Glyphs.font[ch] !== undefined, "missing glyph " + ch)
    }

    function test_layout_of_one() {
        // "1" is 5 wide; its rows are 00100,01100,00100,00100,00100,00100,01110 = 10 dots
        const l = Glyphs.layout("1")
        compare(l.columns, 5)
        compare(l.dots.length, 10)
        compare(l.dots[0].x, 2)
        compare(l.dots[0].y, 0)
    }

    function test_layout_spaces_characters_by_one_column() {
        const one = Glyphs.layout("1")
        const two = Glyphs.layout("11")
        compare(two.columns, one.columns * 2 + 1)
        compare(two.dots.length, one.dots.length * 2)
    }

    function test_lowercase_is_drawn_as_uppercase() {
        compare(Glyphs.layout("ab").dots.length, Glyphs.layout("AB").dots.length)
    }

    function test_unknown_characters_are_skipped_as_space() {
        compare(Glyphs.layout("~").dots.length, 0)
    }

    function test_component_size_follows_grid() {
        // 16:55 → 1(5) 6(5) :(1) 5(5) 5(5) + 4 spacing columns = 25 columns, 7 rows
        const pitch = clock.dotSize + clock.gap
        compare(clock.implicitWidth, 25 * pitch - clock.gap)
        compare(clock.implicitHeight, 7 * pitch - clock.gap)
    }
}
