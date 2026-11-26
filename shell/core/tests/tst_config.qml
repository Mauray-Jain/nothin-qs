import QtQuick
import QtTest
import "../"

TestCase {
    name: "Config"

    SignalSpy { id: setSpy; target: Config; signalName: "setRequested" }
    SignalSpy { id: errSpy; target: Config; signalName: "failed" }

    function test_set_asks_the_daemon() {
        Config.set("general.name", "ada")
        compare(setSpy.count, 1)
        compare(setSpy.signalArguments[0][0], "general.name")
        compare(setSpy.signalArguments[0][1], "ada")
    }

    function test_receive_config_and_error() {
        Config.loaded = false // other tests may have loaded one already
        Config.receive({ type: "config", config: { general: { name: "bob" }, theme: { accent: "#00ff00", background: "#101010" } } })
        verify(Config.loaded)
        compare(Config.values.general.name, "bob")
        compare(Theme.accent, "#00ff00")
        compare(Theme.background, "#101010")

        Config.receive({ type: "error", error: "config.toml line 2: oops" })
        compare(errSpy.count, 1)
        compare(errSpy.signalArguments[0][0], "config.toml line 2: oops")
        compare(Config.values.general.name, "bob")
    }

    function test_bundled_fonts_load() {
        compare(Theme.mono, "Space Mono")
        compare(Theme.body, "Space Grotesk")
        compare(Theme.icons, "Material Symbols Outlined")
    }

    function test_on_monitor() {
        verify(Config.onMonitor([], "eDP-1"))
        verify(Config.onMonitor(["eDP-1"], "eDP-1"))
        verify(!Config.onMonitor(["HDMI-A-1"], "eDP-1"))
        verify(Config.onMonitor(undefined, "eDP-1"))
    }

    function theme(mode, scope) {
        Config.receive({ type: "config", config: { theme: { mode: mode, matugen: scope, accent: "#d71921", background: "#000000" } } })
    }

    function test_matugen_palette() {
        const p = { accent: "#a8c8ff", background: "#111318", surface: "#1d2024", surface_high: "#282a2f" }
        Matugen.receive({ type: "palette", palette: p })

        theme("mono", "accent")
        compare(Theme.accent, "#d71921")          // mono ignores the palette

        theme("matugen", "accent")
        compare(Theme.accent, "#a8c8ff")
        compare(Theme.surface, "#0f0f0f")         // accent only: the rest stays

        theme("matugen", "full")
        compare(Theme.background, "#111318")
        compare(Theme.surface, "#1d2024")
        compare(Theme.surfaceHigh, "#282a2f")

        Matugen.receive({ type: "palette", palette: null })   // matugen failed
        compare(Theme.accent, "#d71921")
        compare(Theme.background, "#000000")
        theme("mono", "accent")
    }

    function test_text_on_accent_stays_readable() {
        theme("mono", "accent")
        compare(Theme.textOnAccent, Theme.text)            // white on Nothing red
        Matugen.receive({ type: "palette", palette: { accent: "#a8c8ff", background: "#111318", surface: "#1d2024", surface_high: "#282a2f" } })
        theme("matugen", "accent")
        compare(Theme.textOnAccent, Theme.background)      // dark on light blue
        Matugen.receive({ type: "palette", palette: null })
        theme("mono", "accent")
    }
}
