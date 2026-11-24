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
