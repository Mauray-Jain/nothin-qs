package daemon

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"os/exec"
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
		{`{"type":"action","action":"power-off-monitors"}`, "monitors off"},
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

// A find request is answered to the asking client only, with its seq.
func TestHubFind(t *testing.T) {
	dir := t.TempDir()
	h, err := newHub(filepath.Join(dir, "config.toml"))
	if err != nil {
		t.Fatal(err)
	}
	h.setFileIndex([]string{"/home/a/Documents/report.pdf", "/home/a/notes.txt"})
	sock := filepath.Join(dir, "s.sock")
	ln, _ := net.Listen("unix", sock)
	defer ln.Close()
	go h.serve(ln)
	c := dial(t, sock)
	c.next() // config
	c.send(`{"type":"find","query":"rep","seq":7}`)
	line := c.raw()
	if !strings.Contains(line, `"type":"files"`) || !strings.Contains(line, `"seq":7`) || !strings.Contains(line, "report.pdf") || strings.Contains(line, "notes") {
		t.Fatalf("find reply: %s", line)
	}
}

// The daemon asks the shell to lock; the shell's "locked" reaches the waiter.
func TestHubLockRoundTrip(t *testing.T) {
	dir := t.TempDir()
	h, err := newHub(filepath.Join(dir, "config.toml"))
	if err != nil {
		t.Fatal(err)
	}
	locked := make(chan struct{}, 1)
	h.setLockedChan(locked)
	sock := filepath.Join(dir, "s.sock")
	ln, _ := net.Listen("unix", sock)
	defer ln.Close()
	go h.serve(ln)
	c := dial(t, sock)
	c.next() // config

	h.requestLock()
	if line := c.raw(); !strings.Contains(line, `"type":"lock"`) {
		t.Fatalf("lock request: %s", line)
	}
	c.send(`{"type":"locked"}`)
	select {
	case <-locked:
	case <-time.After(2 * time.Second):
		t.Fatal("locked never arrived")
	}

	// A lock request is not replayed to a shell that connects later.
	c2 := dial(t, sock)
	c2.next() // config
	c2.conn.SetReadDeadline(time.Now().Add(200 * time.Millisecond))
	if c2.r.Scan() && strings.Contains(c2.r.Text(), `"type":"lock"`) {
		t.Fatal("stale lock request replayed")
	}
}

func (f fakeWM) PowerOffMonitors() error { f.calls <- "monitors off"; return nil }

func TestHubProcsWatchAndKill(t *testing.T) {
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

	if h.watchingProcs() {
		t.Fatal("nobody asked for processes yet")
	}
	c.send(`{"type":"procs-watch","on":true}`)
	waitFor := func(want bool) {
		t.Helper()
		for range 100 {
			if h.watchingProcs() == want {
				return
			}
			time.Sleep(10 * time.Millisecond)
		}
		t.Fatalf("watchingProcs never became %v", want)
	}
	waitFor(true)

	child := exec.Command("sleep", "30")
	if err := child.Start(); err != nil {
		t.Fatal(err)
	}
	done := make(chan error, 1)
	go func() { done <- child.Wait() }()
	c.send(fmt.Sprintf(`{"type":"kill","pid":%d}`, child.Process.Pid))
	select {
	case <-done:
	case <-time.After(3 * time.Second):
		child.Process.Kill()
		t.Fatal("END did not stop the process")
	}

	c.send(`{"type":"kill","pid":1}`) // not ours: the error comes back
	if m := c.next(); m.Type != "error" {
		t.Fatalf("killing pid 1: %+v", m)
	}

	c.conn.Close() // a shell that goes away stops the sampling
	waitFor(false)
}
