import QtQuick
import QtTest
import "../"
import "../../../core"
import "../../../services"

Item {
    width: 1000
    height: 760

    DeckView { id: deck; anchors.fill: parent }
    SignalSpy { id: sets; target: Config; signalName: "setRequested" }

    TestCase {
        name: "DeckPages"
        when: windowShown

        function init() {
            Config.receive({ type: "config", config: {
                general: { name: "ada" }, theme: { accent: "#d71921", background: "#000000" },
                rail: { position: "left", clock_24h: true }, wallpaper: { effect: "dots", dot_size: 17, light: 50 },
                desktop: { layout: "grid", widgets: [], system: [], positions: {} },
                weather: { location: "Pune" }, launcher: { search_url: "https://duckduckgo.com/?q=%s" },
                idle: { suspend_mode: "suspend", fade: 5, ac: {}, battery: {} },
                display: { monitors: { "HDMI-A-1": { scale: 2 } } },
                niri: { gaps: 8, border_width: null, focus_ring: null } } })
            Compositor.receive({ type: "compositor", state: { focused_output: "eDP-1", overview: false, workspaces: [], windows: [],
                outputs: [
                    { name: "eDP-1", on: true, x: 0, y: 0, width: 1600, height: 1000, scale: 1.4, transform: "normal",
                      modes: [{ width: 2240, height: 1400, refresh: 60 }], current_mode: 0, vrr_supported: false },
                    { name: "HDMI-A-1", on: true, x: 1600, y: 0, width: 1920, height: 1080, scale: 2, transform: "normal",
                      modes: [{ width: 3840, height: 2160, refresh: 60 }, { width: 1920, height: 1080, refresh: 60 }], current_mode: 0, vrr_supported: true }
                ] } })
            NiriConfig.receive({ type: "niri-config", includes_nothin: false, kdl_path: "/h/nothin.kdl", error: "", binds: [] })
            sets.clear()
        }

        function lastSet() { return sets.signalArguments[sets.count - 1] }

        function test_nav_has_every_page() {
            for (const p of ["home", "look", "idle", "display", "windows", "input", "shell", "power"])
                verify(findChild(deck, "nav-" + p), p)
        }

        function test_display_writes_the_chosen_monitor() {
            deck.page = "display"
            wait(50)
            findChild(deck, "monitor-pick").activated(1)          // HDMI-A-1
            findChild(deck, "segment-display.monitors.HDMI-A-1.transform").activated(1)
            compare(lastSet()[0], "display.monitors.HDMI-A-1.transform")
            compare(lastSet()[1], "90")
            const scale = findChild(deck, "segment-display.monitors.HDMI-A-1.scale")
            compare(scale.currentIndex, 4)                         // 2 from config
            mouseClick(findChild(deck, "mode-1920x1080@60"))
            compare(lastSet()[0], "display.monitors.HDMI-A-1.mode")
            compare(lastSet()[1], "1920x1080@60")
            verify(findChild(deck, "segment-display.monitors.HDMI-A-1.vrr").visible)
        }

        function test_unusual_scale_is_offered() {
            deck.page = "display"
            wait(50)
            findChild(deck, "monitor-pick").activated(0)   // eDP-1 at 1.4
            const scale = findChild(deck, "segment-display.monitors.eDP-1.scale")
            compare(scale.model, ["1", "1.25", "1.4", "1.5", "1.75", "2"])
            compare(scale.currentIndex, 2)
        }

        function test_display_arranger_writes_position() {
            deck.page = "display"
            wait(50)
            const box = findChild(deck, "arrange-HDMI-A-1")
            mouseDrag(box, box.width / 2, box.height / 2, 0, 30)
            const keys = sets.signalArguments.map(a => a[0])
            verify(keys.includes("display.monitors.HDMI-A-1.x"))
            verify(keys.includes("display.monitors.HDMI-A-1.y"))
        }

        function test_windows_read_only_until_included() {
            deck.page = "windows"
            wait(50)
            verify(findChild(deck, "include-hint").visible)
            verify(!findChild(deck, "niri-controls").enabled)
            NiriConfig.receive({ type: "niri-config", includes_nothin: true, kdl_path: "", error: "", binds: [] })
            verify(!findChild(deck, "include-hint").visible)
            verify(findChild(deck, "niri-controls").enabled)
            const gaps = findChild(deck, "segment-niri.gaps")
            compare(gaps.currentIndex, 2)  // 8
            mouseClick(findChild(deck, "clear-niri.gaps"))
            compare(lastSet()[0], "niri.gaps")
            compare(lastSet()[1], null)
        }

        function test_shell_text_fields() {
            deck.page = "shell"
            wait(50)
            const loc = findChild(deck, "text-weather.location")
            compare(loc.text, "Pune")
            loc.text = "Tokyo"
            loc.accepted()
            compare(lastSet()[0], "weather.location")
            compare(lastSet()[1], "Tokyo")
            const name = findChild(deck, "text-general.name")
            name.text = ""
            name.accepted()
            compare(lastSet()[1], "")
        }
    }
}
