package daemon

import (
	"context"
	"io"
	"os/exec"
	"testing"
	"time"
)

func TestCrashesGiveUpAfterThreeInTenSeconds(t *testing.T) {
	t0 := time.Unix(1000, 0)
	tests := []struct {
		name   string
		offs   []time.Duration
		giveUp bool
	}{
		{"one crash", []time.Duration{0}, false},
		{"two crashes", []time.Duration{0, time.Second}, false},
		{"three quick crashes", []time.Duration{0, time.Second, 2 * time.Second}, true},
		{"three spread crashes", []time.Duration{0, 6 * time.Second, 12 * time.Second}, false},
		{"old crash forgotten", []time.Duration{0, 9 * time.Second, 11 * time.Second}, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var c crashes
			var got bool
			for _, o := range tt.offs {
				got = c.record(t0.Add(o))
			}
			if got != tt.giveUp {
				t.Errorf("giveUp = %v, want %v", got, tt.giveUp)
			}
		})
	}
}

func TestSuperviseGivesUpOnCrashLoop(t *testing.T) {
	starts := 0
	start := func() *exec.Cmd { starts++; return exec.Command("sh", "-c", "exit 1") }
	err := supervise(context.Background(), start, func(int) {}, nil, io.Discard)
	if err == nil {
		t.Fatal("want error after crash loop")
	}
	if starts != 3 {
		t.Errorf("starts = %d, want 3", starts)
	}
}

func TestSuperviseRestartIsNotACrash(t *testing.T) {
	starts := 0
	start := func() *exec.Cmd { starts++; return exec.Command("sleep", "10") }
	restart := make(chan struct{})
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan error)
	go func() { done <- supervise(ctx, start, func(int) {}, restart, io.Discard) }()
	for range 4 {
		restart <- struct{}{}
	}
	cancel()
	select {
	case err := <-done:
		if err != nil {
			t.Fatalf("err = %v, want nil on cancel", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("supervise did not stop on cancel")
	}
	if starts != 5 {
		t.Errorf("starts = %d, want 5", starts)
	}
}
