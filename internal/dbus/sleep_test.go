package dbus

import (
	"testing"
	"time"
)

type fakeInhibit struct{ closed bool }

func (f *fakeInhibit) Close() error { f.closed = true; return nil }

func TestSleepWaitsForLockThenReleases(t *testing.T) {
	var fds []*fakeInhibit
	asked := make(chan struct{}, 1)
	s := &sleepLocker{
		inhibit: func() (closer, error) { f := &fakeInhibit{}; fds = append(fds, f); return f, nil },
		lock:    func() { asked <- struct{}{} },
		locked:  make(chan struct{}, 1),
		wait:    time.Second,
	}
	s.start()
	if len(fds) != 1 {
		t.Fatal("should hold a delay inhibitor from the start")
	}

	done := make(chan struct{})
	go func() { s.prepare(true); close(done) }()
	<-asked // the shell was asked to lock
	select {
	case <-done:
		t.Fatal("sleep went ahead before the shell said it was locked")
	case <-time.After(50 * time.Millisecond):
	}
	s.locked <- struct{}{}
	<-done
	if !fds[0].closed {
		t.Error("inhibitor should be released once locked, so sleep can go on")
	}

	s.prepare(false) // resumed: hold a new one for next time
	if len(fds) != 2 || fds[1].closed {
		t.Error("should take a new inhibitor after resume")
	}
}

func TestSleepGivesUpWaiting(t *testing.T) {
	f := &fakeInhibit{}
	s := &sleepLocker{
		inhibit: func() (closer, error) { return f, nil },
		lock:    func() {},
		locked:  make(chan struct{}, 1),
		wait:    50 * time.Millisecond,
	}
	s.start()
	start := time.Now()
	s.prepare(true)
	if !f.closed || time.Since(start) > time.Second {
		t.Error("should release the inhibitor after the wait even if the shell never answers")
	}
}
