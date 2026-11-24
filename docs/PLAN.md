# nothin: a Nothing-style desktop shell for niri

A Quickshell desktop shell with a Go CLI/daemon, inspired by the "Nothing Linux 2.0"
video (@Bhavyaztwt, 51s; the original is a Hyprland Quickshell config called "glyph").
The goal is the same aesthetic, rebuilt from scratch, user friendly, niri first.
Implementation ideas are borrowed from **DMS** (Go CLI wrapping Quickshell, settings
service, idle, multi-monitor) and **Noctalia** (TOML config, manual compositor setup).

Guiding rule: **the simplest thing that works, first.** Every phase below should ship
the plainest version that meets its "done when" line.

---

## 1. Decisions (from the planning grill)

| # | Topic | Decision |
|---|---|---|
| 1 | Fidelity | Close to the video's look and layout, made user friendly, showing real data |
| 2 | Scope | Every surface in the video, plus the DMS features currently used |
| 3 | Rollout | Develop alongside DMS (`nothin run --dev`); switch the niri startup line at the end of milestone 1. DMS (dux-shell) stays installed for rollback |
| 4/9 | Desktop home | Widgets sit at fixed spots on the background layer. Windows cover them like a normal desktop; visible wherever no window is |
| 5 | Widgets | No GPU temperature. Which widgets show is a setting |
| 6/11/36 | Monitors | Multi-monitor supported. Every component has `monitors = []` (empty = all). Rail on all screens. Wallpaper shared, with `[wallpaper.monitors.<name>]` overrides. Desktop on all screens with a synced layout, optional per-screen layout. Notifications, OSD and launcher follow the focused output. Lock: password box on the focused output, dimmed clock elsewhere |
| 7 | Stack | QML for the UI. No extra runtime besides the Go binary |
| 8 | Audience | Personal first, easy for others to set up. Personal values live in config, never in code |
| 10 | Bento layout | 3×3 snap grid by default; free placement as an option. Hero clock and greeting are toggleable |
| 12 | Input | Mouse, touch and keyboard all work everywhere |
| 13 | Colours | Fixed monochrome by default, matugen (wallpaper colours) as an option, background colour configurable. App theming deferred |
| 14 | Wallpaper | The shell draws it (needed for halftone). Folder is a setting |
| 15/20 | CLI | `nothin`: `run [--dev DIR]`, `restart`, `kill`, `ipc <target> <fn> [args]`, `doctor`, `setup`, `keybinds` |
| 16/24/26 | Go | The `nothin` CLI is Go. `nothin run` stays alive as the parent of `qs`, owns `config.toml`, and serves the shell over a Unix socket. If `qs` crashes it is restarted; after 3 crashes within 10 seconds it gives up. Logs go to `~/.local/state/nothin/nothin.log`. QML is embedded with `go:embed` for installs; `--dev` loads the repo directly for live reload |
| 17 | Config file | One file: `~/.config/nothin/config.toml`. Only non-default values are written. The first run writes a short commented starter file. `config.example.toml` in the repo documents everything (lives in `docs/`) |
| 18 | Reload and errors | Hot reload (~50ms debounce), self-writes ignored, parse error → keep last good config + toast with line number + refuse to save. `config_version` plus migrations |
| 19 | State | Runtime data (notification history, launcher usage, recents) goes in `~/.local/state/nothin/`, not the TOML |
| 21 | DMS parity | Launcher, clipboard (cliphist), process list, notification center, OSDs and polkit agent, all in the dot style |
| 22/34 | Keybinds | Noctalia mentality: nothin never writes binds. `nothin setup` / `nothin keybinds` lists nothin's actions with suggested keys, marks which are free or taken in your niri config, and prints a snippet to paste. The README carries the same list |
| 23 | Compositors | niri only in v1, behind a compositor interface. More (Hyprland first) in v2 |
| 25 | Comments | Saves patch values in place so hand-written comments and order survive |
| 27/38 | niri settings | `config.toml` is the source of truth. DISPLAY is applied live via `niri msg output` (at start, on hotplug, after a niri config reload). WINDOWS/INPUT values generate `~/.config/niri/nothin.kdl`, which the user includes manually if they want it (Noctalia style); otherwise those pages are read-only |
| 28 | App theming | Deferred (kitty/GTK/Qt) |
| 29 | Launcher | Apps (frecency), calculator, windows, emoji, files, web search |
| 30 | Weather | Open-Meteo, location from config. IP lookup only when unset |
| 31/39 | Idle | DMS model: AC/battery timeouts for lock, screen-off, suspend and screen-off-after-lock; fade-to-lock; respects app and logind inhibitors; suspend / hibernate / suspend-then-hibernate; caffeine on the rail. Go handles D-Bus (`PrepareForSleep`, screensaver inhibit) |
| 32 | Lock testing | Develop the lock in a nested niri first. TTY fallback |
| 33 | Packaging | `make install` / `go install` now, AUR later. MIT licence |
| 35 | Cheatsheet | Overlay plus a SHELL page showing your real niri binds. Editor in v2 |
| 37 | Detection | Socket owner of `$WAYLAND_DISPLAY` first, then env vars. `compositor = "auto"` override |
| 41 | Shaders | `qt6-shadertools` for development only. Compiled `.qsb` files are committed; a `scripts/` helper rebuilds them and `make` checks they're current |
| 42 | Fonts | Space Mono and Space Grotesk (OFL) bundled in `shell/assets/fonts/`, loaded with `FontLoader` |
| 43 | Icons | Material Symbols variable font (Apache 2.0) at weight 300, bundled. Dot-matrix icons only where the video uses them |
| 44 | Module path | `github.com/Mauray-Jain/nothin-qs`; binary `nothin` |
| 45 | Git | Repo created (public, `Mauray-Jain/nothin-qs`). Commit at the end of each phase on `main`, tag each milestone (`m1`, `m2`, …). Push only when asked |
| 46 | Tests | Go: unit tests, especially config load, TOML patching, migrations and niri bind parsing. Pure QML components and JS logic: Qt Quick Test via `qmltestrunner`. Wayland surfaces: an acceptance check (IPC query or screenshot checklist) |
| 47 | Dependencies | Standard library by default. Add a package only when it clearly simplifies the code more than it costs (expected: `go-toml/v2`, `fsnotify`, `godbus/dbus`) |
| 48 | System tray | Monochrome tray icons in the rail, with their menus (Quickshell `SystemTray`). Milestone 1 |
| 49 | Test first | Write the test (or acceptance check) before the code, in every phase. Details in CLAUDE.md |

---

## 2. Visual language

| Token | Default |
|---|---|
| Background | `#000000` (configurable) |
| Surface | `#0f0f0f` to `#161616`, radius ~20px, no borders or shadows |
| Text | `#ffffff` primary, `#7a7a7a` secondary, `#4a4a4a` labels |
| Accent | `#d71921`, used only for active dots, play, errors and pen ink |
| Display type | Custom `DotText`: circles on a 5×7 grid (clock, counters, section titles) |
| Labels | Space Mono, caps, wide tracking (`SATURDAY · 24 OCTOBER · WEEK 43`) |
| Body | Space Grotesk |
| Texture | Halftone dot field; dithered art and wallpapers |
| Indicators | Dotted rings, dotted sparklines, pill toggles, segmented controls, dotted knobs |
| Motion | Short fades and staggers, a blinking colon, no bounce |

---

## 3. Architecture

The root stays minimal. Everything else lives in a folder named for what it is.

```
nothin-qs/
├── cmd/nothin/main.go            CLI entry only: parse args, call into internal/
├── internal/                     all Go logic, one package per concern
│   ├── cli/                      subcommand implementations (run, kill, restart, ipc, setup, doctor, keybinds)
│   ├── config/                   defaults, TOML load, validation, migrations, in-place patch writer
│   ├── daemon/                   supervise qs, file watch, Unix socket (JSON lines)
│   ├── compositor/               detection + interface
│   │   └── niri/                 outputs apply, kdl generation, bind parsing
│   └── dbus/                     logind PrepareForSleep, screensaver inhibit
├── shell/                        all QML
│   ├── embed.go                  the only Go file here: `//go:embed` so the binary carries the QML
│   ├── shell.qml
│   ├── core/                     Theme.qml, Config.qml (singletons)
│   ├── components/               DotText, DotRing, DotSpark, Card, Pill, Segmented, Toggle, Knob
│   ├── shaders/                  halftone.frag (+ compiled .qsb, committed)
│   ├── assets/                   fonts/ (Space Mono, Space Grotesk, Material Symbols)
│   ├── services/                 Compositor (+ niri backend), Clock, Weather, SysStats, Audio, Media, …
│   └── modules/                  one folder per surface: rail/, wallpaper/, desktop/, notifications/,
│                                 osd/, launcher/, clipboard/, lock/, polkit/, dashboard/, deck/, picker/, snip/
├── docs/                         PLAN.md, config.example.toml, user docs
├── packaging/                    AUR PKGBUILD, systemd unit (later)
├── scripts/                      dev helpers (nested niri, shader compile)
├── go.mod, go.sum                (Go requires these at the module root)
├── Makefile, README.md, LICENSE, CLAUDE.md, .gitignore
```

**Config flow:** `config.toml` → Go (parse, merge defaults, validate) → JSON over the socket →
`Config` singleton → QML bindings. A change in the settings UI → `set {path, value}` over the socket →
Go patches that value in the TOML → file watch reloads → new JSON to the shell.

**IPC:** each module has an `IpcHandler`; `nothin ipc <target> <fn>` forwards to `qs ipc call`.

**Compositor:** QML talks only to a `Compositor` singleton (workspaces, windows, outputs,
focused output, overview, actions). The niri backend reads `niri msg --json event-stream`.

**Sketch of `config.toml`** (all optional; defaults are in Go):
```toml
config_version = 1

[general]
name = "your-name"
compositor = "auto"

[theme]
mode = "mono"            # mono | matugen
accent = "#d71921"
background = "#000000"

[wallpaper]
dir = "~/Pictures/Wallpapers"
effect = "dots"          # none | dots | mono | color
dot_size = 17
light = 50

[desktop]
layout = "grid"          # grid | free
hero_clock = true
widgets = ["weather", "calendar", "player", "system"]

[notifications]
follow_focused = true

[weather]
location = "your-city"   # or "lat,lon"

[idle.ac]
lock = 300
screen_off = 600
suspend = 0

[idle.battery]
lock = 180
screen_off = 300
suspend = 840

[display.monitors."eDP-1"]
scale = 1.0

[niri]                   # only used if you include ~/.config/niri/nothin.kdl
gaps = 10
border_width = 1
```

---

## 4. Milestones

Each phase ends with something runnable. Each phase starts by writing its tests or acceptance
check (decision #49). Run the review skills listed in `CLAUDE.local.md` (repo root) at the end of
every milestone.

### Milestone 1: daily driver (replaces DMS)

| Phase | Work | Done when |
|---|---|---|
| 1.0 | **Scaffold**: go module, `nothin run --dev/kill/restart/ipc` (with qs restart policy and log), empty `shell.qml`, bundled fonts (Space Mono, Space Grotesk, Material Symbols), README, LICENSE | `nothin run --dev .` shows an empty shell next to DMS; `nothin kill` stops it |
| 1.1 | **Config daemon**: defaults, TOML load, hot reload, error handling, in-place patch writes, socket, QML `Config` singleton, starter file | Editing the TOML changes a test label live; a syntax error shows a toast and keeps the old value; a UI write keeps comments |
| 1.2 | **Design kit**: Theme, DotText + glyphs, DotRing, DotSpark, Card/Pill/Segmented/Toggle/Knob, Halftone shader | A test page renders `16:55`, a 70% ring and a halftoned image |
| 1.3 | **Compositor layer**: detection, niri backend (workspaces, windows, outputs, focus) | Workspace and focus changes log correctly on every connected output |
| 1.4 | **Rail**: workspace dots, mini clock, status icons, system tray, caffeine, power | Rail on every monitor; clicking dots switches workspaces; tray icons open their menus |
| 1.5 | **Wallpaper**: shared and per-monitor, halftone effect | Wallpaper renders as dots; effect settings apply live |
| 1.6 | **Desktop home**: hero clock, greeting, bento grid (weather, calendar, player, system), free mode | A side-by-side screenshot with the reference frame, reviewed by the user; widgets chosen from config; free mode renders positions from config |
| 1.7 | **Notifications + center + OSD** (volume, brightness, media IPC). Test with `dms kill` … `dms run` | nothin's notifications and OSD work with DMS stopped |
| 1.8 | **Launcher core + clipboard**: apps (frecency), calculator, windows; cliphist | Mod+P and Mod+Shift+C equivalents work |
| 1.9 | **Launcher extras**: emoji, files, web search | Each mode is reachable from the launcher |
| 1.10 | **Lock, idle, polkit, D-Bus**. Lock in a nested niri first; polkit tested with DMS stopped | Locks and unlocks, idle timers fire, lock before suspend, polkit prompts appear |
| 1.11 | **Settings deck, minimal**: nav + HOME (incl. drag-to-place for free mode), LOOK, IDLE | Changing a setting in the UI updates the TOML and the shell |
| 1.12 | **Setup + switch-over**: `nothin setup`, `nothin doctor`, keybind suggestions, README | Startup line is `nothin run`; DMS no longer spawned |

### Milestone 2: the rest of the video

| Phase | Work |
|---|---|
| 2.1 | Dashboard bottom sheet + process list |
| 2.2 | Deck: DISPLAY (live via `niri msg output`), WINDOWS/INPUT (generated `nothin.kdl`), POWER, SHELL + keybind cheatsheet overlay |
| 2.3 | Wallpaper picker (carousel, modes, knobs) |
| 2.4 | Screenshot annotator (grim, region, pen/arrow/rect/blur/text, copy/save) |
| 2.5 | Matugen colour mode |

### Milestone 3 (v2)

Hyprland backend, app theming (kitty, GTK, Qt), keybind editor, light mode.

---

## 5. Risks

- **In-place TOML writes**: verify early (phase 1.1) that the chosen Go TOML parser exposes
  byte positions. If not, fall back to a line-based patcher for simple `key = value` lines.
- **Halftone cost**: render once into a texture and redraw only on change.
- **Desktop layer input**: mask the background window to widget rects so it doesn't eat clicks.
- **Lock crashes**: niri keeps the session locked (red screen). Nested niri and a TTY fallback.
- **Two shells during development**: only one notification server and one polkit agent can exist
  per session. They sit on the shared session D-Bus, so a nested niri doesn't isolate them. Keep them
  off under `--dev`, and test them by running `dms kill`, testing nothin, then `dms run`. The lock is
  per compositor, so it does go in a nested niri.
- **Multi-monitor**: this laptop has one output (eDP-1). Multi-monitor behaviour can only be verified
  with an external monitor plugged in. Until then, phase notes mark it "untested" rather than "done".
- **Licence**: rebuild the look; don't copy code from "glyph" unless its licence allows.
