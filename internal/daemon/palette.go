package daemon

import (
	"context"
	"fmt"
	"io"

	"github.com/Mauray-Jain/nothin-qs/internal/config"
	"github.com/Mauray-Jain/nothin-qs/internal/palette"
)

// paletteWatcher runs matugen only when what it depends on changes: the
// theme mode and the wallpaper image.
type paletteWatcher struct {
	key  string
	seen bool
}

// update returns the palette to send (nil: use the configured colours), any
// error, and whether anything changed since last time.
func (w *paletteWatcher) update(c config.Config, from func(string) (palette.Palette, error)) (*palette.Palette, error, bool) {
	key := c.Theme.Mode + "\x00" + c.Wallpaper.Path
	if c.Theme.Mode != "matugen" {
		key = "mono"
	}
	if w.seen && key == w.key {
		return nil, nil, false
	}
	w.key, w.seen = key, true
	if c.Theme.Mode != "matugen" {
		return nil, nil, true
	}
	p, err := from(c.Wallpaper.Path)
	if err != nil {
		return nil, err, true
	}
	return &p, nil, true
}

// followPalette publishes {"type":"palette","palette":{…}|null} at start and
// whenever the mode or wallpaper changes. matugen runs here, off the lock.
func followPalette(ctx context.Context, h *hub, log io.Writer) {
	configs := make(chan config.Config, 1)
	h.addOnLoad(func(c config.Config) {
		select {
		case <-configs: // keep only the newest
		default:
		}
		configs <- c
	})
	var w paletteWatcher
	from := func(path string) (palette.Palette, error) { return palette.From(path, palette.Matugen) }
	for {
		select {
		case <-ctx.Done():
			return
		case c := <-configs:
			p, err, changed := w.update(c, from)
			if !changed {
				continue
			}
			if err != nil {
				fmt.Fprintln(log, "nothin:", err)
				h.mu.Lock()
				h.broadcast(errorMsg("theme: " + err.Error() + " (using the configured colours)"))
				h.mu.Unlock()
			}
			h.publish("palette", map[string]any{"type": "palette", "palette": p})
		}
	}
}
