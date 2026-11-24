import QtQuick
import QtTest
import "../"

TestCase {
    name: "Dots"

    DotRing { id: ring; dots: 40; value: 0.7; diameter: 100; dotSize: 4 }
    DotRing { id: arc; dots: 28; value: 0; sweep: 270; startAngle: 135; diameter: 100; dotSize: 4 }
    DotSpark { id: spark; values: [3, 1, 5, 5, 2]; rows: 5; dotSize: 4; gap: 2 }
    DotSpark { id: flat; values: [7, 7, 7]; rows: 5 }

    function test_ring_lights_value_share_of_dots() {
        compare(ring.lit, 28)
        ring.value = 1.4
        compare(ring.lit, 40)
        ring.value = -1
        compare(ring.lit, 0)
        ring.value = 0.7
    }

    function test_ring_starts_at_twelve_o_clock_and_goes_clockwise() {
        const first = ring.dotCentre(0)
        fuzzyCompare(first.x, 50, 0.001)
        fuzzyCompare(first.y, 2, 0.001)  // radius = (100 - 4) / 2 from centre 50
        const quarter = ring.dotCentre(10)
        fuzzyCompare(quarter.x, 98, 0.001)
        fuzzyCompare(quarter.y, 50, 0.001)
    }

    function test_partial_sweep_reaches_both_ends() {
        const a = arc.dotCentre(0), b = arc.dotCentre(27)
        fuzzyCompare(a.x, 100 - b.x, 0.001)  // 135° and 45° mirror each other
        fuzzyCompare(a.y, b.y, 0.001)
    }

    function test_spark_maps_values_onto_rows() {
        compare(spark.level(0), 2)  // (3-1)/(5-1) * 4
        compare(spark.level(1), 0)
        compare(spark.level(2), 4)
        compare(spark.implicitWidth, 5 * 6 - 2)
        compare(spark.implicitHeight, 5 * 6 - 2)
    }

    function test_flat_spark_sits_in_the_middle() {
        compare(flat.level(0), 2)
    }
}
