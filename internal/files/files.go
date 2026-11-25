// Package files indexes the home folder for the launcher's file search.
package files

import (
	"io/fs"
	"path/filepath"
	"sort"
	"strings"
)

// Index lists files and folders under root, skipping hidden ones and
// node_modules, up to limit entries.
func Index(root string, limit int) []string {
	var out []string
	stop := fs.SkipAll
	filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
		if err != nil || p == root {
			return nil
		}
		name := d.Name()
		if strings.HasPrefix(name, ".") || name == "node_modules" {
			if d.IsDir() {
				return fs.SkipDir
			}
			return nil
		}
		out = append(out, p)
		if len(out) >= limit {
			return stop
		}
		return nil
	})
	return out
}

// Search ranks indexed paths for query (case-insensitive): the name starts
// with it, then the name contains it, then only a folder above contains it;
// shorter paths first within each.
func Search(index []string, query string, limit int) []string {
	q := strings.ToLower(strings.TrimSpace(query))
	if q == "" {
		return nil
	}
	type hit struct {
		path string
		tier int
	}
	var hits []hit
	for _, p := range index {
		lp := strings.ToLower(p)
		name := strings.ToLower(filepath.Base(p))
		switch {
		case strings.HasPrefix(name, q):
			hits = append(hits, hit{p, 0})
		case strings.Contains(name, q):
			hits = append(hits, hit{p, 1})
		case strings.Contains(lp, q):
			hits = append(hits, hit{p, 2})
		}
	}
	sort.SliceStable(hits, func(i, j int) bool {
		a, b := hits[i], hits[j]
		if a.tier != b.tier {
			return a.tier < b.tier
		}
		if len(a.path) != len(b.path) {
			return len(a.path) < len(b.path)
		}
		return a.path < b.path
	})
	out := []string{}
	for i := 0; i < len(hits) && i < limit; i++ {
		out = append(out, hits[i].path)
	}
	return out
}
