import QtQuick
import QtTest
import "../"
import "../../../core"
import "../../../services"

Item {
    width: 900
    height: 640

    DeckView { id: deck; anchors.fill: parent }
    SignalSpy { id: sets; target: Config; signalName: "setRequested" }

    TestCase {
        name: "Deck"
        when: windowShown

        function init() {
            Config.receive({ type: "config", config: {
                general: { name: "ada" },
                theme: { accent: "#d71921", background: "#000000" },
                rail: { position: "left", clock_24h: true, monitors: [] },
                wallpaper: { effect: "dots", dot_size: 17, light: 50 },
                desktop: { layout: "free", hero_clock: true, greeting: true,
                           widgets: ["weather", "calendar", "player", "system"],
                           system: ["cpu", "memory", "disk", "temperature"], positions: {} },
                idle: { suspend_mode: "suspend", fade: 5,
                        ac: { lock: 300, screen_off: 600, suspend: 0, lock_screen_off: 60 },
                        battery: { lock: 180, screen_off: 300, suspend: 840, lock_screen_off: 60 } } } })
            sets.clear()
            deck.page = "home"
        }

        function lastSet() { return sets.signalArguments[sets.count - 1] }

        function test_nav_switches_pages() {
            compare(deck.page, "home")
            mouseClick(findChild(deck, "nav-look"))
            compare(deck.page, "look")
            mouseClick(findChild(deck, "nav-idle"))
            compare(deck.page, "idle")
            mouseClick(findChild(deck, "nav-home"))
        }

        function test_home_toggles() {
            deck.page = "home"
            mouseClick(findChild(deck, "toggle-hero_clock"))
            compare(lastSet()[0], "desktop.hero_clock")
            compare(lastSet()[1], false)
            mouseClick(findChild(deck, "widget-player"))
            compare(lastSet()[0], "desktop.widgets")
            compare(lastSet()[1], ["weather", "calendar", "system"])
            mouseClick(findChild(deck, "system-disk"))
            compare(lastSet()[1], ["cpu", "memory", "temperature"])
        }

        function test_drag_to_place() {
            deck.page = "home"
            const box = findChild(deck, "place-weather")
            verify(box)
            mouseDrag(box, box.width / 2, box.height / 2, 40, 20)
            compare(lastSet()[0], "desktop.positions")
            const p = lastSet()[1].weather
            verify(p[0] >= 0 && p[0] <= 1 && p[1] >= 0 && p[1] <= 1)
            compare(Math.round(p[0] * 100) / 100, p[0]) // rounded to 2 places
        }

        function test_look_accent() {
            deck.page = "look"
            mouseClick(findChild(deck, "swatch-#2fbf71"))
            compare(lastSet()[0], "theme.accent")
            compare(lastSet()[1], "#2fbf71")
            const field = findChild(deck, "accent-field")
            field.text = "blue"
            field.accepted()
            compare(lastSet()[1], "#2fbf71") // not a colour: nothing sent
            field.text = "#123abc"
            field.accepted()
            compare(lastSet()[1], "#123abc")
        }

        function test_look_theme_mode() {
            deck.page = "look"
            findChild(deck, "segment-theme.mode").activated(1)
            compare(lastSet()[0], "theme.mode")
            compare(lastSet()[1], "matugen")
            verify(!findChild(deck, "segment-theme.matugen").visible) // only in matugen mode
        }

        function test_look_effect() {
            deck.page = "look"
            const seg = findChild(deck, "segment-wallpaper.effect")
            seg.activated(1)
            compare(lastSet()[0], "wallpaper.effect")
            compare(lastSet()[1], "color")
        }

        function test_idle_presets() {
            deck.page = "idle"
            const seg = findChild(deck, "segment-idle.ac.lock")
            compare(seg.currentIndex, 4) // 300 s = 5M
            seg.activated(5)
            compare(lastSet()[0], "idle.ac.lock")
            compare(lastSet()[1], 600)
            Config.receive({ type: "config", config: Object.assign({}, Config.values,
                { idle: Object.assign({}, Config.values.idle, { ac: { lock: 420, screen_off: 600, suspend: 0, lock_screen_off: 60 } }) }) })
            compare(seg.currentIndex, -1) // 7 min isn't a preset: nothing selected
        }

        function test_deck_state() {
            verify(!DeckState.open)
            DeckState.toggle()
            verify(DeckState.open)
            DeckState.toggle()
        }
    }
}
