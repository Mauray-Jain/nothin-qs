package niri

import (
	"fmt"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/Mauray-Jain/nothin-qs/internal/config"
)

// KDLPath is nothin.kdl beside the niri config.
func KDLPath(configPath string) string {
	return filepath.Join(filepath.Dir(configPath), "nothin.kdl")
}

const kdlHeader = `// Written by nothin from [niri] in ~/.config/nothin/config.toml.
// Changes here are overwritten; use the nothin settings deck or config.toml.
// Include it at the end of ~/.config/niri/config.kdl:  include "nothin.kdl"
`

// GenerateKDL writes only the settings that are set. Included files merge
// property by property, except the touchpad and mouse sections, which an
// include replaces whole (niri docs, Configuration: Include).
func GenerateKDL(n config.Niri) string {
	var b strings.Builder
	b.WriteString(kdlHeader)
	block := func(name string, lines []string) {
		if len(lines) == 0 {
			return
		}
		b.WriteString("\n" + name + " {\n")
		for _, l := range lines {
			b.WriteString("    " + l + "\n")
		}
		b.WriteString("}\n")
	}
	nest := func(name string, lines []string) []string {
		if len(lines) == 0 {
			return nil
		}
		out := []string{name + " {"}
		for _, l := range lines {
			out = append(out, "    "+l)
		}
		return append(out, "}")
	}
	flag := func(name string, v *bool) []string {
		switch {
		case v == nil:
			return nil
		case *v:
			return []string{name}
		}
		return []string{name + " false"}
	}
	num := func(name string, v *int) []string {
		if v == nil {
			return nil
		}
		return []string{fmt.Sprintf("%s %d", name, *v)}
	}
	float := func(name string, v *float64) []string {
		if v == nil {
			return nil
		}
		return []string{name + " " + strconv.FormatFloat(*v, 'f', -1, 64)}
	}

	var layout []string
	layout = append(layout, num("gaps", n.Gaps)...)
	if n.BorderWidth != nil {
		if *n.BorderWidth == 0 {
			layout = append(layout, nest("border", []string{"off"})...)
		} else {
			layout = append(layout, nest("border", []string{"on", fmt.Sprintf("width %d", *n.BorderWidth)})...)
		}
	}
	var ring []string
	if n.FocusRing != nil {
		ring = append(ring, map[bool]string{true: "on", false: "off"}[*n.FocusRing])
	}
	if n.FocusRingWidth != nil && (n.FocusRing == nil || *n.FocusRing) {
		ring = append(ring, fmt.Sprintf("width %d", *n.FocusRingWidth))
	}
	layout = append(layout, nest("focus-ring", ring)...)
	block("layout", layout)

	if n.CornerRadius != nil {
		block("window-rule", []string{fmt.Sprintf("geometry-corner-radius %d", *n.CornerRadius), "clip-to-geometry true"})
	}

	var keyboard []string
	if n.KeyboardLayout != nil {
		keyboard = append(keyboard, nest("xkb", []string{fmt.Sprintf("layout %q", *n.KeyboardLayout)})...)
	}
	keyboard = append(keyboard, num("repeat-delay", n.RepeatDelay)...)
	keyboard = append(keyboard, num("repeat-rate", n.RepeatRate)...)
	var touchpad []string
	touchpad = append(touchpad, flag("tap", n.TouchpadTap)...)
	touchpad = append(touchpad, flag("natural-scroll", n.TouchpadNaturalScroll)...)
	touchpad = append(touchpad, flag("dwt", n.TouchpadDWT)...)
	touchpad = append(touchpad, float("accel-speed", n.TouchpadSpeed)...)
	var mouse []string
	mouse = append(mouse, flag("natural-scroll", n.MouseNaturalScroll)...)
	mouse = append(mouse, float("accel-speed", n.MouseSpeed)...)
	if n.MouseAccel != nil {
		mouse = append(mouse, fmt.Sprintf("accel-profile %q", *n.MouseAccel))
	}
	var input []string
	input = append(input, nest("keyboard", keyboard)...)
	input = append(input, nest("touchpad", touchpad)...)
	input = append(input, nest("mouse", mouse)...)
	block("input", input)
	return b.String()
}
