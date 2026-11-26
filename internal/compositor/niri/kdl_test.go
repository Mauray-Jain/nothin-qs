package niri

import (
	"reflect"
	"strings"
	"testing"
)

func TestParseKDL(t *testing.T) {
	nodes, err := parseKDL(`
a 1 "two" x=3 { b; c "d"; }
/-gone { x; }
e r#"raw "quoted""# // trailing
f /* inline */ g=null`)
	if err != nil {
		t.Fatal(err)
	}
	if len(nodes) != 3 {
		t.Fatalf("got %d nodes: %+v", len(nodes), nodes)
	}
	a := nodes[0]
	if a.Name != "a" || !reflect.DeepEqual(a.Args, []string{"1", "two"}) || a.Props["x"] != "3" || len(a.Children) != 2 {
		t.Errorf("a = %+v", a)
	}
	if a.Children[1].Name != "c" || a.Children[1].Args[0] != "d" {
		t.Errorf("c = %+v", a.Children[1])
	}
	if nodes[1].Args[0] != `raw "quoted"` {
		t.Errorf("raw string = %q", nodes[1].Args[0])
	}
	if v, ok := nodes[2].Props["g"]; !ok || v != "null" {
		t.Errorf("f props = %+v", nodes[2].Props)
	}
}

func TestParseKDLErrors(t *testing.T) {
	for _, src := range []string{`a { b`, `a "unterminated`} {
		if _, err := parseKDL(src); err == nil {
			t.Errorf("parseKDL(%q) should fail", src)
		}
	}
}

func TestReadBinds(t *testing.T) {
	c, err := ReadConfig("testdata/config/config.kdl")
	if err != nil {
		t.Fatal(err)
	}
	if !c.IncludesNothin {
		t.Error("the config includes nothin.kdl")
	}
	got := map[string]Bind{}
	for _, b := range c.Binds {
		got[b.Key] = b
	}
	if _, ok := got["Mod+Z"]; ok {
		t.Error("slashdash-commented binds must be skipped")
	}
	if _, ok := got["Mod+X"]; ok {
		t.Error("block-commented binds must be skipped")
	}
	for key, want := range map[string]Bind{
		"Mod+T":                {Key: "Mod+T", Action: `spawn "kitty"`, Title: "Open a Terminal: kitty", Group: "apps"},
		"Super+Alt+L":          {Key: "Super+Alt+L", Action: `spawn-sh "loginctl lock-session"`, Group: "apps"},
		"XF86AudioRaiseVolume": {Key: "XF86AudioRaiseVolume", Action: `spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+"`, Group: "apps"},
		"Mod+1":                {Key: "Mod+1", Action: "focus-workspace 1", Group: "workspaces"},
		"Mod+Shift+1":          {Key: "Mod+Shift+1", Action: "move-column-to-workspace 1", Group: "workspaces"},
		"Mod+Left":             {Key: "Mod+Left", Action: "focus-column-left", Group: "focus"},
		"Mod+Ctrl+Left":        {Key: "Mod+Ctrl+Left", Action: "move-column-left", Group: "move"},
		"Print":                {Key: "Print", Action: "screenshot", Group: "screenshots"},
		"Mod+Shift+E":          {Key: "Mod+Shift+E", Action: "quit", Group: "session"},
		"Mod+O":                {Key: "Mod+O", Action: "toggle-overview", Group: "windows"},
		"Mod+B":                {Key: "Mod+B", Action: `spawn "firefox"`, Group: "apps"}, // from an include
	} {
		if !reflect.DeepEqual(got[key], want) {
			t.Errorf("%s = %+v\n want %+v", key, got[key], want)
		}
	}
}

func TestConfigWithoutInclude(t *testing.T) {
	c, err := ReadConfigText(`binds { Mod+T { spawn "kitty"; } }`, ".")
	if err != nil || c.IncludesNothin || len(c.Binds) != 1 {
		t.Errorf("got %+v, %v", c, err)
	}
	if _, err := ReadConfigText(`binds { Mod+T {`, "."); err == nil || !strings.Contains(err.Error(), "config.kdl") {
		t.Errorf("a broken config should be reported: %v", err)
	}
}
