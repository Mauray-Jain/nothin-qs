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
        verify(!Config.loaded)
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
}
