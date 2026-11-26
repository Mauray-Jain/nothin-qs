package daemon

import (
	"errors"
	"testing"

	"github.com/Mauray-Jain/nothin-qs/internal/config"
	"github.com/Mauray-Jain/nothin-qs/internal/palette"
)

func TestPaletteWatcher(t *testing.T) {
	runs := 0
	from := func(path string) (palette.Palette, error) {
		runs++
		if path == "/bad.png" {
			return palette.Palette{}, errors.New("matugen: no colours")
		}
		return palette.Palette{Accent: "#a8c8ff"}, nil
	}
	var w paletteWatcher
	c := config.Defaults()

	// Mono: no palette, matugen never runs.
	if p, err, changed := w.update(c, from); !changed || p != nil || err != nil || runs != 0 {
		t.Fatalf("mono: %v %v %v runs=%d", p, err, changed, runs)
	}
	if _, _, changed := w.update(c, from); changed {
		t.Fatal("nothing changed: nothing to send")
	}

	c.Theme.Mode = "matugen"
	c.Wallpaper.Path = "/w/a.png"
	if p, err, changed := w.update(c, from); !changed || err != nil || p == nil || p.Accent != "#a8c8ff" || runs != 1 {
		t.Fatalf("matugen: %v %v %v runs=%d", p, err, changed, runs)
	}
	// An unrelated change doesn't run matugen again.
	c.General.Name = "ada"
	if _, _, changed := w.update(c, from); changed || runs != 1 {
		t.Fatalf("unrelated change ran matugen: runs=%d", runs)
	}
	// A failing image: an error, and no palette (the shell falls back).
	c.Wallpaper.Path = "/bad.png"
	if p, err, changed := w.update(c, from); !changed || err == nil || p != nil {
		t.Fatalf("bad image: %v %v %v", p, err, changed)
	}
}
