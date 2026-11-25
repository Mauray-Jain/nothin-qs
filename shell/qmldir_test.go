package shell

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"unicode"
)

// A handwritten qmldir replaces Quickshell's generated one, so it must list
// every component in its folder and nothing that isn't there.
func TestQmldirsListEveryComponent(t *testing.T) {
	dirs, _ := filepath.Glob("*/qmldir")
	more, _ := filepath.Glob("*/*/qmldir")
	for _, q := range append(dirs, more...) {
		dir := filepath.Dir(q)
		b, _ := os.ReadFile(q)
		listed := map[string]bool{}
		for _, line := range strings.Split(string(b), "\n") {
			f := strings.Fields(line)
			if len(f) == 0 {
				continue
			}
			file := f[len(f)-1]
			listed[file] = true
			if _, err := os.Stat(filepath.Join(dir, file)); err != nil {
				t.Errorf("%s lists %s, which does not exist", q, file)
			}
		}
		files, _ := filepath.Glob(filepath.Join(dir, "*.qml"))
		for _, f := range files {
			name := filepath.Base(f)
			if unicode.IsUpper(rune(name[0])) && !listed[name] {
				t.Errorf("%s does not list %s", q, name)
			}
		}
	}
}
