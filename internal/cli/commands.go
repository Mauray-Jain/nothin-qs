package cli

import (
	"io/fs"
	"regexp"
	"strings"

	"github.com/Mauray-Jain/nothin-qs/shell"
)

var (
	targetLine = regexp.MustCompile(`^target:\s*"(\w+)"`)
	funcLine   = regexp.MustCompile(`^function\s+(\w+)\(([^)]*)\)`)
)

// ipcCommands finds the IpcHandler blocks in one QML file and returns
// "target function <arg>…" for each function they offer.
func ipcCommands(src string) []string {
	var out []string
	target := ""
	depth, start := 0, -1 // start: depth just inside the current IpcHandler
	for _, raw := range strings.Split(src, "\n") {
		line := strings.TrimSpace(raw)
		if start < 0 && strings.HasPrefix(line, "IpcHandler {") {
			start, target = depth+1, ""
		}
		if start >= 0 && depth == start {
			if m := targetLine.FindStringSubmatch(line); m != nil {
				target = m[1]
			}
			if m := funcLine.FindStringSubmatch(line); m != nil && target != "" {
				cmd := target + " " + m[1]
				for _, arg := range strings.Split(m[2], ",") {
					if name, _, ok := strings.Cut(strings.TrimSpace(arg), ":"); ok {
						cmd += " <" + strings.TrimSpace(name) + ">"
					}
				}
				out = append(out, cmd)
			}
		}
		depth += strings.Count(line, "{") - strings.Count(line, "}")
		if start >= 0 && depth < start {
			start = -1
		}
	}
	return out
}

// commandList is what `nothin commands` prints: every IPC call the shell
// offers, read from the embedded QML so it can't go stale.
func commandList() string {
	var b strings.Builder
	b.WriteString("Every shell action, for scripts or your own keybinds:\n\n")
	fs.WalkDir(shell.FS, ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil || !strings.HasSuffix(p, ".qml") || strings.Contains(p, "testpage") {
			return nil
		}
		src, _ := fs.ReadFile(shell.FS, p)
		for _, c := range ipcCommands(string(src)) {
			b.WriteString("nothin ipc " + c + "\n")
		}
		return nil
	})
	return b.String()
}
