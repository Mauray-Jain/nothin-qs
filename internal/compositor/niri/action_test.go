package niri

import (
	"bufio"
	"net"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor"
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

func TestConfigureOutputSendsOneRequestPerSetting(t *testing.T) {
	scale, x, y, vrr := 1.5, 0, 1080, true
	mode, transform := "2560x1440@165", "90"
	tests := []struct {
		name string
		s    compositor.OutputSettings
		want []string
	}{
		{"off only", compositor.OutputSettings{Enabled: ptr(false), Scale: &scale},
			[]string{`{"Output":{"action":"Off","output":"DP-1"}}`}},
		{"everything", compositor.OutputSettings{Enabled: ptr(true), Mode: &mode, Scale: &scale, Transform: &transform, X: &x, Y: &y, VRR: &vrr},
			[]string{
				`{"Output":{"action":"On","output":"DP-1"}}`,
				`{"Output":{"action":{"Mode":{"mode":{"Specific":{"height":1440,"refresh":165,"width":2560}}}},"output":"DP-1"}}`,
				`{"Output":{"action":{"Scale":{"scale":{"Specific":1.5}}},"output":"DP-1"}}`,
				`{"Output":{"action":{"Transform":{"transform":"90"}},"output":"DP-1"}}`,
				`{"Output":{"action":{"Position":{"position":{"Specific":{"x":0,"y":1080}}}},"output":"DP-1"}}`,
				`{"Output":{"action":{"Vrr":{"vrr":{"on_demand":false,"vrr":true}}},"output":"DP-1"}}`,
			}},
		{"auto mode, no refresh, normal", compositor.OutputSettings{Mode: ptr("auto"), Transform: ptr("normal")},
			[]string{
				`{"Output":{"action":{"Mode":{"mode":"Automatic"}},"output":"DP-1"}}`,
				`{"Output":{"action":{"Transform":{"transform":"Normal"}},"output":"DP-1"}}`,
			}},
		{"mode without refresh", compositor.OutputSettings{Mode: ptr("1920x1080")},
			[]string{`{"Output":{"action":{"Mode":{"mode":{"Specific":{"height":1080,"refresh":null,"width":1920}}}},"output":"DP-1"}}`}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := outputRequests("DP-1", tt.s)
			if len(got) != len(tt.want) {
				t.Fatalf("got %d requests: %s", len(got), got)
			}
			for i := range got {
				if got[i] != tt.want[i] {
					t.Errorf("request %d\n got %s\nwant %s", i, got[i], tt.want[i])
				}
			}
		})
	}
}

func ptr[T any](v T) *T { return &v }

func TestConfigureOutputTalksToNiri(t *testing.T) {
	got := fakeNiri(t, `{"Ok":{"OutputConfigChanged":"Applied"}}`)
	if err := (Niri{}).ConfigureOutput("DP-1", compositor.OutputSettings{Enabled: ptr(false)}); err != nil {
		t.Fatal(err)
	}
	if req := <-got; req != `{"Output":{"action":"Off","output":"DP-1"}}` {
		t.Errorf("sent %s", req)
	}
}
