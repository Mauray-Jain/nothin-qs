// Package niri is the niri backend: it follows `niri msg --json event-stream`.
package niri

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"sort"
	"strings"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor"
)

type Niri struct{}

// Run follows niri's event stream until ctx ends or niri closes it. Outputs
// are read at start and again whenever workspaces change, which is what
// happens when a monitor is plugged in or out.
func (Niri) Run(ctx context.Context, update func(compositor.State)) error {
	s := newState()
	s.outputs = readOutputs(ctx)
	cmd := exec.CommandContext(ctx, "niri", "msg", "--json", "event-stream")
	out, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	if err := cmd.Start(); err != nil {
		return err
	}
	sc := bufio.NewScanner(out)
	sc.Buffer(nil, 4<<20)
	for sc.Scan() {
		line := sc.Bytes()
		changed, err := s.apply(line)
		if err != nil {
			continue // one odd event shouldn't stop the stream
		}
		if bytes.HasPrefix(line, []byte(`{"WorkspacesChanged"`)) {
			s.outputs = readOutputs(ctx)
		}
		if changed {
			update(s.snapshot())
		}
	}
	return cmd.Wait()
}

func readOutputs(ctx context.Context) []compositor.Output {
	b, err := exec.CommandContext(ctx, "niri", "msg", "--json", "outputs").Output()
	if err != nil {
		return nil
	}
	o, _ := parseOutputs(b)
	return o
}

// niri's own JSON shapes (niri-ipc), only the fields nothin uses.
type workspace struct {
	ID        uint64  `json:"id"`
	Idx       int     `json:"idx"`
	Name      *string `json:"name"`
	Output    *string `json:"output"`
	IsUrgent  bool    `json:"is_urgent"`
	IsActive  bool    `json:"is_active"`
	IsFocused bool    `json:"is_focused"`
}

type window struct {
	ID          uint64  `json:"id"`
	Title       *string `json:"title"`
	AppID       *string `json:"app_id"`
	WorkspaceID *uint64 `json:"workspace_id"`
	IsFocused   bool    `json:"is_focused"`
	IsUrgent    bool    `json:"is_urgent"`
}

type output struct {
	Name         string `json:"name"`
	Make         string `json:"make"`
	Model        string `json:"model"`
	VRRSupported bool   `json:"vrr_supported"`
	VRREnabled   bool   `json:"vrr_enabled"`
	CurrentMode  *int   `json:"current_mode"`
	Modes        []struct {
		Width       int `json:"width"`
		Height      int `json:"height"`
		RefreshRate int `json:"refresh_rate"` // millihertz
	} `json:"modes"`
	Logical *struct {
		X         int     `json:"x"`
		Y         int     `json:"y"`
		Width     int     `json:"width"`
		Height    int     `json:"height"`
		Scale     float64 `json:"scale"`
		Transform string  `json:"transform"`
	} `json:"logical"`
}

type state struct {
	workspaces map[uint64]*workspace
	windows    map[uint64]*window
	outputs    []compositor.Output
	overview   bool
	reloads    int
}

func newState() *state {
	return &state{workspaces: map[uint64]*workspace{}, windows: map[uint64]*window{}}
}

// apply folds one event line into the state and reports whether anything
// the shell shows changed. Events nothin doesn't use are ignored.
func (s *state) apply(line []byte) (bool, error) {
	var ev map[string]json.RawMessage
	if err := json.Unmarshal(line, &ev); err != nil {
		return false, err
	}
	for name, body := range ev {
		changed, err := s.applyOne(name, body)
		if err != nil {
			return false, fmt.Errorf("%s: %w", name, err)
		}
		return changed, nil
	}
	return false, nil
}

func (s *state) applyOne(name string, body json.RawMessage) (bool, error) {
	switch name {
	case "WorkspacesChanged":
		var e struct{ Workspaces []*workspace }
		if err := json.Unmarshal(body, &e); err != nil {
			return false, err
		}
		s.workspaces = map[uint64]*workspace{}
		for _, w := range e.Workspaces {
			s.workspaces[w.ID] = w
		}
	case "WorkspaceActivated":
		var e struct {
			ID      uint64
			Focused bool
		}
		if err := json.Unmarshal(body, &e); err != nil {
			return false, err
		}
		ws := s.workspaces[e.ID]
		if ws == nil {
			return false, nil
		}
		for _, w := range s.workspaces {
			if outputOf(w) == outputOf(ws) {
				w.IsActive = false
			}
			if e.Focused {
				w.IsFocused = false
			}
		}
		ws.IsActive = true
		ws.IsFocused = ws.IsFocused || e.Focused
	case "WorkspaceUrgencyChanged":
		var e struct {
			ID     uint64
			Urgent bool
		}
		if err := json.Unmarshal(body, &e); err != nil {
			return false, err
		}
		if ws := s.workspaces[e.ID]; ws != nil {
			ws.IsUrgent = e.Urgent
		}
	case "WindowsChanged":
		var e struct{ Windows []*window }
		if err := json.Unmarshal(body, &e); err != nil {
			return false, err
		}
		s.windows = map[uint64]*window{}
		for _, w := range e.Windows {
			s.windows[w.ID] = w
		}
	case "WindowOpenedOrChanged":
		var e struct{ Window *window }
		if err := json.Unmarshal(body, &e); err != nil {
			return false, err
		}
		if e.Window.IsFocused {
			for _, w := range s.windows {
				w.IsFocused = false
			}
		}
		s.windows[e.Window.ID] = e.Window
	case "WindowClosed":
		var e struct{ ID uint64 }
		if err := json.Unmarshal(body, &e); err != nil {
			return false, err
		}
		delete(s.windows, e.ID)
	case "WindowFocusChanged":
		var e struct{ ID *uint64 }
		if err := json.Unmarshal(body, &e); err != nil {
			return false, err
		}
		for _, w := range s.windows {
			w.IsFocused = e.ID != nil && w.ID == *e.ID
		}
	case "WindowUrgencyChanged":
		var e struct {
			ID     uint64
			Urgent bool
		}
		if err := json.Unmarshal(body, &e); err != nil {
			return false, err
		}
		if w := s.windows[e.ID]; w != nil {
			w.IsUrgent = e.Urgent
		}
	case "ConfigLoaded":
		s.reloads++
	case "OverviewOpenedOrClosed":
		var e struct {
			IsOpen bool `json:"is_open"`
		}
		if err := json.Unmarshal(body, &e); err != nil {
			return false, err
		}
		s.overview = e.IsOpen
	default:
		return false, nil
	}
	return true, nil
}

func outputOf(w *workspace) string { return deref(w.Output) }

func deref[T any](p *T) T {
	var zero T
	if p == nil {
		return zero
	}
	return *p
}

func (s *state) snapshot() compositor.State {
	st := compositor.State{
		Overview:      s.overview,
		ConfigReloads: s.reloads,
		Outputs:       append([]compositor.Output{}, s.outputs...),
		Workspaces:    []compositor.Workspace{},
		Windows:       []compositor.Window{},
	}
	for _, w := range s.workspaces {
		st.Workspaces = append(st.Workspaces, compositor.Workspace{
			ID: w.ID, Index: w.Idx, Name: deref(w.Name), Output: outputOf(w),
			Active: w.IsActive, Focused: w.IsFocused, Urgent: w.IsUrgent,
		})
		if w.IsFocused {
			st.FocusedOutput = outputOf(w)
		}
	}
	sort.Slice(st.Workspaces, func(i, j int) bool {
		a, b := st.Workspaces[i], st.Workspaces[j]
		if a.Output != b.Output {
			return a.Output < b.Output
		}
		return a.Index < b.Index
	})
	for _, w := range s.windows {
		st.Windows = append(st.Windows, compositor.Window{
			ID: w.ID, Title: deref(w.Title), AppID: deref(w.AppID), WorkspaceID: deref(w.WorkspaceID),
			Focused: w.IsFocused, Urgent: w.IsUrgent,
		})
	}
	sort.Slice(st.Windows, func(i, j int) bool { return st.Windows[i].ID < st.Windows[j].ID })
	return st
}

// parseOutputs reads `niri msg --json outputs`: monitors that are on, left
// to right, then those that are off (so they can be turned back on).
func parseOutputs(b []byte) ([]compositor.Output, error) {
	var m map[string]output
	if err := json.Unmarshal(b, &m); err != nil {
		return nil, err
	}
	out := []compositor.Output{}
	for _, o := range m {
		c := compositor.Output{
			Name: o.Name, Make: o.Make, Model: o.Model, Modes: []compositor.Mode{}, CurrentMode: -1,
			VRRSupported: o.VRRSupported, VRREnabled: o.VRREnabled,
		}
		for _, md := range o.Modes {
			c.Modes = append(c.Modes, compositor.Mode{Width: md.Width, Height: md.Height, Refresh: float64(md.RefreshRate) / 1000})
		}
		if o.CurrentMode != nil {
			c.CurrentMode = *o.CurrentMode
		}
		if l := o.Logical; l != nil {
			c.On, c.X, c.Y, c.Width, c.Height, c.Scale = true, l.X, l.Y, l.Width, l.Height, l.Scale
			c.Transform = strings.ToLower(strings.NewReplacer("Flipped", "flipped-").Replace(l.Transform))
			c.Transform = strings.TrimSuffix(c.Transform, "-")
		}
		out = append(out, c)
	}
	sort.Slice(out, func(i, j int) bool {
		a, b := out[i], out[j]
		if a.On != b.On {
			return a.On
		}
		if a.X != b.X {
			return a.X < b.X
		}
		if a.Y != b.Y {
			return a.Y < b.Y
		}
		return a.Name < b.Name
	})
	return out, nil
}

// Summary is one log line: each output's workspaces (* focused, · active,
// ! urgent; * after an output name marks the focused output) and the
// focused window.
func Summary(st compositor.State) string {
	var parts []string
	var cur string
	var ws []string
	flush := func() {
		if cur == "" {
			return
		}
		name := cur
		if cur == st.FocusedOutput {
			name += "*"
		}
		parts = append(parts, name+" ["+strings.Join(ws, " ")+"]")
	}
	for _, w := range st.Workspaces {
		if w.Output != cur {
			flush()
			cur, ws = w.Output, nil
		}
		tok := fmt.Sprint(w.Index)
		switch {
		case w.Focused:
			tok += "*"
		case w.Active:
			tok += "·"
		}
		if w.Urgent {
			tok += "!"
		}
		ws = append(ws, tok)
	}
	flush()
	focus := "none"
	for _, w := range st.Windows {
		if w.Focused {
			focus = fmt.Sprintf("%s %q", w.AppID, w.Title)
		}
	}
	return strings.Join(append(parts, "focus: "+focus), " | ")
}
