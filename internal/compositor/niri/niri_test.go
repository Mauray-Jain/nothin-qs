package niri

import (
	"bufio"
	"encoding/json"
	"os"
	"reflect"
	"testing"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor"
)

func replay(t *testing.T) *state {
	t.Helper()
	f, err := os.Open("testdata/events.jsonl")
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	s := newState()
	sc := bufio.NewScanner(f)
	sc.Buffer(nil, 1<<20)
	for sc.Scan() {
		if _, err := s.apply(sc.Bytes()); err != nil {
			t.Fatalf("apply %s: %v", sc.Bytes(), err)
		}
	}
	return s
}

func TestReplayMatchesGolden(t *testing.T) {
	got := replay(t).snapshot()
	b, _ := os.ReadFile("testdata/state.json")
	var want compositor.State
	if err := json.Unmarshal(b, &want); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(got, want) {
		g, _ := json.MarshalIndent(got, "", "  ")
		t.Errorf("state after replay:\n%s\nwant:\n%s", g, b)
	}
}

func TestEmptySnapshotHasNoNulls(t *testing.T) {
	b, _ := json.Marshal(newState().snapshot())
	want := `{"focused_output":"","overview":false,"outputs":[],"workspaces":[],"windows":[]}`
	if string(b) != want {
		t.Errorf("got %s, want %s", b, want)
	}
}

func TestApplyReportsChanges(t *testing.T) {
	s := replay(t)
	tests := []struct {
		event   string
		changed bool
	}{
		{`{"WindowFocusTimestampChanged":{"id":11,"focus_timestamp":null}}`, false},
		{`{"WindowLayoutsChanged":{"changes":[]}}`, false},
		{`{"KeyboardLayoutSwitched":{"idx":0}}`, false},
		{`{"Unknown":{}}`, false},
		{`{"OverviewOpenedOrClosed":{"is_open":false}}`, true},
		{`{"WorkspaceActivated":{"id":1,"focused":false}}`, true},
	}
	for _, tt := range tests {
		changed, err := s.apply([]byte(tt.event))
		if err != nil || changed != tt.changed {
			t.Errorf("%s: changed=%v err=%v, want changed=%v", tt.event, changed, err, tt.changed)
		}
	}
}

func TestActivateWithoutFocusKeepsFocus(t *testing.T) {
	s := replay(t) // workspace 3 on HDMI-A-1 has focus
	s.apply([]byte(`{"WorkspaceActivated":{"id":1,"focused":false}}`))
	snap := s.snapshot()
	if snap.FocusedOutput != "HDMI-A-1" {
		t.Errorf("focused output = %q, want HDMI-A-1", snap.FocusedOutput)
	}
	for _, w := range snap.Workspaces {
		if w.Output == "eDP-1" && w.Active != (w.ID == 1) {
			t.Errorf("workspace %d active = %v", w.ID, w.Active)
		}
		if w.ID == 3 && !(w.Active && w.Focused) {
			t.Errorf("workspace 3 should stay active and focused: %+v", w)
		}
	}
}

func TestFocusNoWindow(t *testing.T) {
	s := replay(t)
	s.apply([]byte(`{"WindowFocusChanged":{"id":null}}`))
	for _, w := range s.snapshot().Windows {
		if w.Focused {
			t.Errorf("window %d still focused", w.ID)
		}
	}
}

func TestBadEventIsAnError(t *testing.T) {
	if _, err := newState().apply([]byte(`{"WindowClosed":{"id":"x"}}`)); err == nil {
		t.Error("want error for a malformed known event")
	}
}

func TestParseOutputs(t *testing.T) {
	b, _ := os.ReadFile("testdata/outputs.json")
	got, err := parseOutputs(b)
	if err != nil {
		t.Fatal(err)
	}
	want := []compositor.Output{ // sorted by position; DP-2 is off (no logical size)
		{Name: "eDP-1", X: 0, Y: 0, Width: 1600, Height: 1000, Scale: 1.4},
		{Name: "HDMI-A-1", X: 1600, Y: 0, Width: 1920, Height: 1080, Scale: 2},
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %+v\nwant %+v", got, want)
	}
}

func TestSummary(t *testing.T) {
	got := Summary(replay(t).snapshot())
	want := "HDMI-A-1* [1*!] | eDP-1 [1 2·] | focus: thunderbird \"Inbox\""
	if got != want {
		t.Errorf("Summary = %q\nwant      %q", got, want)
	}
}
