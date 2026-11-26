import QtQuick
import "../../core"
import "../../components"
import "../../services"

// SHELL: your name, weather place, web search, and the binds cheatsheet.
Column {
    id: root

    spacing: 4

    SettingRow {
        label: "your name"
        SettingText { path: "general.name"; value: Config.values.general?.name ?? ""; placeholder: "for the greeting" }
    }
    SettingRow {
        label: "weather place"
        SettingText { path: "weather.location"; value: Config.values.weather?.location ?? ""; placeholder: "city or lat,lon (empty: by IP)" }
    }
    SettingRow {
        label: "web search"
        SettingText { path: "launcher.search_url"; value: Config.values.launcher?.search_url ?? ""; fieldWidth: 360; placeholder: "https://…?q=%s" }
    }
    SettingRow {
        label: "your niri binds"
        Pill { text: "show cheatsheet"; onClicked: CheatsheetState.toggle() }
    }
}
