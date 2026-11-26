# Phase notes

Acceptance checks for each phase, written before the code (CLAUDE.md, "Test first").
Checks marked **untested on hardware** were written in a cloud container without
Quickshell or niri. Go and pure-QML tests there did run and pass; the Wayland side
still needs a run on the laptop.

## 1.0 Scaffold

Done when: `nothin run --dev .` shows an empty shell next to DMS; `nothin kill` stops it.

Automated: `go test ./...` covers the crash policy (3 exits within 10 s → give up),
restart-is-not-a-crash, and CLI argument handling.

Checked in the container with a stand-in `qs` script: single-instance guard, `restart`
starts a new qs, `ipc` passes `ipc --pid <qs pid> call …`, `kill` leaves no qs behind,
plain `run` extracts the embedded shell to `$XDG_RUNTIME_DIR/nothin/shell`.

Laptop check (**untested on hardware**):

```bash
go build -o build/nothin ./cmd/nothin
build/nothin run --dev .      # in a terminal, next to DMS
```

- [ ] `qs` starts with no QML errors in the terminal or `~/.local/state/nothin/nothin.log`
- [ ] DMS is still fully working
- [ ] `build/nothin restart` prints "restarting qs" and a new pid
- [ ] `kill $(cat $XDG_RUNTIME_DIR/nothin/qs.pid)` three times within 10 s → nothin exits
      with "giving up" (not `pkill -x qs`: that would kill DMS's qs too)
- [ ] `build/nothin kill` stops nothin, and `pgrep -af "qs -p"` lists no qs for nothin's `shell/`

## 1.1 Config daemon

Done when: editing the TOML changes a test label live; a syntax error shows a toast and
keeps the old value; a UI write keeps comments.

Risk from PLAN.md §5 resolved: go-toml/v2's `unstable` parser gives byte ranges for every
`key = value`, so saves replace just that span (`internal/config/patch.go`). No line-based
fallback needed.

How it fits together:
- `nothin run` owns `~/.config/nothin/config.toml` (writes `config.Starter` if missing) and
  serves JSON lines on `$XDG_RUNTIME_DIR/nothin/nothin.sock`, passed to qs as `NOTHIN_SOCKET`.
- Out: `{"type":"config","config":{…}}`, `{"type":"error","error":"config.toml line 3: …"}`.
  In: `{"type":"set","path":"general.name","value":"ada"}`.
- The file watch debounces 50 ms and ignores contents it has already seen, which covers
  its own writes. A broken file keeps the last good config; saves are refused until fixed.
- QML: `services/Daemon.qml` is the socket; `core/Config.qml` is a plain singleton
  (`values`, `loaded`, `set()`, `failed`), so it runs under `qmltestrunner`. Surfaces load
  only after the first config, so `Theme` fallbacks never show.
- `core/qmldir` is handwritten (Quickshell honours it, see `src/core/scan.cpp`) so the
  same singletons work in Quickshell and in `qmltestrunner`. Imports are relative.

Automated: `go test ./...` (load errors with line numbers, patch fixtures in
`internal/config/testdata/patch/`, the example file covering every key, and the hub over a
real socket and file watch). `qmltestrunner`: Config routing, Theme following config,
bundled fonts loading.

Checked in the container: the built binary over its real socket (set, hand edit, typo).

Laptop check (**untested on hardware**):

```bash
build/nothin run --dev .
build/nothin ipc testpage toggle      # page appears on every screen
build/nothin ipc testpage name        # prints general.name
```

- [ ] Change `name` in `~/.config/nothin/config.toml` and save → the page's "HELLO, …" changes
      and `nothin ipc testpage name` prints the new value
- [ ] Break the file (e.g. `name = "x`) → a toast top-right names the line; the page keeps the old name
- [ ] Fix it → the page updates again
- [ ] Type a name in the page's field and press Enter → the file changes only on the `name`
      line; all comments are still there
- [ ] With the file broken, Enter in the field → toast says to fix the file first

## 1.2 Design kit

Done when: a test page renders `16:55`, a 70% ring and a halftoned image.

Components in `shell/components/`: `DotText` (5×7 glyphs in `Glyphs.js`: digits, A–Z,
`: . - / % °`), `DotRing` (full ring or arc), `DotSpark`, `Card`, `Pill`, `Toggle`,
`Segmented`, `Knob`, `Halftone`. Every control works by mouse/touch (TapHandler or
MouseArea) and keyboard (Space/Enter, arrows), and shows a thin outline when focused.

Shader: `shell/shaders/halftone.frag` → `scripts/compile-shaders.sh` (or `make shaders`)
writes `halftone.frag.qsb` with `--qsbversion 64`, which loads on Qt 6.4 and newer.
`make build` fails if a committed `.qsb` is stale; it skips the check when `qsb` is missing.

Automated (`qmltestrunner`): glyph table shape and coverage, text layout and size, ring
lit count and dot positions (full ring and arc), sparkline levels, Toggle/Segmented/Pill/
Knob by mouse and keys, Card theming, Halftone wiring.

Not automated: the shader's pixels. Qt Quick falls back to its software renderer in the
container, which skips shaders, so a pixel test can't run there. `qsb` compiling it to
SPIR-V does catch GLSL errors.

Checked in the container: a screenshot of the kit (minus the halftone) from the same
components looked right.

Laptop check (**untested on hardware**): `build/nothin ipc testpage toggle`

- [ ] `16:55` in dots, white on the dark card
- [ ] Ring 70% lit, clockwise from twelve o'clock
- [ ] The gradient square is a dot field: big dots on the left (white), shrinking to
      none on the right (black)
- [ ] Toggle, GRID/FREE, CAFFEINE pill and the knob respond to mouse, touch and Tab + keys
      (the CAFFEINE pill only fills and empties here; real caffeine comes with the rail, 1.4)
- [ ] Change `accent` in config.toml → click the knob (or Tab to it): its ring turns that
      colour. The toast dot uses it too. (Checked on hardware: toast yes; knob fixed after)

## 1.3 Compositor layer

Done when: workspace and focus changes log correctly on every connected output.

How it fits together:
- `internal/compositor`: `Detect` asks the kernel who owns the `$WAYLAND_DISPLAY` socket
  (`SO_PEERCRED` → `/proc/<pid>/comm`), then falls back to `NIRI_SOCKET`, Hyprland's
  instance signature and `XDG_CURRENT_DESKTOP`. `general.compositor` overrides it.
  `Compositor` (the one deliberate interface, PLAN #23) has a single method, `Run`, and a
  compositor-neutral `State`.
- `internal/compositor/niri`: follows `niri msg --json event-stream`. Outputs come from
  `niri msg --json outputs` at start and on every `WorkspacesChanged` (that's how a
  hotplug shows up). Event shapes checked against the `niri-ipc` 26.4.0 crate source.
- The daemon broadcasts `{"type":"compositor","state":{…}}` and logs one line per visible
  change, e.g. `niri: HDMI-A-1* [1*!] | eDP-1 [1 2·] | focus: thunderbird "Inbox"`
  (`*` focused, `·` active, `!` urgent; `*` after an output name marks the focused output).
- QML: `services/Compositor.qml` (plain singleton: `focusedOutput`, `outputs`,
  `workspaces`, `windows`, `focusedWindow`, `workspacesOn(output)`).

Automated: `go test ./...` (detection, including a real socket owner lookup; a replay of
`testdata/events.jsonl` against a hand-written `testdata/state.json`; activate without
focus; focus to nothing; ignored and unknown events; outputs parsing; the log summary;
the hub sending state to new and late clients). `qmltestrunner`: the Compositor singleton.

Checked in the container: the built binary against a stand-in `niri` replaying the
fixture. The log showed each change; a late socket client got the final state with both
outputs.

Not done yet: no actions (switching workspaces) go to niri. The rail needs them in 1.4.

Laptop check (**untested on hardware**):

```bash
build/nothin run --dev .
tail -f ~/.local/state/nothin/nothin.log      # in a second terminal
build/nothin ipc testpage desktop
```

- [ ] The log says `nothin: compositor niri`
- [ ] Switching workspaces and focusing windows each add one `niri:` line that matches
      what you see
- [ ] `nothin ipc testpage desktop` prints the same outputs, workspaces and focus
- [ ] Opening and closing the overview doesn't break anything (it's tracked, not logged)
- [ ] With an external monitor: plug it in → its workspaces appear under its name, and
      focus moves between outputs correctly (**multi-monitor untested** until a second
      screen is available, PLAN.md §5)

## 1.4 Rail

Done when: the rail is on every monitor; clicking dots switches workspaces; tray icons
open their menus.

Decisions (asked before starting):
- `rail.position` = left | right | top | bottom, default left. `rail.monitors` (empty =
  all). `rail.clock_24h`, default true.
- Items, in order: overview, workspace dots, (space), focused app, tray, network,
  Bluetooth, volume, battery, caffeine, notifications bell, clock (with seconds, day,
  date), power.
- Dots: focused in accent, shown-on-this-monitor white, others grey, urgent blink.
- Power menu: suspend, log out (niri's own confirmation), reboot and shut down need a
  second press within 3 s. Lock joins in 1.10.
- The bell is only an icon until 1.7.

How it fits together:
- Actions: the shell sends `{"type":"action","action":"focus-workspace","id":3}` (also
  `toggle-overview`, `quit`). The daemon sends them on `$NIRI_SOCKET`, which accepts
  workspace ids (`niri msg` doesn't). Failures come back as a toast.
- Caffeine is a Wayland idle inhibitor, which niri honours. DMS's idle follows niri's,
  so it should respect it too until nothin's own idle (1.10).
- Network and Bluetooth sit behind a `Loader`, so a Quickshell without
  `Quickshell.Networking` or `Quickshell.Bluetooth` loses only that icon.
- The rail can't take keyboard focus (it would steal it from windows), so it is mouse
  and touch only. Keyboard access to its actions can come through `nothin ipc` binds.

Automated: `go test ./...` (rail settings; niri actions against a stand-in socket,
including niri's error reply; the hub routing actions). `qmltestrunner`: Clock formats,
`Config.onMonitor`, Compositor actions, Icon ligatures, WorkspaceDots (count, colours,
blink, click, orientation), RailClock lines, ConfirmPill (press, timeout, keys).

Checked in the container: a screenshot of a mock rail from the same parts, both
orientations.

Laptop check (**untested on hardware**). Run `build/nothin run --dev .`; DMS's bar stays
up, so both bars show.

- [ ] A black rail on the left of every monitor; windows tile beside it, not under it
- [ ] Dots match your workspaces on that monitor; clicking one switches to it; the
      focused one is red; open the overview from the top button (it turns red)
- [ ] Focused app's icon shows on the focused monitor's rail; hover → title
- [ ] Tray icons are grey; right click opens each menu; left click does the app's action
- [ ] Wi-Fi, Bluetooth, volume and battery icons match reality; hover shows details;
      click volume → mute; scroll on it → volume changes; click Bluetooth → toggles
- [ ] Caffeine: click → red; idle past your lock timeout → no lock; click again → normal
- [ ] Clock ticks every second; `clock_24h = false` under `[rail]` → 12-hour with AM/PM
- [ ] Power → menu; click outside closes it; REBOOT → "REBOOT? AGAIN", wait 3 s → back
      (don't press twice unless you mean it); LOG OUT → niri asks to confirm (press Esc)
- [ ] `position = "top"` (then `"right"`, `"bottom"`) under `[rail]` → the rail moves
      live; on top/bottom the app title shows beside its icon
- [ ] `monitors = ["eDP-1"]` → the rail shows only there (with a second monitor)
- [ ] If network or Bluetooth is missing, run `qs --version` and send it with the log

## 1.5 Wallpaper

Done when: the wallpaper renders as dots; effect settings apply live.

How it fits together:
- `[wallpaper]`: `dir`, `file`, `effect` (dots | color | mono | none), `dot_size` (4–64),
  `light` (0–100), and `[wallpaper.monitors."<name>"]` overrides of file, effect,
  dot_size and light (user decision: a `file` setting, newest image in `dir` when empty).
- The daemon resolves the image into `wallpaper.path` (and each override's `path`), so
  the shell never lists folders.
- `modules/wallpaper/Wallpaper.qml`: a background-layer window per monitor (namespace
  `nothin-wallpaper`). `Look.js` merges the shared settings with that monitor's override.
  The image goes through `ShaderEffectSource` into `Halftone`; `color` makes the dots take
  the image's colours (new `colorMode` in `halftone.frag`); `mono` is a greyscale image.

Decided unattended (change any of these by asking):
- With `file` empty, the newest image is picked when the config loads. A new file in the
  folder shows after the next config save or `nothin restart`, not instantly.
- The wallpaper is on every monitor. It has no `monitors` filter because
  `wallpaper.monitors` already holds the per-monitor overrides.
- `light` 50 leaves brightness as it is; 0 darkens fully, 100 brightens fully.
- Images are decoded at screen size (`sourceSize`) to keep memory down.
- `color` dots sit on the theme background, not on a dimmed copy of the image.

Automated: `go test ./...` (settings, ranges, override validation with line numbers,
image choice: newest image, relative/absolute/`~` file, override paths, empty folder;
the daemon resolving `path`). `qmltestrunner`: `Look.forOutput` merging, Halftone's
colour switch. `make check-shaders`: the new `.qsb` matches its source.

Not automated: the shader's pixels (no GPU in the container).

Laptop check (**untested on hardware**). DMS draws its own wallpaper on the same layer,
so under `--dev` either one can end up on top. Hide DMS's wallpaper for this check, or
look for nothin's at the edges while switching workspaces.

- [ ] With images in `~/Pictures/Wallpapers` and no `file` set → the newest one, as white
      dots on black
- [ ] `file = "<name>"` → that image; `effect = "color"` → coloured dots; `"mono"` →
      greyscale photo; `"none"` → the photo as is; each applies within a second of saving
- [ ] `dot_size = 8` → finer dots; `light = 80` → bigger dots; `light = 20` → smaller
- [ ] A typo like `effect = "blur"` → toast with the line; the wallpaper doesn't change
- [ ] With a second monitor: `[wallpaper.monitors."<name>"]` with `effect = "none"` →
      only that monitor shows the plain photo
- [ ] Switching workspaces and opening the overview doesn't flicker the wallpaper

## 1.6 Desktop home

Done when: a side-by-side screenshot with the reference frame, reviewed by the user;
widgets chosen from config; free mode renders positions from config.

How it fits together:
- `[desktop]`: `monitors`, `layout` (grid | free), `hero_clock`, `greeting`, `widgets`,
  `system` (user decision: CPU, memory, disk, temperature, each switchable), `positions`.
  `[weather]`: `location`.
- Go: `internal/sysstat` (CPU from /proc/stat with a 30-sample history, memory as
  MemTotal − MemAvailable, disk via statfs on /, temperature from hwmon or thermal zones)
  is published every 2 s. `internal/weather` (Open-Meteo; place names through its
  geocoding API; IP lookup when `location` is empty) is published every 15 min and on
  change. The hub replays the latest of each message type to a new shell.
- QML: `SysStats` and `Weather` singletons; `modules/desktop/` has `Hero`, the four cards,
  `Calendar.js` and `Layout.js`, and `Desktop.qml`: one bottom-layer window per monitor
  (namespace `nothin-desktop`), above the wallpaper and below windows. It respects the
  rail's space, and its input mask covers only the widget cards.

Decided unattended (change any of these by asking):
- Grid: a 3×3 grid inside a 30 px margin. The hero (clock, date, greeting) takes the two
  top-left cells; widgets fill the remaining cells in `widgets` order. Free mode: a widget
  with a position is one cell in size, placed at that fraction of the screen and kept on
  screen; widgets without one, and the hero, keep their grid spots.
- The hero clock follows `rail.clock_24h`; there is no separate setting.
- Greeting: morning 5–12, afternoon 12–17, evening 17–22, night otherwise, plus
  `general.name` when set.
- Weather in °C and km/h. With `location` empty, nothin sends your IP address to
  ipinfo.io once per refresh to find your city. Refreshes every 15 min, retries a minute
  after a failure, logs each new error once.
- Calendar starts on Monday; today is an accent circle.
- System: memory and disk as small dot rings, CPU as a dotted sparkline, temperature
  turns accent from 90 °C. Disk is the root filesystem.
- Player: the playing MPRIS player, else the first; art in greyscale; play/pause in accent.

Automated: `go test ./...` (settings validation; sysstat against fixture trees: CPU
idle/total and usage, memory, hwmon preferred over thermal zones, a CPU sensor over an
nvme one, no sensor; weather against a local HTTP server: place name, lat,lon, IP lookup,
unknown place, WMO codes; the hub replaying the latest of each type). `qmltestrunner`:
long date with ISO week, greeting, the feeds, calendar grids (incl. leap February), grid
and free placement, the cards' content rules.

Checked in the container: a screenshot of the hero and the weather, calendar and system
cards with sample data. It caught the hero colon sitting too close to the digits, now fixed.
Not checked: real Open-Meteo replies (the container's network blocks it), the player card
and the desktop window (Quickshell only).

Laptop check (**untested on hardware**):

- [ ] Hero top-left: `16:55` style dot clock with a blinking colon, the long date, and
      "GOOD …, NAME"
- [ ] Weather card: your city (or `location`), temperature, icon, condition, low/high
      within a minute of start. With `location = "Tokyo"` → Tokyo within 30 s
- [ ] Calendar: this month, today in red
- [ ] Player: play music → title, artist, art; the buttons work; play/pause is red
- [ ] System: CPU % and sparkline move; memory, disk and temperature look right.
      `system = ["cpu"]` → only CPU
- [ ] `widgets = ["player", "weather"]` → only those two, in that order
- [ ] `layout = "free"` with `positions = { weather = [0.6, 0.6] }` → weather moves
      there, the rest keep their spots
- [ ] Clicking empty desktop areas still reaches whatever is below (nothing breaks);
      windows cover the widgets
- [ ] The widgets don't sit under the rail
- [ ] Send a screenshot next to a frame of the video for the side-by-side review

## 1.7 Notifications, center, OSD

Done when: nothin's notifications and OSD work with DMS stopped.

How it fits together:
- Only one notification server can exist per session. `nothin run` always runs it;
  `nothin run --dev` runs it only with `--exclusive` (the shell sees
  `NOTHIN_EXCLUSIVE=1`). Stop DMS first: `dms kill`.
- `modules/notifications/Notifications.qml`: the server, up to 4 popups top-right on the
  focused monitor, and a center on the right listing everything since start (clear,
  close). `Notifs` singleton holds the list and unread count; the rail's bell turns red
  with a count and opens the center.
- `modules/osd/OsdWindow.qml`: volume (any change, from anywhere) and brightness levels
  as a dot bar near the bottom of the focused monitor. Brightness is set with
  `brightnessctl` (user decision) and read by the daemon from /sys/class/backlight 4×/s,
  since sysfs sends no file events; hardware brightness keys show the OSD too.
- IPC targets for keybinds: `volume up|down|mute`, `brightness up|down`,
  `media playPause|next|previous`, `notifications toggle|clear`.
- The error toast now follows the focused monitor (`Compositor.focusedScreen`).

Decided unattended (change any of these by asking):
- Popups: up to 4, newest on top; 5 s unless the app sets a timeout; critical ones stay
  until closed. A popup timing out leaves the notification in the center. New ones don't
  pop up while the center is open.
- The center keeps notifications only while nothin runs (not saved to disk yet).
- No do-not-disturb mode yet.
- Volume and brightness steps are 5%. Volume up/down also unmutes.
- With `acpi_video*` and another backlight present, the other one is read.

Automated: `go test ./...` (the `--exclusive` rule, backlight reading incl. device
choice). `qmltestrunner`: Notifs (order, unread, center, clear), Osd show/hide, Brightness
feed and steps (only changes after the first reading show the OSD), DotBar, popup
timeouts, NotificationCard (content, action buttons, close), `Compositor.focusedScreen`.

Checked in the container: a screenshot of two notification cards and the OSD bar. It
caught action pills that were invisible on the card, now fixed.

Laptop check (**untested on hardware**). The keys are yours to bind; nothin only offers
commands (`nothin commands` lists them): `nothin ipc volume up|down|mute`,
`nothin ipc brightness up|down`, `nothin ipc media playPause|next|previous`,
`nothin ipc notifications toggle`.

```bash
dms kill
build/nothin run --dev . --exclusive
notify-send "Hello" "from nothin"
notify-send -u critical "Battery" "5% left"
notify-send -t 0 "Sticky" "never expires"
```

- [ ] Each notification pops up top-right on the focused monitor; normal ones leave after
      ~5 s, the critical one (red dot) and the sticky one stay until ✕
- [ ] An app notification with buttons (e.g. a browser download) shows them; they work
- [ ] The rail bell turns red with "N new"; clicking it opens the center with all of
      them; CLEAR empties it; the bell goes back to normal
- [ ] Volume keys (and scrolling on the rail's volume icon) show the volume OSD; mute
      shows MUTE; brightness keys show the brightness OSD; media keys control the player
- [ ] Break config.toml → the toast appears on the monitor you're focused on
- [ ] Without `--exclusive` (and with DMS running): DMS still gets the notifications
- [ ] Afterwards: `build/nothin kill`, then `dms run`

## 1.8 Launcher core and clipboard

Done when: Mod+P and Mod+Shift+C equivalents work (as commands you bind yourself).

How it fits together:
- `modules/launcher/Launcher.qml`: an overlay on the focused monitor that takes the
  keyboard. One search box (`components/Picker.qml`) lists a calculator answer, then up
  to 8 apps, then up to 5 open windows. Enter launches the app, focuses the window
  (new niri action `focus-window`), or copies the answer with `wl-copy`.
- Ranking (`Rank.js`): name starts with the query > a word in it does > contains >
  generic name, keywords or id contain it > its letters in order. Ties go to the most
  used, then the name. An empty query lists apps by use.
- Frecency: the daemon keeps up to 20 launch times per app in
  `~/.local/state/nothin/launcher.json` (never in the TOML) and scores them 4/2/1/0.5 for
  today/this week/this month/older. Scores are sent at start and after each launch.
- Calculator (`Calc.js`): its own parser, never `eval`: `+ - * / % ^`, brackets, `sqrt
  abs round floor ceil sin cos tan log ln`, `pi`, `e`. A bare number isn't shown as a
  result.
- `modules/clipboard/Clipboard.qml`: `cliphist list` in the same Picker; Enter runs
  `cliphist decode <id> | wl-copy` (the id is an argument, not shell text).
- IPC: `launcher toggle`, `clipboard toggle`.

Decided unattended (change any of these by asking):
- The launcher and clipboard close with Escape or after a choice. Clicking outside them
  doesn't close them.
- Calculator results are copied, not typed into a window.
- The clipboard shows the latest 100 entries; images show as cliphist's text preview.
- Launches are only counted from nothin's launcher.

Automated: `go test ./...` (frecency weights and order, save/load, a missing or broken
file; the focus-window action; the hub recording a launch and publishing scores).
`qmltestrunner`: Calc (precedence, right-assoc `^`, unary minus, functions, constants,
rejects), Rank (tiers, ties, empty query, letters in order), Results order, Cliphist
parsing and filtering, Picker (typing, arrows, Enter, Escape, click, reset on new items),
Usage, `Compositor.focusWindow`.

Checked in the container: a screenshot of the Picker with a calculator answer, apps and a
window.

Laptop check (**untested on hardware**). Requires `cliphist` and `wl-clipboard`, with
`wl-paste --watch cliphist store` started by niri. Bind your own keys to
`nothin ipc launcher toggle` and `nothin ipc clipboard toggle`.

- [ ] `nothin ipc launcher toggle` opens the launcher on the focused monitor with the cursor in the box;
      Escape closes it; running it again toggles it
- [ ] Typing "fi" lists Files/Firefox-style matches with their icons; Enter launches the
      highlighted one; arrows and Tab move; clicking a row launches it
- [ ] After launching an app a few times, it rises to the top of the empty-query list and
      of its matches; `~/.local/state/nothin/launcher.json` exists
- [ ] "2*(3+4)" shows 14 first; Enter copies "14" (paste it somewhere)
- [ ] Typing part of an open window's title lists it as WINDOW; Enter focuses it
- [ ] `nothin ipc clipboard toggle` shows recent clipboard entries; typing filters them; Enter puts the
      entry back on the clipboard

## 1.9 Launcher extras

Done when: each mode is reachable from the launcher.

User decisions: prefixes; file search over the home folder minus hidden folders;
DuckDuckGo as the default web search.

- `:words` emoji: every word must be in the emoji's name; Enter copies the emoji. The
  list (1914 emoji) is `modules/launcher/EmojiData.js`, generated by
  `scripts/emoji-data.py` from the unicode-emoji-json npm package (MIT, licence in
  `shell/assets/`).
- `/name` files: the daemon indexes `~` (no hidden folders, no `node_modules`, up to 100k
  entries) at start and every 10 minutes, and answers `find` requests with up to 20
  paths: name starts with the query, then name contains it, then a folder above does;
  shorter paths first. Enter runs `xdg-open`.
- `?words` web search, and a "Search the web for …" row last on normal searches. Enter
  opens `launcher.search_url` with `%s` replaced by the words.

Decided unattended (change any of these by asking):
- Emoji show in the system's colour emoji font. The bundled fonts have no emoji, so this
  is the one place nothin relies on a system font.
- Emoji results stop at 40; file results at 20.
- A new file shows up in file search within 10 minutes, not instantly.

Automated: `go test ./...` (index skips hidden and node_modules and stops at its limit;
search ranking, case, limit; the hub answering `find` to the asker only; search_url
validation). `qmltestrunner`: the three prefixes, the web row, home shown as `~`,
FileSearch keeping only the latest reply.

Laptop check (**untested on hardware**):

```bash
build/nothin ipc launcher toggle
```

- [ ] `:fire` lists 🔥 and friends; Enter copies the emoji (paste it)
- [ ] `/` plus part of a file name lists matching files with their folder; Enter opens
      the file in its default app
- [ ] `?niri wayland` opens a DuckDuckGo search in your browser
- [ ] A normal search ends with "Search the web for …"

## 1.10 Lock, idle, polkit, D-Bus

Done when: locks and unlocks, idle timers fire, lock before suspend, polkit prompts appear.

User decisions: the plan's idle defaults; plain suspend; a 5 s fade; the lock screen shows
the date, greeting and battery as well as the clock and password field.

How it fits together:
- `--notifications` is now `--exclusive` (`NOTHIN_EXCLUSIVE=1`). It covers every
  one-per-session service: notification server, polkit agent, idle, lock before sleep and
  the screensaver inhibit service. `nothin run` always owns them; under `--dev` they stay
  with DMS unless `--exclusive` is given.
- Lock (`modules/lock/`): `WlSessionLock` on every monitor; the password field is on the
  monitor that had focus, the others show a dimmed clock. Checked with PAM's `login`
  stack. `nothin ipc lock lock`, LOCK in the power menu, idle, logind's lock-session and
  sleep all lock.
- Lock before sleep (`internal/dbus`, exclusive only): nothin holds a logind "delay"
  inhibitor; on PrepareForSleep it asks the shell to lock, waits until the shell reports
  the lock is up (at most 2 s), then lets sleep continue, and takes a new inhibitor after
  resume.
- Screensaver inhibit (`internal/dbus`, exclusive only): nothin owns
  `org.freedesktop.ScreenSaver`, so apps that ask to keep the screen awake (video
  players, browsers) pause idle. Apps that quit without releasing are forgotten.
- Idle (`modules/idle/`, exclusive only): `[idle.ac]` or `[idle.battery]` by UPower's
  power source. Fade to black for `idle.fade` seconds ending at the lock time (input
  cancels), screen off via niri, suspend with `idle.suspend_mode`, and screen off
  `lock_screen_off` seconds into a lock. Caffeine and other Wayland idle inhibitors pause
  it too.
- Polkit (`modules/polkit/`, exclusive only): Quickshell's agent with a password prompt on
  the focused monitor.

Decided unattended (change any of these by asking):
- The fade ends at the lock time, so it starts 5 s before it (never before 1 s).
- Screen off after lock doesn't respect inhibitors (a locked screen has nothing to watch).
- A wrong password shows "WRONG PASSWORD"; PAM's own limit shows "TOO MANY TRIES".
- The dot zero has no slash (it read like a 6).

Automated: `go test ./...` (idle settings; ScreenSaver Inhibit/UnInhibit on both paths,
a client leaving, the name already taken, all on a private dbus-daemon; the sleep
locker waiting for the lock or giving up; the hub's lock round trip, never replayed; the
power-off-monitors action; `--exclusive`). `qmltestrunner`: IdlePlan, LockState,
IdleInhibit, LockView (texts, Enter submits and clears, not while busy, no field on other
monitors).

Checked in the container: a screenshot of the lock view.

Laptop check (**untested on hardware**). A crashed lock keeps the session locked (niri
shows red). Ctrl+Alt+F3 gives a TTY; there, `nothin kill` (or `pkill -x qs` if nothin is
gone) and log back in. **Try the lock in a nested niri first:**

```bash
niri                              # from your session: opens a nested niri window
# inside its terminal:
build/nothin run --dev . --exclusive
build/nothin ipc lock lock
```

- [ ] Nested: the lock covers the nested window; a wrong password shows the error; the
      right one unlocks
- [ ] Real session, with DMS still running: `build/nothin ipc lock lock` → lock screen on
      every monitor, password field on the one you were on, battery at the bottom
- [ ] Power menu → LOCK locks; SUSPEND suspends, and the screen is locked on wake
- [ ] With DMS stopped (`dms kill`, then `build/nothin run --dev . --exclusive`):
  - [ ] Set `[idle.ac] lock = 20` → at ~15 s the screen fades; moving the mouse cancels;
        leaving it locks at 20 s
  - [ ] Play a video in a browser or mpv → no fade while it plays
  - [ ] Caffeine on the rail → no fade
  - [ ] `systemctl suspend` → locked on wake
  - [ ] `pkexec true` → nothin's AUTHENTICATION prompt; the right password works, CANCEL
        cancels
- [ ] Afterwards: `build/nothin kill`, then `dms run`

## 1.11 Settings deck

Done when: changing a setting in the UI updates the TOML and the shell.

User decisions: the deck opens from a rail button, SETTINGS in the power menu, and
`nothin ipc deck toggle`; the accent is picked from swatches or typed as hex.

- `modules/deck/`: `DeckView` with HOME, LOOK and IDLE; `Deck.qml` is the window on the
  focused monitor (Escape closes). Every control saves through `Config.set`, so the
  daemon patches config.toml in place (comments kept) and the change applies live.
- HOME: layout, hero clock, greeting, widgets (switching one on adds it at the end of the
  grid order), system rows, and a screen preview: drag a widget to place it. Dropping one
  saves `desktop.positions` (rounded to 1%) and switches to the free layout. RESET
  PLACES clears them.
- LOOK: accent (six swatches or `#rrggbb` + Enter), wallpaper effect, dot size and light
  (knobs save once you stop turning), rail position, 24-hour clock.
- IDLE: on AC and on battery, lock / screen off / suspend / off-when-locked from presets
  (off, 1m, 2m, 3m, 5m, 10m, 15m, 30m); fade; what suspend means.
- The config patcher can now write whole inline tables (`positions = { … }`).

Decided unattended (change any of these by asking):
- A value outside the presets (like the default 14 min battery suspend) shows nothing
  selected but is kept until you pick a preset.
- The swatches are Nothing red, orange, yellow, green, blue and white. The background
  colour is config-only.
- Dropping a widget saves the whole `positions` map. If your file uses
  `[desktop.positions]` tables instead of the inline form, the save is refused with a
  toast; use the inline form (the example file does).

Automated: `go test ./...` (inline tables, including the empty one and keeping a trailing
comment). `qmltestrunner`: nav, toggles, widget and system lists, drag-to-place, accent
swatch and hex (invalid hex not saved), effect, idle presets and the "nothing selected"
case, DeckState, Segmented with no selection.

Checked in the container: screenshots of all three pages.

Laptop check (**untested on hardware**):

- [ ] The tune button on the rail (and SETTINGS in the power menu, and
      `nothin ipc deck toggle`) opens the deck on the focused monitor; Escape closes it
- [ ] Each control changes the shell within a second, and `config.toml` changes only on
      that key; your comments stay
- [ ] HOME: drag a widget in the preview → it moves on the real desktop; the layout
      switches to FREE; RESET PLACES puts everything back
- [ ] LOOK: a swatch recolours accents everywhere; typing `#00aaff` + Enter works
- [ ] IDLE: pick 1m for lock on AC (with `--exclusive`) → it fades and locks after a
      minute

## 1.12 Setup and switch-over

Done when: the startup line is `nothin run`; DMS is no longer spawned.

User decision: nothin suggests no keybinds anywhere ("don't change keybinds, just make CLI
commands"). The plan's `nothin keybinds` became `nothin commands`, which lists every
`nothin ipc <target> <fn>`; everything stays a `nothin ipc` call. The bind snippets in
earlier phase notes were replaced with the commands.

- `nothin commands`: read from the `IpcHandler`s in the embedded QML, so it lists exactly
  what the shell offers (the dev test page is left out).
- `nothin doctor`: FAIL for what nothin can't run without (qs, niri, a broken config),
  warn for each optional helper with what it's for.
- `nothin setup`: writes the starter config if missing, runs doctor, and prints what's
  left by hand (the niri startup lines). It never edits niri's config.
- The 1.1–1.2 test page now loads only under `--dev`.
- README rewritten for installing, switching over and recovering.

Automated: `go test ./...` (IPC commands parsed from QML, incl. arguments and nested
braces; every real target listed, the test page not; doctor's FAIL/warn/ok and the broken
config line).

Checked in the container: `nothin commands` and `nothin setup` output.

Laptop check (**untested on hardware**): the switch-over.

```bash
make install
nothin setup                 # everything ok, or only warnings you accept
```

- [ ] In `~/.config/niri/config.kdl`, replace the DMS startup line with
      `spawn-at-startup "nothin" "run"` (plus the `wl-paste --watch cliphist store` line)
- [ ] Log out and in: the rail, wallpaper and desktop appear; DMS doesn't start
      (`pgrep -af dms` finds nothing)
- [ ] Notifications, idle lock and polkit prompts come from nothin
- [ ] Rollback if needed: put the DMS line back (DMS stays installed)

# Milestone 2

## 2.1 Dashboard and process list

Done when: the dashboard opens and its parts work; the process list shows and ends
processes.

User decisions: quick toggles, sliders, media and system stats beside the process list;
opens from a rail button and `nothin ipc dashboard toggle`; END with confirmation.

- `modules/dashboard/`: `Dashboard.qml` is a sheet sliding up from the bottom of the
  focused monitor (Escape closes). `DashboardView` holds Wi-Fi, Bluetooth, caffeine and
  do-not-disturb tiles, volume and brightness sliders, the player card, the system card
  and `ProcessCard`.
- Processes: `internal/procs` reads `/proc` (name, command, CPU share of the whole machine
  since the last sample, resident memory, owner). The daemon samples every 2 s only while
  a dashboard is open, and stops when that shell goes away. END (press twice) sends
  SIGTERM to one of your own processes; after an END, FORCE (press twice) sends SIGKILL.
  Others' processes are listed greyed, with no buttons; pid 1 is refused.
- Do-not-disturb (`Notifs.dnd`): no popups; notifications still go to the center.
- Caffeine moved into a `Caffeine` singleton so the rail and the dashboard share it.
- `ConfirmPill` moved to `components/` (the rail and the dashboard both use it).

Decided unattended (change any of these by asking):
- CPU is a share of the whole machine (100% = every core busy), not per core like `top`.
- The list shows the top 40.
- Do-not-disturb isn't saved; it resets when nothin restarts.
- The brightness slider never goes below 1%.

Automated: `go test ./...` (sampler on two fixture snapshots, a process that exits,
names with brackets; the hub's watch on/off and disconnect, ending a real child process,
refusing pid 1). `qmltestrunner`: Procs sorting and requests, DND and popups,
DotSlider (click, drag clamp, keys, owner-set value), DashboardView (tiles, DND,
volume slider, END only on your processes with confirmation, sort switch),
Brightness.set, Caffeine, DashboardState.

Checked in the container: a screenshot of the dashboard (fixed a clipped DND label and
invisible END pills).

Laptop check (**untested on hardware**):

- [ ] The dashboard button on the rail (or `nothin ipc dashboard toggle`) slides the sheet
      up on the focused monitor; Escape or the button again closes it
- [ ] Wi-Fi and Bluetooth tiles switch the radios; caffeine matches the rail's button
- [ ] Do-not-disturb on → `notify-send hi` shows no popup (with `--exclusive`), but the
      center lists it
- [ ] Volume and brightness sliders move the real levels (and show the OSD)
- [ ] The player card controls music
- [ ] Processes update every 2 s; CPU/MEM switches the order; END twice on something
      harmless (e.g. a spare `sleep 1000` in a terminal) ends it

## 2.2 Deck: DISPLAY, WINDOWS, INPUT, POWER, SHELL, cheatsheet

Done when: monitors change live from DISPLAY; WINDOWS/INPUT write nothin.kdl; the
cheatsheet shows your binds.

User decisions: DISPLAY covers scale, resolution and refresh, position and rotation,
on/off and VRR. WINDOWS covers gaps, borders, focus ring and corners; INPUT covers
keyboard, touchpad and mouse. The cheatsheet is read-only and shows your own binds.
POWER covers the power profile, battery info and a link to the idle settings.

How it fits together:
- DISPLAY writes `[display.monitors."<name>"]`. The daemon sends set fields to niri over
  its socket (one `Output` request each). It does this when the settings change, when a
  monitor is plugged in, and after niri reloads its own config, which resets live changes.
  Monitors that are off are listed too, so they can be turned back on.
- WINDOWS and INPUT write `[niri]`. Every key starts unset, and only keys you set go into
  `~/.config/niri/nothin.kdl` (rewritten when `[niri]` changes, never created while
  empty). They take effect only when your `config.kdl` ends with `include "nothin.kdl"`
  (niri 25.11+); until then the pages are read-only and show that line. × next to a
  setting removes it again (`null` removes a key from config.toml).
- niri merges included sections property by property, except touchpad and mouse, which
  an include replaces whole. So setting any touchpad option here replaces your own
  touchpad section; the INPUT page says so.
- The cheatsheet (`nothin ipc cheatsheet toggle`, or SHELL → SHOW CHEATSHEET) reads the
  binds from `config.kdl` and the files it includes, with a small KDL reader in Go,
  grouped as apps, windows, focus, move, workspaces, screenshots, session, other.
- `nothin doctor` warns when `nothin.kdl` isn't included.

Decided unattended (change any of these by asking):
- Scale presets 1, 1.25, 1.5, 1.75, 2, plus the current scale when it's something else.
- Rotation offers 0/90/180/270; flipped ones are config-only.
- Dragging a monitor snaps to the others' edges within 80 logical px and saves only the
  moved monitor's x and y.
- WINDOWS/INPUT presets: gaps 0/4/8/12/16/24, border off/1/2/4, ring width 1/2/4/6, corners
  0/6/12/20, repeat delay 200–800, rate 15–50, speeds −0.5…0.5 in quarters.
- The SHELL page has name, weather place and web search; everything else is on its own page.

Automated: `go test ./...` (display settings and validation; Output request JSON for every
field, Off alone, auto mode, no refresh; richer output parsing incl. off monitors; the
display applier's change/hotplug/reload/replug rules; `[niri]` settings and the
commented-example check; KDL reader incl. comments and raw strings; binds and includes
from a fixture; nothin.kdl for three fixtures, and that it parses back; writing nothin.kdl
only when needed; removing keys; doctor's include check). `qmltestrunner`: snapping, mode
lists, NiriConfig groups, every deck page's writes, read-only until included, clearing,
text fields, the cheatsheet's groups, key names and error.

Checked in the container: screenshots of DISPLAY, WINDOWS (read-only) and the cheatsheet.

Laptop check (**untested on hardware**):

- [ ] DISPLAY: scale 1.25 → applies within a second; reboot nothin → still applied;
      `niri msg action load-config-file` (or edit config.kdl) → nothin re-applies it
- [ ] Pick another resolution and rotation; turn VRR on (if supported)
- [ ] With a second monitor: drag it in ARRANGE → windows/cursor cross over where it
      snapped; turn it OFF and back ON from the page
- [ ] WINDOWS before the include: hint shown, controls dimmed; `nothin doctor` warns
- [ ] Add `include "nothin.kdl"` at the end of config.kdl → controls work; gaps 24 →
      niri's gaps change; × → back to your own value; `~/.config/niri/nothin.kdl` matches
- [ ] INPUT: keyboard layout `us,de` (+ Enter) → layout switching works; touchpad tap off
- [ ] SHELL → SHOW CHEATSHEET (or `nothin ipc cheatsheet toggle`) lists your binds; Escape
      closes it; editing config.kdl updates it
- [ ] POWER: profile switches (with power-profiles-daemon); battery numbers look right;
      IDLE SETTINGS jumps to the IDLE page

## 2.3 Wallpaper picker

Done when: choosing an image and effect in the picker changes the wallpaper.

User decision: a pick applies to every monitor; THIS MONITOR ONLY writes the focused
monitor's override instead.

- `nothin ipc picker toggle`, or LOOK → CHOOSE WALLPAPER (closes the deck). Opening asks
  the daemon for `wallpaper.dir`'s images, newest first.
- A large preview with the effect, the thumbnail strip, effect, dot-size and light
  controls, THIS MONITOR ONLY, and APPLY. The controls only preview; nothing is saved
  until APPLY or Enter. Left/Right move, Escape closes.
- APPLY writes `wallpaper.file` (just the name when it's inside the folder), `effect`,
  `dot_size` and `light`, or the same under `[wallpaper.monitors."<focused>"]`.

Decided unattended (change any of these by asking):
- The picker starts on the current wallpaper, with that monitor's effect settings.
- The preview scales the dots to roughly how they'll look full screen.
- Thumbnails are decoded small (280×176) to keep the strip quick.

Automated: `go test ./...` (image listing, newest first, case-insensitive extensions, a
missing folder; the hub's list reply). `qmltestrunner`: Apply.js (all monitors, this
monitor, a file outside the folder), the picker view (start position, arrows, Enter,
preview settings carried into the choice, thumbnail click, Escape, empty folder),
Wallpapers.

Checked in the container: a screenshot with generated images. The preview only shows
with no effect there; dots, color and mono need a GPU.

Laptop check (**untested on hardware**):

- [ ] `nothin ipc picker toggle` opens the picker on the focused monitor with your
      wallpapers, the current one selected
- [ ] Switching DOTS/COLOR/MONO/NONE and turning the knobs changes the preview only
- [ ] APPLY (or Enter) changes the wallpaper on every monitor and closes; config.toml has
      `file = "<name>"` and the effect keys under `[wallpaper]`
- [ ] With two monitors: THIS MONITOR ONLY + APPLY changes only the focused one
      (`[wallpaper.monitors."<name>"]` appears)
- [ ] LOOK → CHOOSE WALLPAPER opens it too

## 2.4 Screenshot annotator

Done when: a region screenshot can be annotated, copied and saved.

User decisions: grim plus nothin's own region picker over a frozen screen; Enter copies,
Ctrl+S also saves to `snip.dir` (`~/Pictures/Screenshots`).

- `nothin ipc snip region`: grim captures the focused monitor first, then the capture
  is shown full screen. Drag an area (Enter takes the whole screen, Escape cancels).
  `nothin ipc snip screen` goes straight to the annotator.
- Annotator: pen, arrow, box, text and blur, in accent, white or black. Keys: P A R T B
  for the tools, Ctrl+Z undo, Enter copy, Ctrl+S save (and copy), Escape cancel. Text: click,
  type, Enter.
- Blur pixelates in 40-pixel blocks: the area is drawn tiny and stretched back, which
  needs no shader and makes text unreadable.
- The result is the captured pixels at full resolution (scaled monitors included), copied
  with `wl-copy -t image/png`, and saved as `nothin-YYYY-MM-DD-HHMMSS.png`.

Decided unattended (change any of these by asking):
- Line width 4 px; text 22 px Space Grotesk.
- The capture covers the whole focused monitor, including the rail.
- Captures live in `$XDG_RUNTIME_DIR/nothin/` and the previous one is deleted on the next.

Automated: `go test ./...` (`snip.dir`, its ~ expansion, doctor's grim check).
`qmltestrunner`: geometry and file names, the region view (drag either way, a click isn't
a selection, Enter, Escape), every tool, undo, tool and colour keys, Enter committing text
without copying, tool keys after text (a focus bug this caught), Enter/Ctrl+S/Escape, and
that export is full resolution.

Checked in the container: a screenshot of the annotator with every kind of annotation.

Laptop check (**untested on hardware**). Needs `grim` and `wl-clipboard`.

- [ ] `nothin ipc snip region` freezes the focused monitor; drag an area → annotator
- [ ] Draw with each tool; B blurs (unreadable); Ctrl+Z undoes; Enter → paste into an
      app: the annotated image at full sharpness
- [ ] Ctrl+S → `~/Pictures/Screenshots/nothin-….png` exists and is on the clipboard
- [ ] `nothin ipc snip screen` skips the selection; Escape at any step cancels
- [ ] On a scaled monitor (e.g. 1.5) the saved image is the monitor's full pixel size

## 2.5 Matugen colours

Done when: with `theme.mode = "matugen"` the accent (or the palette) follows the wallpaper.

User decision: both as options: `theme.matugen = "accent"` (default: only the accent; the
black-and-grey look stays) or `"full"` (accent plus tinted background and cards).

- `[theme] mode = "mono" | "matugen"`, `matugen = "accent" | "full"`; LOOK → COLOURS and
  TAKE FROM WALLPAPER.
- The daemon runs `matugen image <wallpaper> --json hex --dry-run --mode dark
  --source-color-index 0`. It retries without the index flag on versions that lack it.
  It doesn't touch your matugen templates or set the wallpaper. It reads matugen 4.x,
  4.x `--old-json-output` and pre-4.0 output. It runs again only when the mode or the
  wallpaper changes.
- Colours used (dark scheme): accent ← `primary`; with "full", background ← `surface`,
  cards ← `surface_container`, raised cards ← `surface_container_high`.
- If matugen is missing or fails, a toast says why and the configured colours stay.
- Text on the accent switches to dark when the accent is light (matugen's dark-scheme
  primaries usually are), e.g. today in the calendar.

Decided unattended (change any of these by asking):
- Always the dark scheme, and the most dominant colour (index 0).
- With per-monitor wallpapers, colours come from the shared wallpaper.
- Text colours stay white and greys in both scopes.

Automated: `go test ./...` (parsing all three matugen JSON shapes and junk; retrying
without the flag; matugen's error text; no wallpaper; the watcher running matugen only
when the mode or image changes, and falling back on failure). `qmltestrunner`: Theme in
mono, accent and full modes, the fallback, readable text on the accent, the LOOK controls.

Checked in the container: a screenshot of the hero and calendar with a sample palette
(caught white-on-light-blue in the calendar; fixed with Theme.textOnAccent, which also
exposed that a QML property named `onAccent` silently doesn't work).

Laptop check (**untested on hardware**). Needs `matugen`.

- [ ] LOOK → COLOURS: FROM WALLPAPER → accents (focused workspace dot, today, toggles)
      take the wallpaper's colour within a couple of seconds
- [ ] TAKE FROM WALLPAPER: ACCENT + CARDS → the desktop, cards and deck take its tint
- [ ] Pick another wallpaper → the colours follow
- [ ] Without matugen installed: a toast says so; colours stay as configured
- [ ] Back to MONO → the configured accent returns
