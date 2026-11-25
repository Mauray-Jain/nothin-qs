package niri

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"time"
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

// action sends one request on niri's socket and reads its reply. The socket
// takes workspace ids, which `niri msg` can't.
func action(a any) error {
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
	req, _ := json.Marshal(map[string]any{"Action": a})
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
