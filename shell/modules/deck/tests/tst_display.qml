import QtQuick
import QtTest
import "../Arrange.js" as Arrange

TestCase {
    name: "Arrange"

    readonly property var laptop: ({ name: "eDP-1", x: 0, y: 0, width: 1600, height: 1000 })

    function test_snaps_to_the_right_edge() {
        // dropped a little right of and below the laptop's top-right corner
        compare(Arrange.snap({ x: 1630, y: 25, width: 1920, height: 1080 }, [laptop], 50), { x: 1600, y: 0 })
    }

    function test_snaps_above_aligned_left() {
        compare(Arrange.snap({ x: -20, y: -1100, width: 1920, height: 1080 }, [laptop], 50), { x: 0, y: -1080 })
    }

    function test_far_away_stays_put() {
        compare(Arrange.snap({ x: 3000, y: 2000, width: 1920, height: 1080 }, [laptop], 50), { x: 3000, y: 2000 })
    }

    function test_modes_unique_and_sorted() {
        const out = { modes: [
            { width: 1920, height: 1080, refresh: 60.0 },
            { width: 2560, height: 1440, refresh: 59.951 },
            { width: 2560, height: 1440, refresh: 165.08 },
            { width: 1920, height: 1080, refresh: 60.0 }
        ] }
        compare(Arrange.modes(out).map(m => m.value), ["2560x1440@165.08", "2560x1440@59.951", "1920x1080@60"])
        compare(Arrange.modes(out)[0].label, "2560×1440 · 165 HZ")
    }

    function test_current_mode_value() {
        const out = { modes: [{ width: 2560, height: 1440, refresh: 165.08 }], current_mode: 0 }
        compare(Arrange.currentMode(out), "2560x1440@165.08")
        compare(Arrange.currentMode({ modes: [], current_mode: -1 }), "")
    }
}
