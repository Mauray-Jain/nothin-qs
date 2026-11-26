package config

import (
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"slices"
	"strings"
	"testing"
)

func TestLoad(t *testing.T) {
	tests := []struct {
		name     string
		doc      string
		wantLine int    // 0 means no error
		wantErr  string // substring of the error
		check    func(Config) bool
	}{
		{name: "empty uses defaults", doc: "",
			check: func(c Config) bool { return reflect.DeepEqual(c, Defaults()) }},
		{name: "starter file loads", doc: Starter,
			check: func(c Config) bool { return reflect.DeepEqual(c, Defaults()) }},
		{name: "rail defaults", doc: "",
			check: func(c Config) bool {
				return c.Rail.Position == "left" && c.Rail.Clock24h && c.Rail.Monitors != nil && len(c.Rail.Monitors) == 0
			}},
		{name: "rail monitors", doc: "[rail]\nmonitors = [\"eDP-1\", \"HDMI-A-1\"]\n",
			check: func(c Config) bool { return len(c.Rail.Monitors) == 2 && c.Rail.Monitors[1] == "HDMI-A-1" }},
		{name: "wallpaper defaults", doc: "",
			check: func(c Config) bool {
				w := c.Wallpaper
				return w.Dir == "~/Pictures/Wallpapers" && w.File == "" && w.Effect == "dots" &&
					w.DotSize == 17 && w.Light == 50 && w.Monitors != nil
			}},
		{name: "wallpaper per-monitor override", doc: "[wallpaper.monitors.\"HDMI-A-1\"]\neffect = \"none\"\n",
			check: func(c Config) bool {
				o := c.Wallpaper.Monitors["HDMI-A-1"]
				return o.Effect != nil && *o.Effect == "none" && o.File == nil
			}},
		{name: "bad effect", doc: "[wallpaper]\neffect = \"blur\"\n", wantLine: 2, wantErr: "wallpaper.effect"},
		{name: "dot size too small", doc: "[wallpaper]\ndot_size = 1\n", wantLine: 2, wantErr: "wallpaper.dot_size"},
		{name: "light out of range", doc: "[wallpaper]\nlight = 101\n", wantLine: 2, wantErr: "wallpaper.light"},
		{name: "bad override", doc: "[wallpaper.monitors.\"DP-1\"]\nlight = -5\n", wantLine: 2, wantErr: "wallpaper.monitors.DP-1.light"},
		{name: "desktop defaults", doc: "",
			check: func(c Config) bool {
				d := c.Desktop
				return d.Layout == "grid" && d.HeroClock && d.Greeting &&
					reflect.DeepEqual(d.Widgets, []string{"weather", "calendar", "player", "system"}) &&
					reflect.DeepEqual(d.System, []string{"cpu", "memory", "disk", "temperature"}) &&
					d.Positions != nil && d.Monitors != nil && c.Weather.Location == ""
			}},
		{name: "free positions", doc: "[desktop]\nlayout = \"free\"\npositions = { weather = [0.7, 0.1] }\n",
			check: func(c Config) bool { p := c.Desktop.Positions["weather"]; return len(p) == 2 && p[0] == 0.7 }},
		{name: "unknown widget", doc: "[desktop]\nwidgets = [\"weather\", \"stocks\"]\n", wantLine: 2, wantErr: "stocks"},
		{name: "duplicate widget", doc: "[desktop]\nwidgets = [\"player\", \"player\"]\n", wantLine: 2, wantErr: "twice"},
		{name: "unknown system item", doc: "[desktop]\nsystem = [\"gpu\"]\n", wantLine: 2, wantErr: "gpu"},
		{name: "bad layout", doc: "[desktop]\nlayout = \"masonry\"\n", wantLine: 2, wantErr: "desktop.layout"},
		{name: "position off screen", doc: "[desktop]\npositions = { player = [1.5, 0] }\n", wantLine: 2, wantErr: "desktop.positions"},
		{name: "position for unknown widget", doc: "[desktop]\npositions = { stocks = [0, 0] }\n", wantLine: 2, wantErr: "stocks"},
		{name: "launcher defaults", doc: "",
			check: func(c Config) bool { return c.Launcher.SearchURL == "https://duckduckgo.com/?q=%s" }},
		{name: "search url without %s", doc: "[launcher]\nsearch_url = \"https://example.com/\"\n", wantLine: 2, wantErr: "launcher.search_url"},
		{name: "search url not http", doc: "[launcher]\nsearch_url = \"file:///%s\"\n", wantLine: 2, wantErr: "launcher.search_url"},
		{name: "idle defaults", doc: "",
			check: func(c Config) bool {
				i := c.Idle
				return i.SuspendMode == "suspend" && i.Fade == 5 &&
					i.AC == IdleTimes{Lock: 300, ScreenOff: 600, Suspend: 0, LockScreenOff: 60} &&
					i.Battery == IdleTimes{Lock: 180, ScreenOff: 300, Suspend: 840, LockScreenOff: 60}
			}},
		{name: "bad suspend mode", doc: "[idle]\nsuspend_mode = \"sleep\"\n", wantLine: 2, wantErr: "idle.suspend_mode"},
		{name: "negative timeout", doc: "[idle.ac]\nlock = -1\n", wantLine: 2, wantErr: "idle.ac.lock"},
		{name: "fade too long", doc: "[idle]\nfade = 120\n", wantLine: 2, wantErr: "idle.fade"},
		{name: "display monitor", doc: "[display.monitors.\"eDP-1\"]\nscale = 2\nmode = \"2560x1440@165\"\nx = 0\ny = 0\ntransform = \"90\"\nvrr = true\n",
			check: func(c Config) bool {
				m := c.Display.Monitors["eDP-1"]
				return m.Scale != nil && *m.Scale == 2 && *m.Mode == "2560x1440@165" && *m.X == 0 && *m.Transform == "90" && *m.VRR && m.Enabled == nil
			}},
		{name: "display defaults", doc: "", check: func(c Config) bool { return c.Display.Monitors != nil && len(c.Display.Monitors) == 0 }},
		{name: "bad scale", doc: "[display.monitors.\"DP-1\"]\nscale = 20\n", wantLine: 2, wantErr: "display.monitors.DP-1.scale"},
		{name: "bad mode", doc: "[display.monitors.\"DP-1\"]\nmode = \"big\"\n", wantLine: 2, wantErr: "display.monitors.DP-1.mode"},
		{name: "auto mode", doc: "[display.monitors.\"DP-1\"]\nmode = \"auto\"\n", check: func(c Config) bool { return *c.Display.Monitors["DP-1"].Mode == "auto" }},
		{name: "mode without refresh", doc: "[display.monitors.\"DP-1\"]\nmode = \"1920x1080\"\n", check: func(c Config) bool { return true }},
		{name: "x without y", doc: "[display.monitors.\"DP-1\"]\nx = 10\n", wantLine: 2, wantErr: "x and y"},
		{name: "bad transform", doc: "[display.monitors.\"DP-1\"]\ntransform = \"45\"\n", wantLine: 2, wantErr: "transform"},
		{name: "niri unset by default", doc: "", check: func(c Config) bool { return c.Niri == (Niri{}) }},
		{name: "niri values", doc: "[niri]\ngaps = 8\nfocus_ring = false\nkeyboard_layout = \"us,de\"\ntouchpad_speed = 0.3\nmouse_accel = \"flat\"\n",
			check: func(c Config) bool {
				n := c.Niri
				return *n.Gaps == 8 && !*n.FocusRing && *n.KeyboardLayout == "us,de" && *n.TouchpadSpeed == 0.3 && *n.MouseAccel == "flat" && n.BorderWidth == nil
			}},
		{name: "niri gaps too big", doc: "[niri]\ngaps = 500\n", wantLine: 2, wantErr: "niri.gaps"},
		{name: "niri speed out of range", doc: "[niri]\nmouse_speed = 2\n", wantLine: 2, wantErr: "niri.mouse_speed"},
		{name: "niri bad accel", doc: "[niri]\nmouse_accel = \"fast\"\n", wantLine: 2, wantErr: "niri.mouse_accel"},
		{name: "niri layout with quotes", doc: "[niri]\nkeyboard_layout = \"us\\\"\"\n", wantLine: 2, wantErr: "niri.keyboard_layout"},
		{name: "bad rail position", doc: "[rail]\nposition = \"middle\"\n", wantLine: 2, wantErr: "rail.position"},
		{name: "value overrides default", doc: "[general]\nname = \"ada\"\n",
			check: func(c Config) bool { return c.General.Name == "ada" && c.Theme.Accent == "#d71921" }},
		{name: "syntax error", doc: "[general]\nname = \"ada\n", wantLine: 2},
		{name: "unknown key", doc: "[general]\n\nnmae = \"ada\"\n", wantLine: 3, wantErr: "nmae"},
		{name: "wrong type", doc: "[general]\nname = 3\n", wantLine: 2},
		{name: "bad colour", doc: "[theme]\naccent = \"red\"\n", wantLine: 2, wantErr: "theme.accent"},
		{name: "bad compositor", doc: "[general]\ncompositor = \"sway\"\n", wantLine: 2, wantErr: "general.compositor"},
		{name: "version too new", doc: "config_version = 2\n", wantLine: 1, wantErr: "config_version"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, err := Load([]byte(tt.doc))
			if tt.wantLine == 0 {
				if err != nil {
					t.Fatalf("unexpected error: %v", err)
				}
				if !tt.check(c) {
					t.Errorf("unexpected config %+v", c)
				}
				return
			}
			var le *Error
			if !errors.As(err, &le) {
				t.Fatalf("want *Error, got %v", err)
			}
			if le.Line != tt.wantLine {
				t.Errorf("line = %d, want %d (%v)", le.Line, tt.wantLine, err)
			}
			if !strings.Contains(err.Error(), tt.wantErr) {
				t.Errorf("error %q does not mention %q", err, tt.wantErr)
			}
		})
	}
}

// Each testdata/patch/<case>.in.toml is patched with the path and value named
// in its first line ("# set <path> <json value>") and compared to <case>.out.toml.
func TestPatch(t *testing.T) {
	ins, _ := filepath.Glob("testdata/patch/*.in.toml")
	if len(ins) == 0 {
		t.Fatal("no fixtures")
	}
	for _, in := range ins {
		name := strings.TrimSuffix(filepath.Base(in), ".in.toml")
		t.Run(name, func(t *testing.T) {
			doc, _ := os.ReadFile(in)
			want, _ := os.ReadFile(strings.Replace(in, ".in.", ".out.", 1))
			first, _, _ := strings.Cut(string(doc), "\n")
			f := strings.SplitN(strings.TrimPrefix(first, "# set "), " ", 2)
			got, err := Patch(doc, f[0], []byte(f[1]))
			if err != nil {
				t.Fatal(err)
			}
			if string(got) != string(want) {
				t.Errorf("got:\n%s\nwant:\n%s", got, want)
			}
		})
	}
}

func TestPatchRefusesInvalid(t *testing.T) {
	tests := []struct{ doc, path, value string }{
		{"[general]\nname = \"ada\n", "general.name", `"bob"`}, // file doesn't parse
		{"", "theme.accent", `"red"`},                          // value fails validation
		{"", "general.nope", `"x"`},                            // unknown key
		{"", "general.name", `{"a":1}`},                        // tables can't be set
	}
	for _, tt := range tests {
		if _, err := Patch([]byte(tt.doc), tt.path, []byte(tt.value)); err == nil {
			t.Errorf("Patch(%q, %s, %s) succeeded, want error", tt.doc, tt.path, tt.value)
		}
	}
}

// docs/config.example.toml must load, document every key, and show the defaults.
func TestExampleMatchesDefaults(t *testing.T) {
	doc, err := os.ReadFile("../../docs/config.example.toml")
	if err != nil {
		t.Fatal(err)
	}
	c, err := Load(doc)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(c, Defaults()) {
		t.Errorf("example values differ from defaults:\n got %+v\nwant %+v", c, Defaults())
	}
	for _, k := range keys(reflect.TypeOf(Config{}), nil) {
		if find(doc, k) == nil {
			t.Errorf("example does not set %s", strings.Join(k, "."))
		}
	}
	// Optional keys (unset by default) are shown as commented examples.
	for _, k := range optionalKeys(reflect.TypeOf(Config{}), nil) {
		if !strings.Contains(string(doc), "# "+k[len(k)-1]+" = ") {
			t.Errorf("example does not show %s as a commented example", strings.Join(k, "."))
		}
	}
}

// optionalKeys lists pointer fields of top-level sections, which have no default.
func optionalKeys(t reflect.Type, prefix []string) [][]string {
	var out [][]string
	for i := range t.NumField() {
		f := t.Field(i)
		p := append(slices.Clone(prefix), f.Tag.Get("toml"))
		switch {
		case f.Type.Kind() == reflect.Struct:
			out = append(out, optionalKeys(f.Type, p)...)
		case f.Type.Kind() == reflect.Pointer && len(prefix) == 1:
			out = append(out, p)
		}
	}
	return out
}

// keys lists the dotted path of every leaf field, from the toml tags.
func keys(t reflect.Type, prefix []string) [][]string {
	var out [][]string
	for i := range t.NumField() {
		f := t.Field(i)
		if f.Tag.Get("toml") == "-" || f.Type.Kind() == reflect.Pointer {
			continue
		}
		p := append(slices.Clone(prefix), f.Tag.Get("toml"))
		if f.Type.Kind() == reflect.Struct {
			out = append(out, keys(f.Type, p)...)
		} else {
			out = append(out, p)
		}
	}
	return out
}
