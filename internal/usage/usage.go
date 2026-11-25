// Package usage remembers which launcher entries are used, and ranks them by
// frecency: each launch counts more the more recent it is.
package usage

import (
	"encoding/json"
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"time"
)

// Store maps an entry id to the times it was launched (newest last).
type Store map[string][]time.Time

const keep = 20 // launches remembered per entry

func (s Store) Record(id string, at time.Time) {
	t := append(s[id], at)
	if len(t) > keep {
		t = t[len(t)-keep:]
	}
	s[id] = t
}

// Scores sums a weight per launch: 4 within a day, 2 within a week, 1 within
// a month, 0.5 before that.
func (s Store) Scores(now time.Time) map[string]float64 {
	out := map[string]float64{}
	for id, times := range s {
		for _, t := range times {
			switch age := now.Sub(t); {
			case age < 24*time.Hour:
				out[id] += 4
			case age < 7*24*time.Hour:
				out[id] += 2
			case age < 30*24*time.Hour:
				out[id] += 1
			default:
				out[id] += 0.5
			}
		}
	}
	return out
}

// Load reads path; a missing file is an empty store.
func Load(path string) (Store, error) {
	b, err := os.ReadFile(path)
	if errors.Is(err, fs.ErrNotExist) {
		return Store{}, nil
	}
	if err != nil {
		return nil, err
	}
	s := Store{}
	return s, json.Unmarshal(b, &s)
}

func (s Store) Save(path string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	b, err := json.Marshal(s)
	if err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, b, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}
