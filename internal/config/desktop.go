package config

import (
	"fmt"
	"slices"
	"sort"
)

type Desktop struct {
	Monitors  []string             `toml:"monitors" json:"monitors"` // empty = every monitor
	Layout    string               `toml:"layout" json:"layout"`     // grid | free
	HeroClock bool                 `toml:"hero_clock" json:"hero_clock"`
	Greeting  bool                 `toml:"greeting" json:"greeting"`
	Widgets   []string             `toml:"widgets" json:"widgets"`     // shown, in grid order
	System    []string             `toml:"system" json:"system"`       // rows of the system widget
	Positions map[string][]float64 `toml:"positions" json:"positions"` // free layout: widget → [x, y], 0..1 of the screen
}

type Weather struct {
	Location string `toml:"location" json:"location"` // "" = look up by IP; a place name or "lat,lon"
}

var (
	widgetNames = []string{"weather", "calendar", "player", "system"}
	systemNames = []string{"cpu", "memory", "disk", "temperature"}
)

func oneOfEach(path string, items, allowed []string) (string, string) {
	seen := map[string]bool{}
	for _, it := range items {
		if !slices.Contains(allowed, it) {
			return path, fmt.Sprintf("unknown item %q (known: %v)", it, allowed)
		}
		if seen[it] {
			return path, fmt.Sprintf("%q is listed twice", it)
		}
		seen[it] = true
	}
	return "", ""
}

func (d Desktop) validate() (string, string) {
	if d.Layout != "grid" && d.Layout != "free" {
		return "desktop.layout", `must be "grid" or "free"`
	}
	if p, m := oneOfEach("desktop.widgets", d.Widgets, widgetNames); p != "" {
		return p, m
	}
	if p, m := oneOfEach("desktop.system", d.System, systemNames); p != "" {
		return p, m
	}
	names := make([]string, 0, len(d.Positions))
	for n := range d.Positions {
		names = append(names, n)
	}
	sort.Strings(names)
	for _, n := range names {
		p := d.Positions[n]
		if !slices.Contains(widgetNames, n) {
			return "desktop.positions", fmt.Sprintf("unknown widget %q", n)
		}
		if len(p) != 2 || p[0] < 0 || p[0] > 1 || p[1] < 0 || p[1] > 1 {
			return "desktop.positions", fmt.Sprintf("%s must be [x, y] with both between 0 and 1", n)
		}
	}
	return "", ""
}
