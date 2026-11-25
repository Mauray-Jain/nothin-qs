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
- [ ] `pkill -x qs` three times quickly → nothin exits with "giving up"
- [ ] `build/nothin kill` stops nothin and `pgrep -x qs` finds no nothin qs

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
- [ ] Change `accent` in config.toml → the knob ring turns that colour when focused
