// Package palette takes colours from the wallpaper with matugen, for
// theme.mode = "matugen".
package palette

import (
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"regexp"
	"strings"
)

// Palette is what the shell uses from matugen's dark scheme.
type Palette struct {
	Accent      string `json:"accent"`       // primary
	Background  string `json:"background"`   // surface
	Surface     string `json:"surface"`      // surface_container
	SurfaceHigh string `json:"surface_high"` // surface_container_high
}

var hexColour = regexp.MustCompile(`^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$`)

// Parse reads `matugen --json hex` output in any of its shapes:
// 4.x colors.<name>.dark.color, 4.x --old-json-output colors.<name>.dark,
// and before 4.0 colors.dark.<name>.
func Parse(b []byte) (Palette, error) {
	var out struct {
		Colors map[string]json.RawMessage `json:"colors"`
	}
	if err := json.Unmarshal(b, &out); err != nil {
		return Palette{}, fmt.Errorf("matugen output: %w", err)
	}
	dark := map[string]string{}
	if raw, ok := out.Colors["dark"]; ok { // before 4.0
		json.Unmarshal(raw, &dark)
	} else {
		for name, raw := range out.Colors {
			var v struct {
				Dark json.RawMessage `json:"dark"`
			}
			if json.Unmarshal(raw, &v) != nil || v.Dark == nil {
				continue
			}
			var s string
			var c struct{ Color string }
			if json.Unmarshal(v.Dark, &s) == nil {
				dark[name] = s
			} else if json.Unmarshal(v.Dark, &c) == nil {
				dark[name] = c.Color
			}
		}
	}
	pick := func(names ...string) string {
		for _, n := range names {
			if c := dark[n]; hexColour.MatchString(c) {
				return strings.ToLower(c[:7])
			}
		}
		return ""
	}
	p := Palette{
		Accent:      pick("primary"),
		Background:  pick("surface", "background"),
		Surface:     pick("surface_container", "surface_variant"),
		SurfaceHigh: pick("surface_container_high", "surface_container", "surface_variant"),
	}
	if p.Accent == "" || p.Background == "" || p.Surface == "" || p.SurfaceHigh == "" {
		return Palette{}, errors.New("matugen output has no usable dark colours")
	}
	return p, nil
}

// From runs matugen on the image through run (which returns its combined
// output), without touching templates or the wallpaper.
func From(image string, run func(args []string) ([]byte, error)) (Palette, error) {
	if image == "" {
		return Palette{}, errors.New("no wallpaper image to take colours from")
	}
	args := []string{"image", image, "--json", "hex", "--dry-run", "--mode", "dark"}
	out, err := run(append(args, "--source-color-index", "0"))
	if err != nil && strings.Contains(string(out), "source-color-index") {
		out, err = run(args) // matugen before the flag existed
	}
	if err != nil {
		return Palette{}, fmt.Errorf("matugen: %s", strings.TrimSpace(firstLine(string(out), err)))
	}
	return Parse(out)
}

func firstLine(out string, err error) string {
	if l, _, _ := strings.Cut(strings.TrimSpace(out), "\n"); l != "" {
		return l
	}
	return err.Error()
}

// Matugen runs the real matugen.
func Matugen(args []string) ([]byte, error) {
	cmd := exec.Command("matugen", args...)
	out, err := cmd.Output()
	if ee, ok := err.(*exec.ExitError); ok {
		out = append(out, ee.Stderr...)
	} else if err != nil {
		return []byte(err.Error()), err
	}
	return out, err
}
