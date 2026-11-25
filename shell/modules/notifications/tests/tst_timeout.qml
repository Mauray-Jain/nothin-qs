import QtQuick
import QtTest
import "../Timeout.js" as Timeout

TestCase {
    name: "PopupTimeout"

    function test_rules() {
        compare(Timeout.forPopup(-1, false), 5000) // the app left it to us
        compare(Timeout.forPopup(0, false), 0)     // the app asked to never expire
        compare(Timeout.forPopup(8000, false), 8000)
        compare(Timeout.forPopup(3000, true), 0)   // critical always stays
    }
}
