package usage

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

var now = time.Date(2026, 11, 26, 12, 0, 0, 0, time.UTC)

func TestScoreFavoursRecentAndFrequent(t *testing.T) {
	s := Store{}
	s.Record("firefox", now.Add(-2*time.Hour))
	s.Record("firefox", now.Add(-1*time.Hour))
	s.Record("gimp", now.Add(-40*24*time.Hour))
	s.Record("gimp", now.Add(-40*24*time.Hour))
	s.Record("gimp", now.Add(-40*24*time.Hour))
	s.Record("kitty", now.Add(-3*24*time.Hour))
	sc := s.Scores(now)
	if !(sc["firefox"] > sc["kitty"] && sc["kitty"] > sc["gimp"]) {
		t.Errorf("scores %v: want firefox (2 today) > kitty (1 this week) > gimp (3, long ago)", sc)
	}
}

func TestScoreWeights(t *testing.T) {
	tests := []struct {
		age  time.Duration
		want float64
	}{
		{time.Hour, 4},
		{3 * 24 * time.Hour, 2},
		{20 * 24 * time.Hour, 1},
		{100 * 24 * time.Hour, 0.5},
	}
	for _, tt := range tests {
		s := Store{}
		s.Record("a", now.Add(-tt.age))
		if got := s.Scores(now)["a"]; got != tt.want {
			t.Errorf("age %v: score %v, want %v", tt.age, got, tt.want)
		}
	}
}

func TestSaveAndLoad(t *testing.T) {
	path := filepath.Join(t.TempDir(), "nested", "launcher.json")
	s := Store{}
	s.Record("firefox", now)
	if err := s.Save(path); err != nil {
		t.Fatal(err)
	}
	got, err := Load(path)
	if err != nil {
		t.Fatal(err)
	}
	if got.Scores(now)["firefox"] != 4 {
		t.Errorf("loaded %v", got)
	}
}

func TestLoadMissingFileIsEmpty(t *testing.T) {
	s, err := Load(filepath.Join(t.TempDir(), "none.json"))
	if err != nil || len(s) != 0 {
		t.Errorf("Load missing = %v, %v", s, err)
	}
}

func TestLoadBrokenFileIsAnError(t *testing.T) {
	path := filepath.Join(t.TempDir(), "bad.json")
	os.WriteFile(path, []byte("{"), 0o644)
	if _, err := Load(path); err == nil {
		t.Error("want an error for a broken file")
	}
}
