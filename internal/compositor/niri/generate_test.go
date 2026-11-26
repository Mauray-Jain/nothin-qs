package niri

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Mauray-Jain/nothin-qs/internal/config"
	"github.com/pelletier/go-toml/v2"
)

// Each testdata/kdl/<case>.toml is a [niri] table; <case>.kdl is the file.
func TestGenerateKDL(t *testing.T) {
	cases, _ := filepath.Glob("testdata/kdl/*.toml")
	if len(cases) == 0 {
		t.Fatal("no cases")
	}
	for _, c := range cases {
		name := strings.TrimSuffix(filepath.Base(c), ".toml")
		t.Run(name, func(t *testing.T) {
			b, _ := os.ReadFile(c)
			var n config.Niri
			if err := toml.Unmarshal(b, &n); err != nil {
				t.Fatal(err)
			}
			want, _ := os.ReadFile(strings.TrimSuffix(c, ".toml") + ".kdl")
			got := GenerateKDL(n)
			if got != string(want) {
				t.Errorf("got:\n%s\nwant:\n%s", got, want)
			}
			if _, err := parseKDL(got); err != nil {
				t.Errorf("generated KDL doesn't parse: %v", err)
			}
		})
	}
}

func TestKDLPath(t *testing.T) {
	if got := KDLPath("/home/a/.config/niri/config.kdl"); got != "/home/a/.config/niri/nothin.kdl" {
		t.Errorf("KDLPath = %q", got)
	}
}
