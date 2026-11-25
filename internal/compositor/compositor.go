// Package compositor finds the running compositor and defines what nothin
// needs from one. Backends live in sub-packages (niri/).
package compositor

import (
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"syscall"
)

// Compositor streams the desktop's state. The niri backend is the only one in v1.
type Compositor interface {
	// Run calls update with a fresh State after every change, until ctx ends.
	Run(ctx context.Context, update func(State)) error
	FocusWorkspace(id uint64) error
	FocusWindow(id uint64) error
	ToggleOverview() error
	Quit() error // log out
	PowerOffMonitors() error
}

// State is what the shell sees, the same for every compositor.
type State struct {
	FocusedOutput string      `json:"focused_output"`
	Overview      bool        `json:"overview"`
	Outputs       []Output    `json:"outputs"`
	Workspaces    []Workspace `json:"workspaces"` // by output, then index
	Windows       []Window    `json:"windows"`    // by id
}

type Output struct {
	Name   string  `json:"name"`
	X      int     `json:"x"`
	Y      int     `json:"y"`
	Width  int     `json:"width"`
	Height int     `json:"height"`
	Scale  float64 `json:"scale"`
}

type Workspace struct {
	ID      uint64 `json:"id"`
	Index   int    `json:"index"` // 1-based position on its output
	Name    string `json:"name"`
	Output  string `json:"output"`
	Active  bool   `json:"active"`  // shown on its output
	Focused bool   `json:"focused"` // the one workspace with focus
	Urgent  bool   `json:"urgent"`
}

type Window struct {
	ID          uint64 `json:"id"`
	Title       string `json:"title"`
	AppID       string `json:"app_id"`
	WorkspaceID uint64 `json:"workspace_id"` // 0 if none
	Focused     bool   `json:"focused"`
	Urgent      bool   `json:"urgent"`
}

// Detect names the running compositor. setting is general.compositor:
// "auto" detects, anything else is taken as is.
func Detect(setting string) (string, error) {
	return detect(setting, os.Getenv)
}

func detect(setting string, getenv func(string) string) (string, error) {
	if setting != "auto" {
		return setting, nil
	}
	if d := getenv("WAYLAND_DISPLAY"); d != "" {
		path := d
		if !filepath.IsAbs(path) {
			path = filepath.Join(getenv("XDG_RUNTIME_DIR"), d)
		}
		if comm, err := socketOwner(path); err == nil {
			if name := fromComm(comm); name != "" {
				return name, nil
			}
		}
	}
	if name := fromEnv(getenv); name != "" {
		return name, nil
	}
	return "", errors.New("could not tell which compositor is running; set general.compositor")
}

func fromComm(comm string) string {
	switch strings.ToLower(comm) {
	case "niri":
		return "niri"
	case "hyprland":
		return "hyprland"
	}
	return ""
}

func fromEnv(getenv func(string) string) string {
	switch {
	case getenv("NIRI_SOCKET") != "":
		return "niri"
	case getenv("HYPRLAND_INSTANCE_SIGNATURE") != "":
		return "hyprland"
	}
	return fromComm(getenv("XDG_CURRENT_DESKTOP"))
}

// socketOwner returns the process name of whoever listens on a Unix socket.
func socketOwner(path string) (string, error) {
	c, err := net.Dial("unix", path)
	if err != nil {
		return "", err
	}
	defer c.Close()
	raw, err := c.(*net.UnixConn).SyscallConn()
	if err != nil {
		return "", err
	}
	var cred *syscall.Ucred
	var credErr error
	raw.Control(func(fd uintptr) {
		cred, credErr = syscall.GetsockoptUcred(int(fd), syscall.SOL_SOCKET, syscall.SO_PEERCRED)
	})
	if credErr != nil {
		return "", credErr
	}
	comm, err := os.ReadFile(fmt.Sprintf("/proc/%d/comm", cred.Pid))
	return strings.TrimSpace(string(comm)), err
}
