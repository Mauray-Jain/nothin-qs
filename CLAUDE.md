# nothin

A Nothing-style desktop shell: Quickshell (QML) UI plus a Go CLI/daemon (`nothin`), niri first.
The full plan and every design decision live in [docs/PLAN.md](docs/PLAN.md). Read it before starting a phase.

## Core rule: simplest thing that works

Occam's razor. Build the plainest version that meets the current phase's "done when" line, then stop.

- No abstraction until there is a second real use. The one exception is the `Compositor`
  interface, which is a deliberate decision (docs/PLAN.md #23).
- No options, flags or config keys that nothing asks for yet.
- No caching, pooling or micro-optimisation without a measured problem.
- Prefer deleting code to adding code. Prefer one file to three.
- When two approaches both work, pick the one with fewer moving parts.

## Folder structure

Keep the repo root clean. Unlike many Go projects, nothing gets dumped at the top level.

**The root holds only:**
- `go.mod` and `go.sum` (Go requires them there)
- `Makefile`, `README.md`, `LICENSE`, `CLAUDE.md`, `CLAUDE.local.md`, `.gitignore`

Anything else goes in a folder. Adding a new top-level file or folder needs a reason that fits none of the existing folders.

| Folder | Holds |
|---|---|
| `cmd/nothin/` | `main.go` only: parse args, call into `internal/`. No logic |
| `internal/` | All Go logic, one package per concern: `cli`, `config`, `daemon`, `compositor` (with `niri/` under it), `dbus` |
| `shell/` | All QML. `embed.go` is its only Go file |
| `shell/core/` | `Theme.qml`, `Config.qml` |
| `shell/components/` | Reusable visuals |
| `shell/shaders/` | Shader sources plus their compiled `.qsb` files (committed) |
| `shell/assets/` | Bundled fonts (and any other static files the shell loads) |
| `shell/services/` | Data singletons |
| `shell/modules/<surface>/` | One folder per on-screen surface (`rail/`, `lock/`, `deck/`…) |
| `docs/` | `PLAN.md`, `config.example.toml`, user docs |
| `packaging/` | AUR / systemd files |
| `scripts/` | Dev helpers |

**Rules:**
- No `pkg/`, `utils/`, `common/`, `helpers/` or `misc/` grab-bags. A helper lives in the package that uses it. If two packages need it, it gets a package named for what it does.
- A package or folder name says what it is. Files are named for their main type or purpose.
- Go tests (`*_test.go`) sit next to the code they test. Test fixtures go in that package's `testdata/`.
- QML tests (`tst_*.qml`) go in a `tests/` folder inside the area they test (e.g. `shell/components/tests/`). This is the one allowed extra sub-folder per area.
- One QML component per file. A surface that grows past one file gets its own folder under `shell/modules/`.
- Generated or build output (`build/`, compiled binaries) is never committed and never lands in the root.
- Keep nesting shallow. Add a sub-folder only when a folder has several files that clearly form a group.

## Conventions

- **Config.** `~/.config/nothin/config.toml` is the only settings file.
  - Defaults live in Go. A new key needs a default, validation and an entry in `docs/config.example.toml`.
  - QML reads settings only through the `Config` singleton and writes only through `Config.set(path, value)`. It never touches the file.
  - Keys are `snake_case`.
- **State.** Runtime data (history, usage counts) goes in `~/.local/state/nothin/`, never in the TOML.
- **Theme.** Colours, fonts, radii and durations come from `Theme.qml`. No hardcoded colours in modules.
- **Compositor.** QML never calls `niri` directly; go through the `Compositor` service.
- **Personal values.** Name, city and paths belong in config, never in code.
- **Multi-monitor.** Build every surface as `Variants` over screens, filtered by the component's `monitors` setting.
- **Binds.** nothin never writes user keybinds. It only suggests them (`nothin keybinds`).
- **Fonts and icons.** Use the bundled Space Mono, Space Grotesk and Material Symbols (weight 300) through `Theme`. Never rely on system fonts.
- **Shaders.** After editing a `.frag`, recompile with the `scripts/` helper and commit the `.qsb` together with the source.

## Dependencies

Standard library first. Add a Go package only when it clearly simplifies the code more than it
costs in weight and maintenance. Say why in the commit message. Expected set: `go-toml/v2`,
`fsnotify`, `godbus/dbus`. The CLI uses the standard `flag` package.

## Git

- Commit to `main` at the end of each phase without asking, and tag each milestone (`m1`, `m2`, …).
- Never push unless the user asks.

## Test first, then implement

Every change starts with a test or check that fails, then the code that makes it pass.

- **Go.** Red-green.
  1. Write a failing `*_test.go`.
  2. Run it and watch it fail.
  3. Implement until it passes.

  No production code without a failing test that asks for it. Prefer small table-driven tests, with fixtures in `testdata/`.
- **Pure QML and JS.** This covers components such as DotText and DotRing, layout math and formatters. Write a Qt Quick Test `tst_*.qml` first, then the component.
- **Wayland surfaces** (rail, lock, desktop…). These can't run under `qmltestrunner`.
  1. Before coding, write the phase's acceptance check in the phase notes: a `nothin ipc` state query where one exists, otherwise a screenshot checklist.
  2. Implement.
  3. Run the check.
- **Keep tests simple.** Tests are as simple as the code they test; Occam's razor applies to them too. No mocks of Quickshell types, and no test tools beyond `go test` and `qmltestrunner`.

```bash
go test ./...
/usr/lib/qt6/bin/qmltestrunner -input shell/
```

## Running (planned, see docs/PLAN.md 1.0)

```bash
go build -o build/nothin ./cmd/nothin
build/nothin run --dev .      # live-reload QML from the repo, alongside DMS
build/nothin kill
build/nothin ipc <target> <fn> [args]
```

While DMS is still running, keep nothin's notification server and polkit agent disabled under
`--dev`. Only one of each can exist per session, and a nested niri shares the session D-Bus.
To test them, run `dms kill`, test nothin, then `dms run`. Lock work goes in a nested niri.

## Safety

- Test lock-screen changes in a nested niri (`niri` launched inside a window) before the real
  session. A crashed lock keeps the session locked; the TTY (Ctrl+Alt+F3) is the fallback.
- Don't edit the user's `~/.config/niri/config.kdl`. nothin may only generate `~/.config/niri/nothin.kdl`.
