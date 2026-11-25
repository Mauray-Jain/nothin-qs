package compositor

import (
	"net"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestFromEnv(t *testing.T) {
	tests := []struct {
		env  map[string]string
		want string
	}{
		{map[string]string{"NIRI_SOCKET": "/run/user/1000/niri.sock"}, "niri"},
		{map[string]string{"HYPRLAND_INSTANCE_SIGNATURE": "abc"}, "hyprland"},
		{map[string]string{"XDG_CURRENT_DESKTOP": "niri"}, "niri"},
		{map[string]string{"XDG_CURRENT_DESKTOP": "GNOME"}, ""},
		{map[string]string{}, ""},
	}
	for _, tt := range tests {
		got := fromEnv(func(k string) string { return tt.env[k] })
		if got != tt.want {
			t.Errorf("fromEnv(%v) = %q, want %q", tt.env, got, tt.want)
		}
	}
}

// The test process owns the socket, so its own name comes back.
func TestSocketOwner(t *testing.T) {
	sock := filepath.Join(t.TempDir(), "wayland-1")
	ln, err := net.Listen("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	go func() {
		c, err := ln.Accept()
		if err == nil {
			c.Close()
		}
	}()
	got, err := socketOwner(sock)
	if err != nil {
		t.Fatal(err)
	}
	self, _ := os.ReadFile("/proc/self/comm")
	if got != strings.TrimSpace(string(self)) {
		t.Errorf("socketOwner = %q, want %q", got, self)
	}
}

func TestDetect(t *testing.T) {
	none := func(string) string { return "" }
	niriEnv := func(k string) string {
		if k == "NIRI_SOCKET" {
			return "/x"
		}
		return ""
	}
	if got, err := detect("niri", none); got != "niri" || err != nil {
		t.Errorf(`override "niri": %q, %v`, got, err)
	}
	if got, err := detect("auto", niriEnv); got != "niri" || err != nil {
		t.Errorf("auto with NIRI_SOCKET: %q, %v", got, err)
	}
	if _, err := detect("auto", none); err == nil {
		t.Error("auto with nothing to go on should fail")
	}
}
