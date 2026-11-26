package config

import "regexp"

// Niri holds settings that go into ~/.config/niri/nothin.kdl, which the user
// includes from their niri config. Every key is unset by default, and only set
// keys are written, so nothing in the user's own niri config is overridden
// unless they change it here.
type Niri struct {
	Gaps                  *int     `toml:"gaps" json:"gaps"`
	BorderWidth           *int     `toml:"border_width" json:"border_width"` // 0 turns the border off
	FocusRing             *bool    `toml:"focus_ring" json:"focus_ring"`
	FocusRingWidth        *int     `toml:"focus_ring_width" json:"focus_ring_width"`
	CornerRadius          *int     `toml:"corner_radius" json:"corner_radius"`
	KeyboardLayout        *string  `toml:"keyboard_layout" json:"keyboard_layout"` // xkb layouts, e.g. "us,de"
	RepeatDelay           *int     `toml:"repeat_delay" json:"repeat_delay"`       // ms
	RepeatRate            *int     `toml:"repeat_rate" json:"repeat_rate"`         // per second
	TouchpadTap           *bool    `toml:"touchpad_tap" json:"touchpad_tap"`
	TouchpadNaturalScroll *bool    `toml:"touchpad_natural_scroll" json:"touchpad_natural_scroll"`
	TouchpadDWT           *bool    `toml:"touchpad_dwt" json:"touchpad_dwt"`     // disable while typing
	TouchpadSpeed         *float64 `toml:"touchpad_speed" json:"touchpad_speed"` // -1..1
	MouseSpeed            *float64 `toml:"mouse_speed" json:"mouse_speed"`       // -1..1
	MouseAccel            *string  `toml:"mouse_accel" json:"mouse_accel"`       // adaptive | flat
	MouseNaturalScroll    *bool    `toml:"mouse_natural_scroll" json:"mouse_natural_scroll"`
}

var layoutPattern = regexp.MustCompile(`^[a-z0-9_,()+-]*$`)

func (n Niri) validate() (string, string) {
	ints := []struct {
		key      string
		v        *int
		min, max int
	}{
		{"gaps", n.Gaps, 0, 100}, {"border_width", n.BorderWidth, 0, 30}, {"focus_ring_width", n.FocusRingWidth, 1, 30},
		{"corner_radius", n.CornerRadius, 0, 60}, {"repeat_delay", n.RepeatDelay, 100, 3000}, {"repeat_rate", n.RepeatRate, 1, 200},
	}
	for _, f := range ints {
		if f.v != nil && (*f.v < f.min || *f.v > f.max) {
			return "niri." + f.key, "out of range"
		}
	}
	for _, f := range []struct {
		key string
		v   *float64
	}{{"touchpad_speed", n.TouchpadSpeed}, {"mouse_speed", n.MouseSpeed}} {
		if f.v != nil && (*f.v < -1 || *f.v > 1) {
			return "niri." + f.key, "must be between -1 and 1"
		}
	}
	if n.MouseAccel != nil && *n.MouseAccel != "adaptive" && *n.MouseAccel != "flat" {
		return "niri.mouse_accel", `must be "adaptive" or "flat"`
	}
	if n.KeyboardLayout != nil && !layoutPattern.MatchString(*n.KeyboardLayout) {
		return "niri.keyboard_layout", `must be xkb layout names like "us" or "us,de"`
	}
	return "", ""
}
