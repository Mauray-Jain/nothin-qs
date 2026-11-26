package daemon

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Mauray-Jain/nothin-qs/internal/config"
)

func TestWriteNothinKDL(t *testing.T) {
	path := filepath.Join(t.TempDir(), "nothin.kdl")

	// Nothing set and no file yet: don't create one.
	if err := writeNothinKDL(path, config.Niri{}); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(path); err == nil {
		t.Fatal("created nothin.kdl with nothing in it")
	}

	gaps := 8
	if err := writeNothinKDL(path, config.Niri{Gaps: &gaps}); err != nil {
		t.Fatal(err)
	}
	b, _ := os.ReadFile(path)
	if !strings.Contains(string(b), "gaps 8") {
		t.Fatalf("nothin.kdl:\n%s", b)
	}

	// Unsetting everything keeps the file, but empties it.
	if err := writeNothinKDL(path, config.Niri{}); err != nil {
		t.Fatal(err)
	}
	b, _ = os.ReadFile(path)
	if strings.Contains(string(b), "gaps") {
		t.Fatalf("stale setting left:\n%s", b)
	}
}
