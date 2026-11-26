package daemon

import (
	"reflect"
	"sort"
	"testing"

	"github.com/Mauray-Jain/nothin-qs/internal/config"
)

func names(m map[string]config.Monitor) []string {
	out := []string{}
	for n := range m {
		out = append(out, n)
	}
	sort.Strings(out)
	return out
}

func TestDisplayPlan(t *testing.T) {
	two, one5 := 2.0, 1.5
	want := map[string]config.Monitor{"eDP-1": {Scale: &two}, "HDMI-A-1": {Scale: &one5}}
	var a displayApplier

	// First run: only the monitors that are connected.
	got := a.plan(want, []string{"eDP-1", "DP-3"}, 0)
	if !reflect.DeepEqual(names(got), []string{"eDP-1"}) {
		t.Fatalf("first: %v", names(got))
	}
	// Nothing changed: nothing to do.
	if got := a.plan(want, []string{"eDP-1", "DP-3"}, 0); len(got) != 0 {
		t.Fatalf("again: %v", names(got))
	}
	// HDMI plugged in: just it.
	if got := a.plan(want, []string{"eDP-1", "HDMI-A-1"}, 0); !reflect.DeepEqual(names(got), []string{"HDMI-A-1"}) {
		t.Fatalf("hotplug: %v", names(got))
	}
	// A setting changes: just that monitor.
	three := 3.0
	want["eDP-1"] = config.Monitor{Scale: &three}
	if got := a.plan(want, []string{"eDP-1", "HDMI-A-1"}, 0); !reflect.DeepEqual(names(got), []string{"eDP-1"}) {
		t.Fatalf("change: %v", names(got))
	}
	// niri reloaded its config (which resets live changes): everything again.
	if got := a.plan(want, []string{"eDP-1", "HDMI-A-1"}, 1); !reflect.DeepEqual(names(got), []string{"HDMI-A-1", "eDP-1"}) {
		t.Fatalf("reload: %v", names(got))
	}
	// Unplugged and back: applied again.
	a.plan(want, []string{"eDP-1"}, 1)
	if got := a.plan(want, []string{"eDP-1", "HDMI-A-1"}, 1); !reflect.DeepEqual(names(got), []string{"HDMI-A-1"}) {
		t.Fatalf("replug: %v", names(got))
	}
}
