// Package daemon is `nothin run`: it supervises qs and owns the runtime files.
package daemon

import (
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"syscall"
	"time"

	"github.com/Mauray-Jain/nothin-qs/internal/compositor"
	"github.com/Mauray-Jain/nothin-qs/internal/compositor/niri"
	"github.com/Mauray-Jain/nothin-qs/internal/sysstat"
)

// RuntimeDir holds nothin.pid, qs.pid and nothin.sock.
func RuntimeDir() string {
	if d := os.Getenv("XDG_RUNTIME_DIR"); d != "" {
		return filepath.Join(d, "nothin")
	}
	return filepath.Join(os.TempDir(), fmt.Sprintf("nothin-%d", os.Getuid()))
}

// StateDir holds the log and runtime data that outlives a session.
func StateDir() string {
	if d := os.Getenv("XDG_STATE_HOME"); d != "" {
		return filepath.Join(d, "nothin")
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".local", "state", "nothin")
}

// ReadPID returns the pid stored in RuntimeDir/name if that process is alive.
func ReadPID(name string) (int, error) {
	b, err := os.ReadFile(filepath.Join(RuntimeDir(), name))
	if err != nil {
		return 0, errors.New("nothin is not running")
	}
	pid, err := strconv.Atoi(string(b))
	if err != nil || syscall.Kill(pid, 0) != nil {
		return 0, errors.New("nothin is not running")
	}
	return pid, nil
}

func writePID(name string, pid int) error {
	return os.WriteFile(filepath.Join(RuntimeDir(), name), []byte(strconv.Itoa(pid)), 0o644)
}

// Run supervises qs on shellDir until SIGINT or SIGTERM. SIGHUP restarts qs.
// If shellDir is empty, the embedded shell is extracted and used.
func Run(shellDir string, embedded fs.FS, dev bool, stderr io.Writer) error {
	if pid, err := ReadPID("nothin.pid"); err == nil {
		return fmt.Errorf("nothin is already running (pid %d)", pid)
	}
	if err := os.MkdirAll(RuntimeDir(), 0o700); err != nil {
		return err
	}
	if err := os.MkdirAll(StateDir(), 0o755); err != nil {
		return err
	}
	logf, err := os.OpenFile(filepath.Join(StateDir(), "nothin.log"), os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o644)
	if err != nil {
		return err
	}
	defer logf.Close()
	log := io.MultiWriter(stderr, logf)

	if shellDir == "" {
		shellDir = filepath.Join(RuntimeDir(), "shell")
		if err := extract(embedded, shellDir); err != nil {
			return fmt.Errorf("extract shell: %w", err)
		}
	}
	if err := writePID("nothin.pid", os.Getpid()); err != nil {
		return err
	}
	defer os.Remove(filepath.Join(RuntimeDir(), "nothin.pid"))
	defer os.Remove(filepath.Join(RuntimeDir(), "qs.pid"))

	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	h, err := newHub(ConfigPath())
	if err != nil {
		return err
	}
	if h.err != "" {
		fmt.Fprintln(log, "nothin:", h.err)
	}
	sock := filepath.Join(RuntimeDir(), "nothin.sock")
	os.Remove(sock)
	ln, err := net.Listen("unix", sock)
	if err != nil {
		return err
	}
	defer ln.Close()
	go h.serve(ln)
	go func() {
		if err := h.watch(ctx); err != nil {
			fmt.Fprintln(log, "nothin: config watch:", err)
		}
	}()
	go followCompositor(ctx, h, log)
	go sampleSystem(ctx, h)
	hup := make(chan os.Signal, 1)
	signal.Notify(hup, syscall.SIGHUP)
	restart := make(chan struct{})
	go func() {
		for range hup {
			restart <- struct{}{}
		}
	}()

	env := append(os.Environ(), "NOTHIN_SOCKET="+sock)
	if dev {
		env = append(env, "NOTHIN_DEV=1")
	}
	start := func() *exec.Cmd {
		cmd := exec.Command("qs", "-p", shellDir)
		cmd.Env = env
		cmd.Stdout, cmd.Stderr = log, log
		return cmd
	}
	started := func(pid int) { writePID("qs.pid", pid) }
	return supervise(ctx, start, started, restart, log)
}

func extract(src fs.FS, dir string) error {
	if err := os.RemoveAll(dir); err != nil {
		return err
	}
	return os.CopyFS(dir, src)
}

// followCompositor feeds the compositor's state to the shell and logs one
// line whenever what it shows changes.
func followCompositor(ctx context.Context, h *hub, log io.Writer) {
	h.mu.Lock()
	setting := h.good.General.Compositor
	h.mu.Unlock()
	name, err := compositor.Detect(setting)
	if err != nil {
		fmt.Fprintln(log, "nothin:", err)
		return
	}
	if name != "niri" {
		fmt.Fprintf(log, "nothin: compositor %q is not supported yet (niri only)\n", name)
		return
	}
	fmt.Fprintln(log, "nothin: compositor niri")
	h.setWM(niri.Niri{})
	last := ""
	err = niri.Niri{}.Run(ctx, func(st compositor.State) {
		h.setCompositor(st)
		if line := niri.Summary(st); line != last {
			fmt.Fprintln(log, "niri:", line)
			last = line
		}
	})
	if ctx.Err() == nil {
		fmt.Fprintln(log, "nothin: niri event stream ended:", err)
	}
}

// sampleSystem publishes CPU, memory, disk and temperature every 2 seconds.
func sampleSystem(ctx context.Context, h *hub) {
	var s sysstat.Sampler
	t := time.NewTicker(2 * time.Second)
	defer t.Stop()
	for {
		h.publish("system", map[string]any{"type": "system", "stats": s.Sample("/")})
		select {
		case <-ctx.Done():
			return
		case <-t.C:
		}
	}
}
