package cli

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor/niri"
	"github.com/Mauray-Jain/nothin-qs/internal/config"
	"github.com/Mauray-Jain/nothin-qs/internal/daemon"
)

type doctorEnv struct {
	lookPath   func(string) (string, error)
	getenv     func(string) string
	configPath string
	niriConfig string
}

func realDoctorEnv() doctorEnv {
	return doctorEnv{lookPath: exec.LookPath, getenv: os.Getenv, configPath: daemon.ConfigPath(), niriConfig: niri.ConfigPath()}
}

// Helpers nothin uses; missing ones only switch off what they're for.
var optionalTools = []struct{ name, forWhat string }{
	{"brightnessctl", "brightness keys and the brightness OSD"},
	{"cliphist", "clipboard history"},
	{"wl-copy", "copying from the launcher and clipboard"},
	{"wl-paste", "recording clipboard history (wl-paste --watch cliphist store)"},
	{"xdg-open", "opening files and web searches from the launcher"},
	{"systemctl", "suspend, reboot and shut down"},
}

// doctor checks what nothin needs. ok is false only if something it can't
// run without is missing; optional tools are warnings.
func doctor(env doctorEnv) (report string, ok bool) {
	var b strings.Builder
	ok = true
	line := func(status, name, detail string) {
		fmt.Fprintf(&b, "%-4s %-13s %s\n", status, name, detail)
		if status == "FAIL" {
			ok = false
		}
	}

	if p, err := env.lookPath("qs"); err == nil {
		line("ok", "qs", p)
	} else {
		line("FAIL", "qs", "Quickshell's qs is not on PATH; install quickshell")
	}

	if s := env.getenv("NIRI_SOCKET"); s != "" {
		line("ok", "niri", s)
	} else {
		line("FAIL", "niri", "NIRI_SOCKET is not set; run nothin inside a niri session")
	}

	switch b2, err := os.ReadFile(env.configPath); {
	case errors.Is(err, fs.ErrNotExist):
		line("ok", "config", env.configPath+" (not created yet; nothin run or nothin setup writes it)")
	case err != nil:
		line("FAIL", "config", err.Error())
	default:
		if _, err := config.Load(b2); err != nil {
			line("FAIL", "config", env.configPath+" "+err.Error())
		} else {
			line("ok", "config", env.configPath)
		}
	}

	if c, err := niri.ReadConfig(env.niriConfig); err != nil {
		line("warn", "niri config", err.Error())
	} else if c.IncludesNothin {
		line("ok", "nothin.kdl", "included by "+env.niriConfig)
	} else {
		line("warn", "nothin.kdl", `not included: the deck's WINDOWS and INPUT pages are read-only until `+
			env.niriConfig+` ends with  include "nothin.kdl"`)
	}

	for _, t := range optionalTools {
		if p, err := env.lookPath(t.name); err == nil {
			line("ok", t.name, p)
		} else {
			line("warn", t.name, "not found: no "+t.forWhat)
		}
	}
	return b.String(), ok
}

// setup writes the starter config if there is none, runs doctor, and says
// what is left to do by hand. It never edits niri's config.
func setup(env doctorEnv) (string, bool) {
	var b strings.Builder
	if _, err := os.Stat(env.configPath); errors.Is(err, fs.ErrNotExist) {
		os.MkdirAll(filepath.Dir(env.configPath), 0o755)
		if err := os.WriteFile(env.configPath, []byte(config.Starter), 0o644); err != nil {
			return "nothin: " + err.Error() + "\n", false
		}
		b.WriteString("wrote " + env.configPath + "\n\n")
	}
	report, ok := doctor(env)
	b.WriteString(report)
	b.WriteString(`
Left for you (nothin never edits your niri config):
  1. In ~/.config/niri/config.kdl, replace the line that starts DMS with
         spawn-at-startup "nothin" "run"
  2. For clipboard history, also start
         spawn-at-startup "wl-paste" "--watch" "cliphist" "store"
  3. Restart niri (or log out and in).

Every action nothin offers: nothin commands
All settings: docs/config.example.toml in the nothin repo, or the settings deck.
`)
	return b.String(), ok
}
