import QtQuick
import QtTest
import "../"

TestCase {
    name: "DotBar"

    DotBar { id: bar; dots: 20; dotSize: 6; gap: 4; value: 0.42 }

    function test_lit_and_size() {
        compare(bar.lit, 8)
        compare(bar.implicitWidth, 20 * 10 - 4)
        compare(bar.implicitHeight, 6)
        bar.value = 2
        compare(bar.lit, 20)
        bar.value = 0.42
    }
}
