package niri

import (
	"bufio"
	"net"
	"path/filepath"
	"strings"
	"testing"
)

// fakeNiri answers one request per connection with reply and records it.
func fakeNiri(t *testing.T, reply string) <-chan string {
	sock := filepath.Join(t.TempDir(), "niri.sock")
	ln, err := net.Listen("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { ln.Close() })
	t.Setenv("NIRI_SOCKET", sock)
	got := make(chan string, 1)
	go func() {
		c, err := ln.Accept()
		if err != nil {
			return
		}
		defer c.Close()
		line, _ := bufio.NewReader(c).ReadString('\n')
		got <- strings.TrimSpace(line)
		c.Write([]byte(reply + "\n"))
	}()
	return got
}

func TestActions(t *testing.T) {
	tests := []struct {
		name string
		do   func(Niri) error
		want string
	}{
		{"focus workspace by id", func(n Niri) error { return n.FocusWorkspace(3) },
			`{"Action":{"FocusWorkspace":{"reference":{"Id":3}}}}`},
		{"focus window by id", func(n Niri) error { return n.FocusWindow(12) },
			`{"Action":{"FocusWindow":{"id":12}}}`},
		{"power off monitors", func(n Niri) error { return n.PowerOffMonitors() },
			`{"Action":{"PowerOffMonitors":{}}}`},
		{"toggle overview", func(n Niri) error { return n.ToggleOverview() },
			`{"Action":{"ToggleOverview":{}}}`},
		{"quit asks niri to confirm", func(n Niri) error { return n.Quit() },
			`{"Action":{"Quit":{"skip_confirmation":false}}}`},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := fakeNiri(t, `{"Ok":"Handled"}`)
			if err := tt.do(Niri{}); err != nil {
				t.Fatal(err)
			}
			if req := <-got; req != tt.want {
				t.Errorf("sent %s\nwant %s", req, tt.want)
			}
		})
	}
}

func TestActionErrorFromNiri(t *testing.T) {
	fakeNiri(t, `{"Err":"workspace not found"}`)
	err := Niri{}.FocusWorkspace(99)
	if err == nil || !strings.Contains(err.Error(), "workspace not found") {
		t.Errorf("err = %v, want niri's message", err)
	}
}

func TestActionWithoutNiri(t *testing.T) {
	t.Setenv("NIRI_SOCKET", "")
	if err := (Niri{}).ToggleOverview(); err == nil {
		t.Error("want an error when NIRI_SOCKET is unset")
	}
}
