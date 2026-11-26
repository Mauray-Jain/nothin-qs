package config

import (
	"fmt"
	"regexp"
	"slices"
	"sort"
)

type Display struct {
	Monitors map[string]Monitor `toml:"monitors" json:"monitors"`
}

// Monitor settings applied live through the compositor. A field left out is
// left as the compositor has it.
type Monitor struct {
	Enabled   *bool    `toml:"enabled" json:"enabled"`
	Scale     *float64 `toml:"scale" json:"scale"`
	Mode      *string  `toml:"mode" json:"mode"` // "2560x1440@165", "1920x1080" or "auto"
	X         *int     `toml:"x" json:"x"`
	Y         *int     `toml:"y" json:"y"`
	Transform *string  `toml:"transform" json:"transform"` // normal | 90 | 180 | 270 | flipped | flipped-90 | flipped-180 | flipped-270
	VRR       *bool    `toml:"vrr" json:"vrr"`
}

var (
	modePattern = regexp.MustCompile(`^(auto|\d{3,5}x\d{3,5}(@\d+(\.\d+)?)?)$`)
	transforms  = []string{"normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"}
)

func (d Display) validate() (string, string) {
	names := make([]string, 0, len(d.Monitors))
	for n := range d.Monitors {
		names = append(names, n)
	}
	sort.Strings(names)
	for _, n := range names {
		m, p := d.Monitors[n], fmt.Sprintf("display.monitors.%s.", n)
		switch {
		case m.Scale != nil && (*m.Scale < 0.25 || *m.Scale > 10):
			return p + "scale", "must be between 0.25 and 10"
		case m.Mode != nil && !modePattern.MatchString(*m.Mode):
			return p + "mode", `must look like "2560x1440@165", "1920x1080" or "auto"`
		case (m.X == nil) != (m.Y == nil):
			return p + "x", "x and y go together: set both or neither"
		case m.Transform != nil && !slices.Contains(transforms, *m.Transform):
			return p + "transform", `must be "normal", "90", "180", "270" or a "flipped" one`
		}
	}
	return "", ""
}
