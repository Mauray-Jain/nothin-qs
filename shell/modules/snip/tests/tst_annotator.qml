import QtQuick
import QtTest
import QtCore
import "../"
import "../../../core"

Item {
    width: 900
    height: 700

    // A stand-in "screenshot": the annotator only needs an image source.
    Rectangle { id: fake; width: 600; height: 400; color: "#3366aa"; visible: false
        Rectangle { x: 100; y: 100; width: 200; height: 100; color: "white" } }

    AnnotatorView { id: ann; anchors.fill: parent; crop: ({ x: 50, y: 40, width: 400, height: 300 }); sourceScale: 2 }
    SignalSpy { id: copy; target: ann; signalName: "copyRequested" }
    SignalSpy { id: save; target: ann; signalName: "saveRequested" }
    SignalSpy { id: cancel; target: ann; signalName: "cancelled" }

    TestCase {
        name: "AnnotatorView"
        when: windowShown

        function initTestCase() {
            Config.receive({ type: "config", config: { theme: { accent: "#d71921", background: "#000000" } } })
            fake.grabToImage(r => ann.source = r.url)
            tryVerify(() => ann.source != "", 2000)
        }

        function init() {
            ann.clear()
            ann.tool = "pen"
            ann.colour = Theme.accent
            copy.clear(); save.clear(); cancel.clear()
            ann.forceActiveFocus()
        }

        function sheet() { return findChild(ann, "snip-sheet") }

        function test_rect_tool() {
            ann.tool = "rect"
            mouseDrag(sheet(), 20, 30, 100, 50)
            compare(ann.shapes.length, 1)
            const s = ann.shapes[0]
            compare(s.type, "rect")
            compare([s.x, s.y, s.width, s.height], [20, 30, 100, 50])
            compare(s.colour, Theme.accent.toString())
        }

        function test_pen_collects_points_and_undo() {
            mouseDrag(sheet(), 10, 10, 60, 30)
            compare(ann.shapes[0].type, "pen")
            verify(ann.shapes[0].points.length >= 2)
            keyClick(Qt.Key_Z, Qt.ControlModifier)
            compare(ann.shapes.length, 0)
        }

        function test_arrow_and_blur() {
            ann.tool = "arrow"
            mouseDrag(sheet(), 10, 10, 80, 0)
            ann.tool = "blur"
            mouseDrag(sheet(), 100, 100, 60, 40)
            compare(ann.shapes.map(s => s.type), ["arrow", "blur"])
            verify(findChild(ann, "blur-1"))
        }

        function test_text_tool_types_then_enter_commits() {
            ann.tool = "text"
            mouseClick(sheet(), 50, 60)
            verify(ann.editing)
            keyClick(Qt.Key_H)
            keyClick(Qt.Key_I)
            keyClick(Qt.Key_Return)  // commits the text, doesn't copy
            verify(!ann.editing)
            compare(copy.count, 0)
            compare(ann.shapes[0].type, "text")
            compare(ann.shapes[0].text, "hi")
        }

        function test_tool_and_colour_keys() {
            keyClick(Qt.Key_R)
            compare(ann.tool, "rect")
            keyClick(Qt.Key_A)
            compare(ann.tool, "arrow")
            keyClick(Qt.Key_B)
            compare(ann.tool, "blur")
            mouseClick(findChild(ann, "colour-white"))
            compare(ann.colour.toString(), "#ffffff")
        }

        function test_enter_copies_ctrl_s_saves_escape_cancels() {
            keyClick(Qt.Key_Return)
            keyClick(Qt.Key_S, Qt.ControlModifier)
            keyClick(Qt.Key_Escape)
            compare([copy.count, save.count, cancel.count], [1, 1, 1])
        }

        Image { id: check; visible: false }

        function test_export_is_full_resolution() {
            ann.tool = "rect"
            mouseDrag(sheet(), 20, 20, 100, 60)
            const dir = String(StandardPaths.writableLocation(StandardPaths.TempLocation)).replace("file://", "")
            const path = dir + "/nothin-snip-test-" + Date.now() + ".png"
            let saved = null
            ann.exportImage(path, ok => saved = ok)
            tryVerify(() => saved !== null, 3000)
            verify(saved)
            check.source = "file://" + path
            tryVerify(() => check.status === Image.Ready, 3000)
            compare(check.implicitWidth, 800)   // crop 400×300 at scale 2
            compare(check.implicitHeight, 600)
        }
    }
}
