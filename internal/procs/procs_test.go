package procs

import (
	"math"
	"testing"
)

func byPID(list []Proc) map[int]Proc {
	m := map[int]Proc{}
	for _, p := range list {
		m[p.PID] = p
	}
	return m
}

func TestFirstSampleHasNoCPU(t *testing.T) {
	var s Sampler
	got := byPID(s.Sample("testdata/a", 1000))
	if len(got) != 3 {
		t.Fatalf("got %d processes", len(got))
	}
	if got[100].CPU != 0 {
		t.Errorf("cpu on first sample = %v", got[100].CPU)
	}
}

func TestSecondSample(t *testing.T) {
	var s Sampler
	s.Sample("testdata/a", 1000)
	got := byPID(s.Sample("testdata/b", 1000))
	if len(got) != 2 {
		t.Fatalf("process 300 exited: got %d", len(got))
	}
	ff := got[100]
	// 100 of the machine's 200 ticks
	if math.Abs(ff.CPU-0.5) > 1e-9 {
		t.Errorf("firefox cpu = %v, want 0.5", ff.CPU)
	}
	if ff.Name != "Web Content" || ff.Command != "/usr/lib/firefox/firefox -contentproc" {
		t.Errorf("firefox = %+v", ff)
	}
	if ff.Memory != 25000*pageSize || !ff.Mine {
		t.Errorf("firefox memory/mine = %d %v", ff.Memory, ff.Mine)
	}
	if sshd := got[200]; sshd.Mine || math.Abs(sshd.CPU-0.01) > 1e-9 || sshd.Command != "" {
		t.Errorf("sshd = %+v", sshd)
	}
}

func TestStatWithParensInName(t *testing.T) {
	ticks, name, ok := parseStat("42 (a (weird) name) S 1 2 3 4 5 6 7 8 9 10 70 30 0 0")
	if !ok || name != "a (weird) name" || ticks != 100 {
		t.Errorf("parseStat = %d %q %v", ticks, name, ok)
	}
}
