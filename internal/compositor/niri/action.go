package niri

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor"
)

func (n Niri) FocusWorkspace(id uint64) error {
	return action(map[string]any{"FocusWorkspace": map[string]any{"reference": map[string]any{"Id": id}}})
}

func (n Niri) FocusWindow(id uint64) error {
	return action(map[string]any{"FocusWindow": map[string]any{"id": id}})
}

// PowerOffMonitors blanks every screen; niri turns them back on at the next input.
func (n Niri) PowerOffMonitors() error {
	return action(map[string]any{"PowerOffMonitors": struct{}{}})
}

func (n Niri) ToggleOverview() error {
	return action(map[string]any{"ToggleOverview": struct{}{}})
}

// Quit leaves niri's own "are you sure" prompt on.
func (n Niri) Quit() error {
	return action(map[string]any{"Quit": map[string]any{"skip_confirmation": false}})
}

// ConfigureOutput applies the settings that are set, one request each. Off
// alone is sent when the monitor is to be turned off.
func (n Niri) ConfigureOutput(name string, s compositor.OutputSettings) error {
	for _, req := range outputRequests(name, s) {
		if err := request([]byte(req)); err != nil {
			return fmt.Errorf("%s: %w", name, err)
		}
	}
	return nil
}

func outputRequests(name string, s compositor.OutputSettings) []string {
	var actions []any
	if s.Enabled != nil && !*s.Enabled {
		actions = append(actions, "Off")
	} else {
		if s.Enabled != nil {
			actions = append(actions, "On")
		}
		if s.Mode != nil {
			actions = append(actions, map[string]any{"Mode": map[string]any{"mode": modeToSet(*s.Mode)}})
		}
		if s.Scale != nil {
			actions = append(actions, map[string]any{"Scale": map[string]any{"scale": map[string]any{"Specific": *s.Scale}}})
		}
		if s.Transform != nil {
			actions = append(actions, map[string]any{"Transform": map[string]any{"transform": transformToSet(*s.Transform)}})
		}
		if s.X != nil && s.Y != nil {
			actions = append(actions, map[string]any{"Position": map[string]any{"position": map[string]any{"Specific": map[string]any{"x": *s.X, "y": *s.Y}}}})
		}
		if s.VRR != nil {
			actions = append(actions, map[string]any{"Vrr": map[string]any{"vrr": map[string]any{"vrr": *s.VRR, "on_demand": false}}})
		}
	}
	reqs := make([]string, len(actions))
	for i, a := range actions {
		b, _ := json.Marshal(map[string]any{"Output": map[string]any{"output": name, "action": a}})
		reqs[i] = string(b)
	}
	return reqs
}

func modeToSet(mode string) any {
	if mode == "auto" {
		return "Automatic"
	}
	var w, h int
	var hz float64
	size, rate, hasRate := strings.Cut(mode, "@")
	fmt.Sscanf(size, "%dx%d", &w, &h)
	var refresh any // null: let niri pick the rate
	if hasRate {
		hz, _ = strconv.ParseFloat(rate, 64)
		refresh = hz
	}
	return map[string]any{"Specific": map[string]any{"width": w, "height": h, "refresh": refresh}}
}

// transformToSet turns "90" or "flipped-90" into niri's names ("90", "Flipped90").
func transformToSet(t string) string {
	switch t {
	case "normal":
		return "Normal"
	case "flipped":
		return "Flipped"
	}
	if rest, ok := strings.CutPrefix(t, "flipped-"); ok {
		return "Flipped" + rest
	}
	return t
}

// action sends one request on niri's socket and reads its reply. The socket
// takes workspace ids, which `niri msg` can't.
func action(a any) error {
	req, _ := json.Marshal(map[string]any{"Action": a})
	return request(req)
}

func request(req []byte) error {
	path := os.Getenv("NIRI_SOCKET")
	if path == "" {
		return errors.New("NIRI_SOCKET is not set")
	}
	c, err := net.DialTimeout("unix", path, time.Second)
	if err != nil {
		return err
	}
	defer c.Close()
	c.SetDeadline(time.Now().Add(2 * time.Second))
	if _, err := c.Write(append(req, '\n')); err != nil {
		return err
	}
	line, err := bufio.NewReader(c).ReadBytes('\n')
	if err != nil {
		return err
	}
	var reply struct{ Err *string }
	if err := json.Unmarshal(line, &reply); err != nil {
		return err
	}
	if reply.Err != nil {
		return fmt.Errorf("niri: %s", *reply.Err)
	}
	return nil
}
