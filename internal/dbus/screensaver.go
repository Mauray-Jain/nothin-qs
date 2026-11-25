// Package dbus is nothin's D-Bus side: the org.freedesktop.ScreenSaver
// inhibit service apps use to keep the screen awake, and logind's sleep
// signals so the screen is locked before suspend.
package dbus

import (
	"errors"
	"sort"
	"sync"

	godbus "github.com/godbus/dbus/v5"
)

// Inhibitor is one app keeping the screen awake.
type Inhibitor struct {
	App    string `json:"app"`
	Reason string `json:"reason"`
	sender string
	cookie uint32
}

type screenSaver struct {
	mu       sync.Mutex
	next     uint32
	active   map[uint32]Inhibitor
	onChange func([]Inhibitor)
}

// ServeScreenSaver owns org.freedesktop.ScreenSaver on conn (the session bus)
// and calls onChange with the current inhibitors whenever they change. It
// fails if another program (such as DMS) already owns the name.
func ServeScreenSaver(conn *godbus.Conn, onChange func([]Inhibitor)) error {
	s := &screenSaver{active: map[uint32]Inhibitor{}, onChange: onChange}
	for _, path := range []godbus.ObjectPath{"/org/freedesktop/ScreenSaver", "/ScreenSaver"} {
		if err := conn.Export(s, path, "org.freedesktop.ScreenSaver"); err != nil {
			return err
		}
	}
	reply, err := conn.RequestName("org.freedesktop.ScreenSaver", godbus.NameFlagDoNotQueue)
	if err != nil {
		return err
	}
	if reply != godbus.RequestNameReplyPrimaryOwner {
		return errors.New("org.freedesktop.ScreenSaver is owned by another program")
	}
	// Forget inhibitors of apps that leave the bus without UnInhibit.
	if err := conn.AddMatchSignal(
		godbus.WithMatchInterface("org.freedesktop.DBus"),
		godbus.WithMatchMember("NameOwnerChanged"),
	); err != nil {
		return err
	}
	signals := make(chan *godbus.Signal, 16)
	conn.Signal(signals)
	go func() {
		for sig := range signals {
			if sig.Name == "org.freedesktop.DBus.NameOwnerChanged" && len(sig.Body) == 3 {
				name, _ := sig.Body[0].(string)
				newOwner, _ := sig.Body[2].(string)
				if newOwner == "" {
					s.dropSender(name)
				}
			}
		}
	}()
	return nil
}

func (s *screenSaver) Inhibit(sender godbus.Sender, app, reason string) (uint32, *godbus.Error) {
	s.mu.Lock()
	s.next++
	c := s.next
	s.active[c] = Inhibitor{App: app, Reason: reason, sender: string(sender), cookie: c}
	s.mu.Unlock()
	s.changed()
	return c, nil
}

func (s *screenSaver) UnInhibit(sender godbus.Sender, cookie uint32) *godbus.Error {
	s.mu.Lock()
	delete(s.active, cookie)
	s.mu.Unlock()
	s.changed()
	return nil
}

func (s *screenSaver) dropSender(name string) {
	s.mu.Lock()
	n := len(s.active)
	for c, in := range s.active {
		if in.sender == name {
			delete(s.active, c)
		}
	}
	dropped := len(s.active) != n
	s.mu.Unlock()
	if dropped {
		s.changed()
	}
}

func (s *screenSaver) changed() {
	s.mu.Lock()
	list := make([]Inhibitor, 0, len(s.active))
	for _, in := range s.active {
		list = append(list, in)
	}
	s.mu.Unlock()
	sort.Slice(list, func(i, j int) bool { return list[i].cookie < list[j].cookie })
	s.onChange(list)
}
