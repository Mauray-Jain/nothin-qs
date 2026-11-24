# nothin

A Nothing-style desktop shell for [niri](https://github.com/YaLTeR/niri): a
[Quickshell](https://quickshell.org) UI driven by a small Go daemon, `nothin`.

Work in progress. The plan is in [docs/PLAN.md](docs/PLAN.md).

## Requirements

- niri
- Quickshell (`qs` on `PATH`)
- Go 1.24+ to build

## Build and run

```bash
make install            # builds build/nothin, installs to ~/.local/bin
nothin run              # start the shell (QML embedded in the binary)
nothin run --dev .      # from a checkout: load QML from ./shell, live reload
nothin restart          # restart qs
nothin kill             # stop everything
nothin ipc <target> <fn> [args]
```

`nothin run` stays in the foreground as the parent of `qs`. If `qs` crashes it is
restarted; after 3 crashes within 10 seconds nothin gives up. The log is
`~/.local/state/nothin/nothin.log`.

To start it with niri, add to `~/.config/niri/config.kdl`:

```kdl
spawn-at-startup "nothin" "run"
```

## Licence

MIT. Bundled fonts keep their own licences (see `shell/assets/fonts/`).
