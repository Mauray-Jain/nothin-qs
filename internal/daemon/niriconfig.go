package daemon

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"time"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor/niri"
	"github.com/Mauray-Jain/nothin-qs/internal/config"
	"github.com/fsnotify/fsnotify"
)

// writeNothinKDL keeps nothin.kdl in step with [niri]. It isn't created
// while nothing is set, but an existing one is always rewritten (so unset
// keys disappear from it). Unchanged contents aren't written again, which
// would make niri reload for nothing.
func writeNothinKDL(path string, n config.Niri) error {
	want := []byte(niri.GenerateKDL(n))
	old, err := os.ReadFile(path)
	if errors.Is(err, fs.ErrNotExist) {
		if n == (config.Niri{}) {
			return nil
		}
	} else if err == nil && bytes.Equal(old, want) {
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return writeAtomic(path, want)
}

// followNiriConfig publishes the user's niri binds and whether config.kdl
// includes nothin.kdl, at start and whenever a file in niri's config folder
// changes (debounced), and writes nothin.kdl whenever [niri] changes.
func followNiriConfig(ctx context.Context, h *hub, log io.Writer) {
	path := niri.ConfigPath()
	publish := func() {
		c, err := niri.ReadConfig(path)
		msg := map[string]any{"type": "niri-config", "binds": c.Binds, "includes_nothin": c.IncludesNothin,
			"path": path, "kdl_path": niri.KDLPath(path), "error": ""}
		if err != nil {
			msg["binds"], msg["error"] = []niri.Bind{}, err.Error()
		}
		h.publish("niri-config", msg)
	}

	h.setOnLoad(func(c config.Config) {
		if err := writeNothinKDL(niri.KDLPath(path), c.Niri); err != nil {
			fmt.Fprintln(log, "nothin: nothin.kdl:", err)
		}
	})
	publish()

	w, err := fsnotify.NewWatcher()
	if err != nil {
		return
	}
	defer w.Close()
	if err := w.Add(filepath.Dir(path)); err != nil {
		return // no niri config folder: nothing to follow
	}
	debounce := time.NewTimer(time.Hour)
	debounce.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case ev := <-w.Events:
			if filepath.Ext(ev.Name) == ".kdl" {
				debounce.Reset(100 * time.Millisecond)
			}
		case <-w.Errors:
		case <-debounce.C:
			publish()
		}
	}
}
