package daemon

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor"
)

type msg struct {
	Type   string `json:"type"`
	Error  string `json:"error"`
	Config struct {
		General struct {
			Name string `json:"name"`
		} `json:"general"`
	} `json:"config"`
}

type testClient struct {
	t    *testing.T
	conn net.Conn
	r    *bufio.Scanner
}

func dial(t *testing.T, sock string) *testClient {
	conn, err := net.Dial("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { conn.Close() })
	return &testClient{t, conn, bufio.NewScanner(conn)}
}

func (c *testClient) next() msg {
	c.t.Helper()
	c.conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	if !c.r.Scan() {
		c.t.Fatalf("no message: %v", c.r.Err())
	}
	var m msg
	if err := json.Unmarshal(c.r.Bytes(), &m); err != nil {
		c.t.Fatal(err)
	}
	return m
}

func (c *testClient) send(s string) {
	c.conn.Write([]byte(s + "\n"))
}

func TestHub(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "nothin", "config.toml")
	sock := filepath.Join(dir, "nothin.sock")
	h, err := newHub(path)
	if err != nil {
		t.Fatal(err)
	}
	ln, err := net.Listen("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go h.serve(ln)
	go h.watch(ctx)

	// First run writes the starter file and sends defaults.
	c := dial(t, sock)
	if m := c.next(); m.Type != "config" || m.Config.General.Name != "" {
		t.Fatalf("first message = %+v", m)
	}
	if b, _ := os.ReadFile(path); !strings.Contains(string(b), "# nothin settings") {
		t.Fatalf("starter not written:\n%s", b)
	}

	// A UI write patches the file in place and is broadcast once.
	c.send(`{"type":"set","path":"general.name","value":"bob"}`)
	if m := c.next(); m.Config.General.Name != "bob" {
		t.Fatalf("after set: %+v", m)
	}
	b, _ := os.ReadFile(path)
	if !strings.Contains(string(b), "# nothin settings") || !strings.Contains(string(b), `name = "bob"`) {
		t.Fatalf("patched file lost comments or value:\n%s", b)
	}

	// A bad set gets an error back, and the file is unchanged.
	c.send(`{"type":"set","path":"theme.accent","value":"red"}`)
	if m := c.next(); m.Type != "error" || !strings.Contains(m.Error, "theme.accent") {
		t.Fatalf("bad set: %+v", m)
	}

	// Editing the file by hand reloads it.
	os.WriteFile(path, []byte("[general]\nname = \"ada\"\n"), 0o644)
	if m := c.next(); m.Config.General.Name != "ada" {
		t.Fatalf("after edit: %+v", m)
	}

	// A syntax error reports the line and keeps the last good config.
	os.WriteFile(path, []byte("[general]\nname = \"ada\n"), 0o644)
	if m := c.next(); m.Type != "error" || !strings.Contains(m.Error, "line 2") {
		t.Fatalf("after bad edit: %+v", m)
	}
	c2 := dial(t, sock)
	if m := c2.next(); m.Config.General.Name != "ada" {
		t.Fatalf("new client after bad edit: %+v", m)
	}
	if m := c2.next(); m.Type != "error" {
		t.Fatalf("new client should also get the error: %+v", m)
	}

	// Saving is refused while the file has an error.
	c.send(`{"type":"set","path":"general.name","value":"eve"}`)
	if m := c.next(); m.Type != "error" {
		t.Fatalf("set on broken file: %+v", m)
	}
}

func TestHubCompositorState(t *testing.T) {
	dir := t.TempDir()
	h, err := newHub(filepath.Join(dir, "config.toml"))
	if err != nil {
		t.Fatal(err)
	}
	sock := filepath.Join(dir, "s.sock")
	ln, err := net.Listen("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	go h.serve(ln)

	c := dial(t, sock)
	c.next() // config
	h.setCompositor(compositor.State{FocusedOutput: "eDP-1"})
	line := c.raw()
	if !strings.Contains(line, `"type":"compositor"`) || !strings.Contains(line, `"focused_output":"eDP-1"`) {
		t.Fatalf("broadcast = %s", line)
	}

	// A shell that connects later gets the latest state straight away.
	c2 := dial(t, sock)
	c2.next() // config
	if line := c2.raw(); !strings.Contains(line, `"focused_output":"eDP-1"`) {
		t.Fatalf("late client got %s", line)
	}
}

func (c *testClient) raw() string {
	c.t.Helper()
	c.conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	if !c.r.Scan() {
		c.t.Fatalf("no message: %v", c.r.Err())
	}
	return c.r.Text()
}

type fakeWM struct{ calls chan string }

func (f fakeWM) Run(context.Context, func(compositor.State)) error { return nil }
func (f fakeWM) FocusWorkspace(id uint64) error {
	if id == 99 {
		return errors.New("niri: workspace not found")
	}
	f.calls <- fmt.Sprintf("focus %d", id)
	return nil
}
func (f fakeWM) ToggleOverview() error { f.calls <- "overview"; return nil }
func (f fakeWM) FocusWindow(id uint64) error {
	f.calls <- fmt.Sprintf("window %d", id)
	return nil
}
func (f fakeWM) Quit() error { f.calls <- "quit"; return nil }

func TestHubActions(t *testing.T) {
	dir := t.TempDir()
	h, err := newHub(filepath.Join(dir, "config.toml"))
	if err != nil {
		t.Fatal(err)
	}
	sock := filepath.Join(dir, "s.sock")
	ln, _ := net.Listen("unix", sock)
	defer ln.Close()
	go h.serve(ln)
	c := dial(t, sock)
	c.next() // config

	// Before a compositor is known, actions fail with a message.
	c.send(`{"type":"action","action":"toggle-overview"}`)
	if m := c.next(); m.Type != "error" {
		t.Fatalf("action with no compositor: %+v", m)
	}

	wm := fakeWM{calls: make(chan string, 8)}
	h.setWM(wm)
	for _, tt := range []struct{ msg, want string }{
		{`{"type":"action","action":"focus-workspace","id":3}`, "focus 3"},
		{`{"type":"action","action":"toggle-overview"}`, "overview"},
		{`{"type":"action","action":"quit"}`, "quit"},
		{`{"type":"action","action":"focus-window","id":12}`, "window 12"},
	} {
		c.send(tt.msg)
		select {
		case got := <-wm.calls:
			if got != tt.want {
				t.Errorf("%s → %q, want %q", tt.msg, got, tt.want)
			}
		case <-time.After(2 * time.Second):
			t.Fatalf("%s: no call", tt.msg)
		}
	}

	c.send(`{"type":"action","action":"focus-workspace","id":99}`)
	if m := c.next(); m.Type != "error" || !strings.Contains(m.Error, "workspace not found") {
		t.Fatalf("failed action: %+v", m)
	}
	c.send(`{"type":"action","action":"dance"}`)
	if m := c.next(); m.Type != "error" || !strings.Contains(m.Error, "dance") {
		t.Fatalf("unknown action: %+v", m)
	}
}

func TestHubResolvesWallpaper(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	os.WriteFile(filepath.Join(home, "w.png"), []byte("x"), 0o644)
	path := filepath.Join(home, "config.toml")
	os.WriteFile(path, []byte("[wallpaper]\nfile = \"~/w.png\"\n"), 0o644)
	h, err := newHub(path)
	if err != nil {
		t.Fatal(err)
	}
	if got := h.good.Wallpaper.Path; got != filepath.Join(home, "w.png") {
		t.Errorf("wallpaper path = %q", got)
	}
}

// Any published message type reaches current clients and is replayed to new ones.
func TestHubPublishReplaysLatestOfEachType(t *testing.T) {
	dir := t.TempDir()
	h, err := newHub(filepath.Join(dir, "config.toml"))
	if err != nil {
		t.Fatal(err)
	}
	sock := filepath.Join(dir, "s.sock")
	ln, _ := net.Listen("unix", sock)
	defer ln.Close()
	go h.serve(ln)

	c := dial(t, sock)
	c.next() // config
	h.publish("system", map[string]any{"type": "system", "stats": map[string]any{"cpu": 0.1}})
	h.publish("system", map[string]any{"type": "system", "stats": map[string]any{"cpu": 0.2}})
	c.raw()
	if line := c.raw(); !strings.Contains(line, `"cpu":0.2`) {
		t.Fatalf("second publish = %s", line)
	}
	c2 := dial(t, sock)
	c2.next() // config
	if line := c2.raw(); !strings.Contains(line, `"cpu":0.2`) || strings.Contains(line, `"cpu":0.1`) {
		t.Fatalf("late client got %s, want only the latest", line)
	}
}

// A launch is recorded in the state dir and the new scores are published.
func TestHubRecordsLaunches(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("XDG_STATE_HOME", dir)
	h, err := newHub(filepath.Join(dir, "config.toml"))
	if err != nil {
		t.Fatal(err)
	}
	sock := filepath.Join(dir, "s.sock")
	ln, _ := net.Listen("unix", sock)
	defer ln.Close()
	go h.serve(ln)
	c := dial(t, sock)
	c.next() // config
	c.send(`{"type":"launch","entry":"firefox.desktop"}`)
	if line := c.raw(); !strings.Contains(line, `"type":"usage"`) || !strings.Contains(line, `"firefox.desktop":4`) {
		t.Fatalf("after launch: %s", line)
	}
	if b, err := os.ReadFile(filepath.Join(dir, "nothin", "launcher.json")); err != nil || !strings.Contains(string(b), "firefox.desktop") {
		t.Fatalf("launcher.json: %s, %v", b, err)
	}
}
