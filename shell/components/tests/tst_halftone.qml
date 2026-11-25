import QtQuick
import QtTest
import "../"
import "../../core"

TestCase {
    name: "Halftone"

    Halftone { id: fx; width: 200; height: 100 }

    function test_defaults_come_from_theme() {
        compare(fx.ink, Theme.text)
        compare(fx.paper, Theme.background)
    }

    function test_resolution_follows_size() {
        compare(fx.resolution, Qt.vector2d(200, 100))
        fx.width = 300
        compare(fx.resolution, Qt.vector2d(300, 100))
    }

    function test_points_at_the_compiled_shader() {
        verify(String(fx.fragmentShader).endsWith("shaders/halftone.frag.qsb"))
    }

    function test_image_colours_switch_the_shader_mode() {
        compare(fx.colorMode, 0)
        fx.imageColours = true
        compare(fx.colorMode, 1)
        fx.imageColours = false
    }
}
