import QtQuick
import QtTest
import "../"

TestCase {
    name: "Icon"

    Icon { id: icon; name: "battery_full"; size: 24 }

    // The ligature turns the name into one glyph about `size` wide, not text.
    function test_name_renders_as_one_glyph() {
        verify(icon.implicitWidth > 12 && icon.implicitWidth < 36, "width " + icon.implicitWidth)
    }
}
