package niri

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Bind is one key binding from the user's niri config.
type Bind struct {
	Key    string `json:"key"`
	Action string `json:"action"` // the first action, e.g. `spawn "kitty"`
	Title  string `json:"title"`  // hotkey-overlay-title, if any
	Group  string `json:"group"`  // apps | workspaces | focus | move | windows | screenshots | session | other
}

// Config is what nothin reads from the user's niri config.
type Config struct {
	Binds          []Bind `json:"binds"`
	IncludesNothin bool   `json:"includes_nothin"` // the config includes nothin.kdl
}

// ConfigPath is $NIRI_CONFIG, else ~/.config/niri/config.kdl.
func ConfigPath() string {
	if p := os.Getenv("NIRI_CONFIG"); p != "" {
		return p
	}
	d, err := os.UserConfigDir()
	if err != nil {
		d = filepath.Join(os.Getenv("HOME"), ".config")
	}
	return filepath.Join(d, "niri", "config.kdl")
}

// ReadConfig reads path and the files it includes (one level deep).
func ReadConfig(path string) (Config, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return Config{}, err
	}
	return ReadConfigText(string(b), filepath.Dir(path))
}

func ReadConfigText(src, dir string) (Config, error) {
	nodes, err := parseKDL(src)
	if err != nil {
		return Config{}, fmt.Errorf("niri config.kdl %w", err)
	}
	c := Config{Binds: []Bind{}}
	collect(&c, nodes)
	home, _ := os.UserHomeDir()
	for _, n := range nodes {
		if n.Name != "include" || len(n.Args) == 0 {
			continue
		}
		p := n.Args[0]
		if filepath.Base(p) == "nothin.kdl" {
			c.IncludesNothin = true
			continue
		}
		if strings.HasPrefix(p, "~/") {
			p = filepath.Join(home, p[2:])
		} else if !filepath.IsAbs(p) {
			p = filepath.Join(dir, p)
		}
		b, err := os.ReadFile(p)
		if err != nil {
			continue // an optional include that doesn't exist
		}
		if inc, err := parseKDL(string(b)); err == nil {
			collect(&c, inc)
		}
	}
	return c, nil
}

func collect(c *Config, nodes []node) {
	for _, n := range nodes {
		if n.Name != "binds" {
			continue
		}
		for _, b := range n.Children {
			if len(b.Children) == 0 {
				continue
			}
			act := b.Children[0]
			action := act.Name
			for _, a := range act.Args {
				if strings.ContainsAny(a, " \"") || a == "" || act.Name == "spawn" || act.Name == "spawn-sh" {
					a = fmt.Sprintf("%q", a)
				}
				action += " " + a
			}
			title := b.Props["hotkey-overlay-title"]
			if title == "null" {
				title = ""
			}
			c.Binds = append(c.Binds, Bind{Key: b.Name, Action: action, Title: title, Group: group(act.Name)})
		}
	}
}

func group(action string) string {
	switch {
	case strings.HasPrefix(action, "spawn"):
		return "apps"
	case strings.Contains(action, "workspace"):
		return "workspaces"
	case strings.HasPrefix(action, "focus-"):
		return "focus"
	case strings.HasPrefix(action, "move-"):
		return "move"
	case strings.HasPrefix(action, "screenshot"):
		return "screenshots"
	case action == "quit" || action == "power-off-monitors" || action == "suspend":
		return "session"
	case strings.Contains(action, "window") || strings.Contains(action, "column") || strings.Contains(action, "overview") ||
		strings.Contains(action, "fullscreen") || strings.Contains(action, "maximize") || strings.Contains(action, "floating"):
		return "windows"
	}
	return "other"
}
