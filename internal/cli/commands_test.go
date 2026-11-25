package cli

import (
	"io/fs"
	"os"
	"reflect"
	"strings"
	"testing"

	"github.com/Mauray-Jain/nothin-qs/shell"
)

func TestIPCCommandsFromQML(t *testing.T) {
	src, _ := os.ReadFile("testdata/Example.qml")
	got := ipcCommands(string(src))
	want := []string{"volume up", "volume down", "volume mute", "lock lock", "lock named <name>"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got  %q\nwant %q", got, want)
	}
}

// The real shell's targets are all listed, and the dev-only test page isn't.
func TestCommandsListTheShellsTargets(t *testing.T) {
	var all []string
	fs.WalkDir(shell.FS, ".", func(p string, d fs.DirEntry, err error) error {
		if strings.HasSuffix(p, ".qml") && !strings.Contains(p, "testpage") {
			b, _ := fs.ReadFile(shell.FS, p)
			all = append(all, ipcCommands(string(b))...)
		}
		return nil
	})
	out := commandList()
	for _, c := range all {
		if !strings.Contains(out, "nothin ipc "+c+"\n") {
			t.Errorf("commands output misses %q", c)
		}
	}
	for _, c := range []string{"launcher toggle", "lock lock", "deck toggle", "volume up", "media playPause"} {
		if !strings.Contains(out, "nothin ipc "+c+"\n") {
			t.Errorf("expected %q in:\n%s", c, out)
		}
	}
	if strings.Contains(out, "testpage") {
		t.Error("the dev test page should not be listed")
	}
}
