package cli

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestDoctor(t *testing.T) {
	dir := t.TempDir()
	cfg := filepath.Join(dir, "config.toml")
	os.WriteFile(cfg, []byte("[general]\nname = \"ada\n"), 0o644) // broken on line 2
	have := map[string]bool{"qs": true, "wl-copy": true, "systemctl": true}
	niriCfg := filepath.Join(dir, "config.kdl")
	os.WriteFile(niriCfg, []byte("binds { Mod+T { spawn \"kitty\"; } }\n"), 0o644)
	env := doctorEnv{
		niriConfig: niriCfg,
		lookPath: func(name string) (string, error) {
			if have[name] {
				return "/usr/bin/" + name, nil
			}
			return "", errors.New("not found")
		},
		getenv:     func(k string) string { return map[string]string{"NIRI_SOCKET": ""}[k] },
		configPath: cfg,
	}
	out, ok := doctor(env)
	if ok {
		t.Error("doctor should fail without niri and with a broken config")
	}
	for _, want := range []string{
		"ok   qs",
		"FAIL niri",
		"FAIL config",
		"line 2",
		"warn cliphist",
		"clipboard history",
		"warn brightnessctl",
		"warn nothin.kdl",
		`include "nothin.kdl"`,
	} {
		if !strings.Contains(out, want) {
			t.Errorf("doctor output misses %q:\n%s", want, out)
		}
	}

	os.WriteFile(cfg, []byte("[general]\nname = \"ada\"\n"), 0o644)
	os.WriteFile(niriCfg, []byte("include \"nothin.kdl\"\n"), 0o644)
	if out, _ := doctor(env); !strings.Contains(out, "ok   nothin.kdl") {
		t.Errorf("include not seen:\n%s", out)
	}
	env.getenv = func(k string) string { return map[string]string{"NIRI_SOCKET": "/run/niri.sock"}[k] }
	if _, ok := doctor(env); !ok {
		t.Error("only warnings left: doctor should pass")
	}
}

func TestMainKnowsNewCommands(t *testing.T) {
	for _, c := range []string{"commands"} {
		if got := Main([]string{c}, os.Stderr); got != 0 {
			t.Errorf("nothin %s exit = %d", c, got)
		}
	}
}
