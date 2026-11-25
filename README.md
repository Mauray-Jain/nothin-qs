# nothin

A Nothing-style desktop shell for [niri](https://github.com/YaLTeR/niri): a
[Quickshell](https://quickshell.org) UI driven by a small Go daemon, `nothin`.
Dot-matrix type, monochrome by default, one red accent.

## What's in it

- **Rail** on every monitor (left by default): workspace dots, overview, the focused app,
  tray, Wi-Fi, Bluetooth, volume, battery, caffeine, notifications, settings, clock, power.
- **Wallpaper** drawn as a halftone dot field (or in colour, greyscale or plain), per monitor.
- **Desktop home**: a big dot clock, greeting, and weather, calendar, player and system
  widgets on a grid or wherever you drag them.
- **Notifications** with popups and a center, and **OSDs** for volume and brightness.
- **Launcher**: apps (most used first), open windows, a calculator, `:emoji`, `/files`,
  `?web search`. **Clipboard** history from cliphist.
- **Lock screen**, **idle** (fade, lock, screen off, suspend), lock before sleep, apps can
  keep the screen awake, and a **polkit** password prompt.
- **Settings deck** for the desktop, look and idle; everything also lives in one
  commented TOML file that nothin edits in place.

## Requirements

- niri, and Quickshell (`qs` on `PATH`)
- Go 1.24+ to build
- Optional, each for one feature (`nothin doctor` tells you what's missing):
  `brightnessctl` (brightness), `cliphist` and `wl-clipboard` (clipboard history and
  copying), `xdg-utils` (opening files and web searches), systemd (suspend, reboot).

## Install

```bash
make install            # builds build/nothin and installs it to ~/.local/bin
nothin setup            # writes ~/.config/nothin/config.toml and checks your system
```

Then, in `~/.config/niri/config.kdl` (nothin never edits it), start nothin instead of
your current shell:

```kdl
spawn-at-startup "nothin" "run"
spawn-at-startup "wl-paste" "--watch" "cliphist" "store"
```

and restart niri.

## Commands

```bash
nothin run              # start the shell (stays in the foreground as qs's parent)
nothin restart          # restart qs
nothin kill             # stop everything
nothin commands         # list every action, for your own keybinds or scripts
nothin ipc <target> <fn> [args]   # run one, e.g. nothin ipc launcher toggle
nothin doctor           # check qs, niri, the config and the optional tools
nothin setup            # first-run setup (safe to run again)
```

nothin suggests no keys; bind whichever you like to the commands `nothin commands`
prints.

## Settings

One file: `~/.config/nothin/config.toml`. Every key is optional and documented in
[docs/config.example.toml](docs/config.example.toml). nothin reloads it as soon as you
save. If a save has a mistake, a toast names the line and the last good settings stay.
The settings deck (the tune button on the rail) changes the same file in place, keeping
your comments.

Runtime data (launcher usage) is in `~/.local/state/nothin/`, the log in
`~/.local/state/nothin/nothin.log`.

## Developing

```bash
go build -o build/nothin ./cmd/nothin
build/nothin run --dev .              # QML from ./shell with live reload, next to another shell
build/nothin run --dev . --exclusive  # also the one-per-session services (stop the other shell first)
make test                             # go test ./... and qmltestrunner
make shaders                          # after editing shell/shaders/*.frag
```

Under `--dev` nothin leaves the notification server, polkit agent, idle, lock before
sleep and the screensaver service to the shell already running, since only one of each
can exist per session. `--exclusive` takes them. The plan is in
[docs/PLAN.md](docs/PLAN.md); each phase's notes and checks are in
[docs/PHASES.md](docs/PHASES.md).

## If something goes wrong

- `nothin doctor` first.
- If qs crashes three times within 10 seconds, nothin gives up; the reason is in the log.
- A crashed lock screen leaves niri locked (a red screen). Switch to a TTY
  (Ctrl+Alt+F3), log in, run `nothin restart` (or `pkill -x qs`), then switch back.

## Licence

MIT. Bundled fonts keep their own licences (Space Mono and Space Grotesk: OFL; Material
Symbols: Apache 2.0), and so does the emoji list (unicode-emoji-json: MIT); see
`shell/assets/`.
