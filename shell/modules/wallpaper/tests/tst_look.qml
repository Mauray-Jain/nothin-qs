import QtQuick
import QtTest
import "../Look.js" as Look

TestCase {
    name: "WallpaperLook"

    readonly property var shared: ({
        path: "/w/new.png", effect: "dots", dot_size: 17, light: 50,
        monitors: {
            "HDMI-A-1": { file: "old.jpg", path: "/w/old.jpg", effect: "color", dot_size: null, light: null },
            "DP-1": { file: null, path: "", effect: null, dot_size: 8, light: 70 }
        }
    })

    function test_no_override_uses_shared() {
        compare(Look.forOutput(shared, "eDP-1"), { path: "/w/new.png", effect: "dots", dotSize: 17, light: 0.5 })
    }

    function test_override_replaces_only_what_it_sets() {
        compare(Look.forOutput(shared, "HDMI-A-1"), { path: "/w/old.jpg", effect: "color", dotSize: 17, light: 0.5 })
        compare(Look.forOutput(shared, "DP-1"), { path: "/w/new.png", effect: "dots", dotSize: 8, light: 0.7 })
    }
}
