package files

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func tree(t *testing.T) string {
	root := t.TempDir()
	for _, p := range []string{
		"Documents/report.pdf",
		"Documents/old/report-2019.pdf",
		"Documents/notes.txt",
		"Pictures/reports/scan.png",
		".config/secret/report.txt",
		"code/app/node_modules/report/index.js",
		"code/app/main.go",
	} {
		full := filepath.Join(root, p)
		os.MkdirAll(filepath.Dir(full), 0o755)
		os.WriteFile(full, nil, 0o644)
	}
	return root
}

func TestIndexSkipsHiddenAndNodeModules(t *testing.T) {
	root := tree(t)
	idx := Index(root, 1000)
	for _, p := range idx {
		if filepath.Base(filepath.Dir(p)) == "secret" || filepath.Base(p) == "index.js" {
			t.Errorf("indexed %s", p)
		}
	}
	// 5 files and 6 folders (Documents, Documents/old, Pictures, Pictures/reports, code, code/app)
	if len(idx) != 11 {
		t.Errorf("index has %d entries: %v", len(idx), idx)
	}
}

func TestIndexStopsAtLimit(t *testing.T) {
	if got := len(Index(tree(t), 3)); got != 3 {
		t.Errorf("len = %d, want 3", got)
	}
}

func TestSearchRanking(t *testing.T) {
	root := tree(t)
	idx := Index(root, 1000)
	got := Search(idx, "report", 10)
	rel := make([]string, len(got))
	for i, p := range got {
		rel[i], _ = filepath.Rel(root, p)
	}
	want := []string{
		"Pictures/reports",              // name starts with it; shortest path first
		"Documents/report.pdf",          // name starts with it
		"Documents/old/report-2019.pdf", // name starts with it, longer path
		"Pictures/reports/scan.png",     // only the folder matches
	}
	if !reflect.DeepEqual(rel, want) {
		t.Errorf("got  %v\nwant %v", rel, want)
	}
}

func TestSearchIsCaseInsensitiveAndLimited(t *testing.T) {
	idx := Index(tree(t), 1000)
	if got := Search(idx, "REPORT", 2); len(got) != 2 {
		t.Errorf("got %v", got)
	}
	if got := Search(idx, "", 10); len(got) != 0 {
		t.Errorf("empty query should find nothing, got %v", got)
	}
}
