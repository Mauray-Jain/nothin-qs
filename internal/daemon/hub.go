package daemon

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"net"
	"os"
	"path/filepath"
	"sync"
	"syscall"
	"time"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor"
	"github.com/Mauray-Jain/nothin-qs/internal/config"
	"github.com/Mauray-Jain/nothin-qs/internal/files"
	"github.com/Mauray-Jain/nothin-qs/internal/usage"
	"github.com/fsnotify/fsnotify"
)

// hub owns config.toml and talks to the shell over the socket in JSON lines.
//
// Out: {"type":"config","config":{…}}, {"type":"error","error":"…"},
// {"type":"lock"} (lock now; the shell answers {"type":"locked"}), and
// published state: {"type":"compositor","state":{…}}, {"type":"system",…},
// {"type":"weather",…}, {"type":"inhibit","inhibitors":[…]},
// {"type":"procs","procs":[…]} (only while a shell sends
// {"type":"procs-watch","on":true}). In also: {"type":"kill","pid","force"}. A new client
// gets the latest published one of each type straight away.
// In:  {"type":"set","path":"theme.accent","value":"#ffffff"} and
//
//	{"type":"action","action":"focus-workspace","id":3} (also
//	"toggle-overview" and "quit"). A failure comes back as an error.
type hub struct {
	path string

	mu           sync.Mutex
	last         []byte                // file contents last loaded or written
	good         config.Config         // last config that loaded
	err          string                // current file error, "" if none
	latest       map[string]any        // last published message of each type
	order        []string              // types in the order first published
	wm           compositor.Compositor // nil until detected
	files        []string              // the home folder index for file search
	locked       chan<- struct{}       // told when the shell reports it locked
	procWatchers map[net.Conn]bool     // clients that want the process list
	clients      map[net.Conn]bool
}

// newHub loads path, writing the starter file if it doesn't exist.
func newHub(path string) (*hub, error) {
	h := &hub{path: path, good: config.Defaults(), clients: map[net.Conn]bool{}, latest: map[string]any{}, procWatchers: map[net.Conn]bool{}}
	b, err := os.ReadFile(path)
	if errors.Is(err, fs.ErrNotExist) {
		b = []byte(config.Starter)
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			return nil, err
		}
		if err := writeAtomic(path, b); err != nil {
			return nil, err
		}
	} else if err != nil {
		return nil, err
	}
	h.load(b)
	return h, nil
}

// ConfigPath is ~/.config/nothin/config.toml (honouring XDG_CONFIG_HOME).
func ConfigPath() string {
	d, err := os.UserConfigDir()
	if err != nil {
		d = filepath.Join(os.Getenv("HOME"), ".config")
	}
	return filepath.Join(d, "nothin", "config.toml")
}

// load takes new file contents; the caller holds mu or owns h exclusively.
func (h *hub) load(b []byte) {
	h.last = b
	c, err := config.Load(b)
	if err != nil {
		h.err = "config.toml " + err.Error()
		return
	}
	home, _ := os.UserHomeDir()
	c.Wallpaper.Resolve(home)
	h.good, h.err = c, ""
}

func (h *hub) configMsg() any { return map[string]any{"type": "config", "config": h.good} }
func errorMsg(s string) any   { return map[string]any{"type": "error", "error": s} }

// reload rereads the file and broadcasts the result. Contents it has already
// seen (including its own writes) are ignored.
func (h *hub) reload() {
	b, err := os.ReadFile(h.path)
	if err != nil {
		return
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	if bytes.Equal(b, h.last) {
		return
	}
	h.load(b)
	if h.err != "" {
		h.broadcast(errorMsg(h.err))
		return
	}
	h.broadcast(h.configMsg())
}

// publish sends msg to every client and keeps it as the latest of its type.
func (h *hub) publish(typ string, msg any) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if _, ok := h.latest[typ]; !ok {
		h.order = append(h.order, typ)
	}
	h.latest[typ] = msg
	h.broadcast(msg)
}

func (h *hub) setCompositor(st compositor.State) {
	h.publish("compositor", compositorMsg(st))
}

func (h *hub) setWM(wm compositor.Compositor) {
	h.mu.Lock()
	h.wm = wm
	h.mu.Unlock()
}

func (h *hub) action(name string, id uint64) error {
	h.mu.Lock()
	wm := h.wm
	h.mu.Unlock()
	if wm == nil {
		return errors.New("no supported compositor is running")
	}
	switch name {
	case "focus-workspace":
		return wm.FocusWorkspace(id)
	case "focus-window":
		return wm.FocusWindow(id)
	case "toggle-overview":
		return wm.ToggleOverview()
	case "quit":
		return wm.Quit()
	case "power-off-monitors":
		return wm.PowerOffMonitors()
	}
	return fmt.Errorf("unknown action %q", name)
}

func (h *hub) setLockedChan(ch chan<- struct{}) {
	h.mu.Lock()
	h.locked = ch
	h.mu.Unlock()
}

// requestLock asks the shell to lock the screen. It is broadcast, not
// published, so a shell that connects later doesn't lock on a stale request.
func (h *hub) requestLock() {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.broadcast(map[string]any{"type": "lock"})
}

// watchingProcs reports whether any shell has the process list open.
func (h *hub) watchingProcs() bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	return len(h.procWatchers) > 0
}

// killProc ends a process: SIGTERM, or SIGKILL with force. The kernel refuses
// other users' processes, and that error goes back to the shell.
func killProc(pid int, force bool) error {
	if pid <= 1 {
		return fmt.Errorf("won't end process %d", pid)
	}
	sig := syscall.SIGTERM
	if force {
		sig = syscall.SIGKILL
	}
	if err := syscall.Kill(pid, sig); err != nil {
		return fmt.Errorf("end process %d: %w", pid, err)
	}
	return nil
}

func (h *hub) setFileIndex(idx []string) {
	h.mu.Lock()
	h.files = idx
	h.mu.Unlock()
}

// find answers a launcher file search; seq lets the shell drop stale replies.
func (h *hub) find(query string, seq int) any {
	h.mu.Lock()
	idx := h.files
	h.mu.Unlock()
	return map[string]any{"type": "files", "seq": seq, "query": query, "results": files.Search(idx, query, 20)}
}

// launch records a launcher entry being used and publishes the new scores.
func (h *hub) launch(id string) error {
	if id == "" {
		return errors.New("launch: no id")
	}
	s := loadUsage()
	s.Record(id, time.Now())
	if err := s.Save(usagePath()); err != nil {
		return err
	}
	h.publishUsage(s)
	return nil
}

func usagePath() string { return filepath.Join(StateDir(), "launcher.json") }

// loadUsage reads the launch history; a broken file starts over rather than
// blocking launches.
func loadUsage() usage.Store {
	s, err := usage.Load(usagePath())
	if err != nil {
		return usage.Store{}
	}
	return s
}

func (h *hub) publishUsage(s usage.Store) {
	h.publish("usage", map[string]any{"type": "usage", "scores": s.Scores(time.Now())})
}

func compositorMsg(st compositor.State) any {
	return map[string]any{"type": "compositor", "state": st}
}

func (h *hub) set(path string, value json.RawMessage) error {
	h.mu.Lock()
	defer h.mu.Unlock()
	b, err := os.ReadFile(h.path)
	if err != nil {
		return err
	}
	out, err := config.Patch(b, path, value)
	if err != nil {
		return err
	}
	if err := writeAtomic(h.path, out); err != nil {
		return err
	}
	h.load(out)
	h.broadcast(h.configMsg())
	return nil
}

// broadcast sends v to every client; the caller holds mu.
func (h *hub) broadcast(v any) {
	line, _ := json.Marshal(v)
	line = append(line, '\n')
	for c := range h.clients {
		c.SetWriteDeadline(time.Now().Add(time.Second))
		if _, err := c.Write(line); err != nil {
			c.Close()
			delete(h.clients, c)
		}
	}
}

func (h *hub) serve(ln net.Listener) {
	for {
		c, err := ln.Accept()
		if err != nil {
			return
		}
		go h.handle(c)
	}
}

func (h *hub) handle(c net.Conn) {
	h.mu.Lock()
	h.clients[c] = true
	first := []any{h.configMsg()}
	if h.err != "" {
		first = append(first, errorMsg(h.err))
	}
	for _, typ := range h.order {
		first = append(first, h.latest[typ])
	}
	for _, m := range first {
		line, _ := json.Marshal(m)
		c.Write(append(line, '\n'))
	}
	h.mu.Unlock()

	s := bufio.NewScanner(c)
	for s.Scan() {
		var in struct {
			Type   string          `json:"type"`
			Path   string          `json:"path"`
			Value  json.RawMessage `json:"value"`
			Action string          `json:"action"`
			ID     uint64          `json:"id"`
			Entry  string          `json:"entry"`
			Query  string          `json:"query"`
			Seq    int             `json:"seq"`
			On     bool            `json:"on"`
			PID    int             `json:"pid"`
			Force  bool            `json:"force"`
		}
		if json.Unmarshal(s.Bytes(), &in) != nil {
			continue
		}
		var err error
		switch in.Type {
		case "set":
			err = h.set(in.Path, in.Value)
		case "action":
			err = h.action(in.Action, in.ID)
		case "launch":
			err = h.launch(in.Entry)
		case "procs-watch":
			h.mu.Lock()
			if in.On {
				h.procWatchers[c] = true
			} else {
				delete(h.procWatchers, c)
			}
			h.mu.Unlock()
		case "kill":
			err = killProc(in.PID, in.Force)
		case "locked":
			h.mu.Lock()
			ch := h.locked
			h.mu.Unlock()
			if ch != nil {
				select {
				case ch <- struct{}{}:
				default:
				}
			}
		case "find":
			line, _ := json.Marshal(h.find(in.Query, in.Seq))
			h.mu.Lock()
			c.Write(append(line, '\n'))
			h.mu.Unlock()
		}
		if err != nil {
			line, _ := json.Marshal(errorMsg(err.Error()))
			h.mu.Lock()
			c.Write(append(line, '\n'))
			h.mu.Unlock()
		}
	}
	h.mu.Lock()
	delete(h.clients, c)
	delete(h.procWatchers, c)
	h.mu.Unlock()
	c.Close()
}

// watch reloads the file ~50ms after the last change to it. It watches the
// directory because editors often replace the file rather than write to it.
func (h *hub) watch(ctx context.Context) error {
	w, err := fsnotify.NewWatcher()
	if err != nil {
		return err
	}
	defer w.Close()
	if err := w.Add(filepath.Dir(h.path)); err != nil {
		return err
	}
	debounce := time.NewTimer(time.Hour)
	debounce.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case ev := <-w.Events:
			if filepath.Clean(ev.Name) == filepath.Clean(h.path) {
				debounce.Reset(50 * time.Millisecond)
			}
		case <-w.Errors:
		case <-debounce.C:
			h.reload()
		}
	}
}

func writeAtomic(path string, b []byte) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, b, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}
