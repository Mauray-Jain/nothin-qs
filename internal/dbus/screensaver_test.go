package dbus

import (
	"bufio"
	"os/exec"
	"strings"
	"sync"
	"testing"
	"time"

	godbus "github.com/godbus/dbus/v5"
)

// privateBus starts a throwaway session bus and returns its address.
func privateBus(t *testing.T) string {
	if _, err := exec.LookPath("dbus-daemon"); err != nil {
		t.Skip("dbus-daemon not installed")
	}
	cmd := exec.Command("dbus-daemon", "--session", "--nofork", "--print-address")
	out, _ := cmd.StdoutPipe()
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { cmd.Process.Kill(); cmd.Wait() })
	addr, err := bufio.NewReader(out).ReadString('\n')
	if err != nil {
		t.Fatal(err)
	}
	return strings.TrimSpace(addr)
}

func connect(t *testing.T, addr string) *godbus.Conn {
	c, err := godbus.Connect(addr)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { c.Close() })
	return c
}

type recorder struct {
	mu  sync.Mutex
	got [][]Inhibitor
}

func (r *recorder) set(in []Inhibitor) { r.mu.Lock(); r.got = append(r.got, in); r.mu.Unlock() }
func (r *recorder) last() []Inhibitor {
	r.mu.Lock()
	defer r.mu.Unlock()
	if len(r.got) == 0 {
		return nil
	}
	return r.got[len(r.got)-1]
}

func waitFor(t *testing.T, what string, cond func() bool) {
	t.Helper()
	for range 100 {
		if cond() {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	t.Fatal("timed out waiting for " + what)
}

func TestScreenSaverInhibit(t *testing.T) {
	addr := privateBus(t)
	var rec recorder
	if err := ServeScreenSaver(connect(t, addr), rec.set); err != nil {
		t.Fatal(err)
	}

	app := connect(t, addr)
	obj := app.Object("org.freedesktop.ScreenSaver", "/org/freedesktop/ScreenSaver")
	var cookie uint32
	if err := obj.Call("org.freedesktop.ScreenSaver.Inhibit", 0, "mpv", "Playing video").Store(&cookie); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "one inhibitor", func() bool { l := rec.last(); return len(l) == 1 && l[0].App == "mpv" })

	if err := obj.Call("org.freedesktop.ScreenSaver.UnInhibit", 0, cookie).Err; err != nil {
		t.Fatal(err)
	}
	waitFor(t, "no inhibitors", func() bool { return rec.last() != nil && len(rec.last()) == 0 })

	// The legacy /ScreenSaver path works too, and a client that quits
	// without UnInhibit is forgotten.
	gone := connect(t, addr)
	if err := gone.Object("org.freedesktop.ScreenSaver", "/ScreenSaver").
		Call("org.freedesktop.ScreenSaver.Inhibit", 0, "firefox", "video").Store(&cookie); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "firefox inhibiting", func() bool { return len(rec.last()) == 1 })
	gone.Close()
	waitFor(t, "firefox forgotten", func() bool { return len(rec.last()) == 0 })
}

func TestScreenSaverNameTaken(t *testing.T) {
	addr := privateBus(t)
	other := connect(t, addr)
	if _, err := other.RequestName("org.freedesktop.ScreenSaver", godbus.NameFlagDoNotQueue); err != nil {
		t.Fatal(err)
	}
	if err := ServeScreenSaver(connect(t, addr), func([]Inhibitor) {}); err == nil {
		t.Error("want an error when another program owns org.freedesktop.ScreenSaver")
	}
}
