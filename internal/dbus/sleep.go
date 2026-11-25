package dbus

import (
	"os"
	"time"

	godbus "github.com/godbus/dbus/v5"
)

type closer interface{ Close() error }

// sleepLocker holds a logind "delay" inhibitor so the screen can be locked
// before the system sleeps: on PrepareForSleep(true) it asks for a lock,
// waits until the shell says it is locked (or `wait` passes), then lets go so
// sleep continues. After resume it takes a new inhibitor.
type sleepLocker struct {
	inhibit func() (closer, error)
	lock    func()
	locked  chan struct{}
	wait    time.Duration
	held    closer
}

func (s *sleepLocker) start() {
	s.held, _ = s.inhibit()
}

func (s *sleepLocker) prepare(sleeping bool) {
	if !sleeping {
		if s.held == nil {
			s.held, _ = s.inhibit()
		}
		return
	}
	select { // drop a stale "locked" from an earlier manual lock
	case <-s.locked:
	default:
	}
	s.lock()
	select {
	case <-s.locked:
	case <-time.After(s.wait):
	}
	if s.held != nil {
		s.held.Close()
		s.held = nil
	}
}

// Logind connects to the system bus and calls lock before every suspend or
// hibernate, and when something runs `loginctl lock-session`. Send on the
// returned channel once the screen is locked.
func Logind(lock func()) (chan<- struct{}, error) {
	conn, err := godbus.ConnectSystemBus()
	if err != nil {
		return nil, err
	}
	login := conn.Object("org.freedesktop.login1", "/org/freedesktop/login1")
	s := &sleepLocker{
		lock:   lock,
		locked: make(chan struct{}, 1),
		wait:   2 * time.Second,
		inhibit: func() (closer, error) {
			var fd godbus.UnixFD
			err := login.Call("org.freedesktop.login1.Manager.Inhibit", 0,
				"sleep", "nothin", "Lock the screen before sleep", "delay").Store(&fd)
			if err != nil {
				return nil, err
			}
			return os.NewFile(uintptr(fd), "logind-inhibit"), nil
		},
	}
	s.start()

	var session godbus.ObjectPath
	login.Call("org.freedesktop.login1.Manager.GetSessionByPID", 0, uint32(os.Getpid())).Store(&session)

	conn.AddMatchSignal(godbus.WithMatchInterface("org.freedesktop.login1.Manager"), godbus.WithMatchMember("PrepareForSleep"))
	if session != "" {
		conn.AddMatchSignal(godbus.WithMatchObjectPath(session), godbus.WithMatchInterface("org.freedesktop.login1.Session"), godbus.WithMatchMember("Lock"))
	}
	signals := make(chan *godbus.Signal, 8)
	conn.Signal(signals)
	go func() {
		for sig := range signals {
			switch sig.Name {
			case "org.freedesktop.login1.Manager.PrepareForSleep":
				if len(sig.Body) == 1 {
					sleeping, _ := sig.Body[0].(bool)
					s.prepare(sleeping)
				}
			case "org.freedesktop.login1.Session.Lock":
				lock()
			}
		}
	}()
	return s.locked, nil
}
