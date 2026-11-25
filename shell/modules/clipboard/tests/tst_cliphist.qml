import QtQuick
import QtTest
import "../Cliphist.js" as Cliphist

TestCase {
    name: "Cliphist"

    readonly property string out: "42\thello world\n41\t[[ binary data 12 KiB png 640x480 ]]\n40\tline with\ttab\n\n"

    function test_parse() {
        const e = Cliphist.parse(out)
        compare(e.length, 3)
        compare(e[0], { id: "42", text: "hello world", image: false })
        compare(e[1].image, true)
        compare(e[2].text, "line with\ttab")
    }

    function test_filter() {
        const e = Cliphist.parse(out)
        compare(Cliphist.filter(e, "HELLO").map(x => x.id), ["42"])
        compare(Cliphist.filter(e, "").length, 3)
    }
}
