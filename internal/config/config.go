// Package config holds nothin's settings: defaults, loading, validation and
// in-place edits of config.toml.
package config

import (
	"bytes"
	"errors"
	"fmt"
	"regexp"
	"slices"
	"strings"

	"github.com/pelletier/go-toml/v2"
)

// Version is the config_version this nothin writes and understands.
const Version = 1

type Config struct {
	ConfigVersion int       `toml:"config_version" json:"config_version"`
	General       General   `toml:"general" json:"general"`
	Theme         Theme     `toml:"theme" json:"theme"`
	Rail          Rail      `toml:"rail" json:"rail"`
	Wallpaper     Wallpaper `toml:"wallpaper" json:"wallpaper"`
}

type General struct {
	Name       string `toml:"name" json:"name"`
	Compositor string `toml:"compositor" json:"compositor"` // auto | niri
}

type Theme struct {
	Accent     string `toml:"accent" json:"accent"`
	Background string `toml:"background" json:"background"`
}

type Rail struct {
	Position string   `toml:"position" json:"position"` // left | right | top | bottom
	Monitors []string `toml:"monitors" json:"monitors"` // empty = every monitor
	Clock24h bool     `toml:"clock_24h" json:"clock_24h"`
}

func Defaults() Config {
	return Config{
		ConfigVersion: Version,
		General:       General{Compositor: "auto"},
		Theme:         Theme{Accent: "#d71921", Background: "#000000"},
		Rail:          Rail{Position: "left", Monitors: []string{}, Clock24h: true},
		Wallpaper: Wallpaper{
			Dir: "~/Pictures/Wallpapers", Effect: "dots", DotSize: 17, Light: 50,
			Monitors: map[string]WallpaperOverride{},
		},
	}
}

// Starter is written on first run.
const Starter = `# nothin settings. Every key is optional; defaults apply to anything left out.
# All keys are documented in docs/config.example.toml in the nothin repo.
config_version = 1

[general]
# name = "your-name"
`

// Error is a problem in config.toml, with the line it is on (0 if unknown).
type Error struct {
	Line int
	Msg  string
}

func (e *Error) Error() string {
	if e.Line == 0 {
		return e.Msg
	}
	return fmt.Sprintf("line %d: %s", e.Line, e.Msg)
}

// Load parses doc over the defaults and validates the result.
func Load(doc []byte) (Config, error) {
	c := Defaults()
	err := toml.NewDecoder(bytes.NewReader(doc)).DisallowUnknownFields().Decode(&c)
	var de *toml.DecodeError
	var se *toml.StrictMissingError
	switch {
	case errors.As(err, &se):
		e := se.Errors[0]
		line, _ := e.Position()
		return c, &Error{line, "unknown key " + strings.Join(e.Key(), ".")}
	case errors.As(err, &de):
		line, _ := de.Position()
		return c, &Error{line, strings.TrimPrefix(de.Error(), "toml: ")}
	case err != nil:
		return c, &Error{0, err.Error()}
	}
	if path, msg := c.validate(); path != "" {
		line := 0
		if kv := find(doc, strings.Split(path, ".")); kv != nil {
			line = kv.line
		}
		return c, &Error{line, path + ": " + msg}
	}
	return c, nil
}

var hexColour = regexp.MustCompile(`^#[0-9a-fA-F]{6}$`)

// validate returns the dotted path of the first bad value and why.
func (c Config) validate() (path, msg string) {
	switch {
	case c.ConfigVersion < 1:
		return "config_version", "must be 1 or more"
	case c.ConfigVersion > Version:
		return "config_version", fmt.Sprintf("%d is newer than this nothin understands (%d); update nothin", c.ConfigVersion, Version)
	case c.General.Compositor != "auto" && c.General.Compositor != "niri":
		return "general.compositor", `must be "auto" or "niri"`
	case !hexColour.MatchString(c.Theme.Accent):
		return "theme.accent", `must be a colour like "#d71921"`
	case !hexColour.MatchString(c.Theme.Background):
		return "theme.background", `must be a colour like "#000000"`
	case !slices.Contains([]string{"left", "right", "top", "bottom"}, c.Rail.Position):
		return "rail.position", `must be "left", "right", "top" or "bottom"`
	}
	return c.Wallpaper.validate()
}
