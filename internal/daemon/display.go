package daemon

import (
	"encoding/json"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor"
	"github.com/Mauray-Jain/nothin-qs/internal/config"
)

// displayApplier remembers what it last applied to each connected monitor,
// so settings go to niri only when they change, when a monitor is plugged
// in, or after niri reloaded its own config (which resets live changes).
type displayApplier struct {
	applied map[string]string // monitor → its settings as JSON
	reloads int
}

func (a *displayApplier) plan(want map[string]config.Monitor, connected []string, reloads int) map[string]config.Monitor {
	if a.applied == nil || reloads != a.reloads {
		a.applied, a.reloads = map[string]string{}, reloads
	}
	present := map[string]bool{}
	todo := map[string]config.Monitor{}
	for _, name := range connected {
		present[name] = true
		m, ok := want[name]
		if !ok {
			continue
		}
		key, _ := json.Marshal(m)
		if a.applied[name] != string(key) {
			todo[name] = m
			a.applied[name] = string(key)
		}
	}
	for name := range a.applied {
		if !present[name] {
			delete(a.applied, name) // apply again when it comes back
		}
	}
	return todo
}

func outputSettings(m config.Monitor) compositor.OutputSettings {
	return compositor.OutputSettings{
		Enabled: m.Enabled, Scale: m.Scale, Mode: m.Mode, X: m.X, Y: m.Y, Transform: m.Transform, VRR: m.VRR,
	}
}
