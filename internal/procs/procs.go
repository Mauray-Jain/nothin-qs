// Package procs lists processes for the dashboard: name, command, CPU share
// since the last sample, memory, and whether they belong to this user.
package procs

import (
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

var pageSize = uint64(os.Getpagesize())

type Proc struct {
	PID     int     `json:"pid"`
	Name    string  `json:"name"`
	Command string  `json:"command"` // empty for kernel threads
	CPU     float64 `json:"cpu"`     // share of the whole machine since the last sample
	Memory  uint64  `json:"memory"`  // resident bytes
	Mine    bool    `json:"mine"`    // owned by uid, so it can be ended
}

// Sampler remembers each process's CPU ticks between samples.
type Sampler struct {
	total uint64
	ticks map[int]uint64
}

// Sample reads every process under root/proc. uid marks which are ours.
func (s *Sampler) Sample(root string, uid int) []Proc {
	total := totalTicks(root)
	dt := total - s.total
	prev := s.ticks
	s.ticks, s.total = map[int]uint64{}, total

	dirs, _ := filepath.Glob(filepath.Join(root, "proc", "[0-9]*"))
	out := []Proc{}
	for _, d := range dirs {
		pid, err := strconv.Atoi(filepath.Base(d))
		if err != nil {
			continue
		}
		stat, err := os.ReadFile(filepath.Join(d, "stat"))
		if err != nil {
			continue // exited while we looked
		}
		ticks, name, ok := parseStat(string(stat))
		if !ok {
			continue
		}
		s.ticks[pid] = ticks
		p := Proc{PID: pid, Name: name, Memory: resident(d), Mine: owner(d) == uid}
		if before, seen := prev[pid]; seen && dt > 0 && ticks >= before {
			p.CPU = float64(ticks-before) / float64(dt)
		}
		if cmd, err := os.ReadFile(filepath.Join(d, "cmdline")); err == nil {
			p.Command = strings.TrimSpace(strings.ReplaceAll(string(cmd), "\x00", " "))
		}
		out = append(out, p)
	}
	return out
}

// parseStat returns utime+stime and the name from /proc/<pid>/stat. The
// name is in brackets and may itself contain brackets or spaces.
func parseStat(s string) (ticks uint64, name string, ok bool) {
	open, close := strings.IndexByte(s, '('), strings.LastIndexByte(s, ')')
	if open < 0 || close < open {
		return 0, "", false
	}
	f := strings.Fields(s[close+1:]) // f[0] is state; utime and stime are fields 14 and 15
	if len(f) < 13 {
		return 0, "", false
	}
	u, err1 := strconv.ParseUint(f[11], 10, 64)
	st, err2 := strconv.ParseUint(f[12], 10, 64)
	if err1 != nil || err2 != nil {
		return 0, "", false
	}
	return u + st, s[open+1 : close], true
}

func totalTicks(root string) uint64 {
	b, err := os.ReadFile(filepath.Join(root, "proc", "stat"))
	if err != nil {
		return 0
	}
	line, _, _ := strings.Cut(string(b), "\n")
	var sum uint64
	for _, f := range strings.Fields(line)[1:] {
		v, _ := strconv.ParseUint(f, 10, 64)
		sum += v
	}
	return sum
}

func resident(dir string) uint64 {
	b, err := os.ReadFile(filepath.Join(dir, "statm"))
	if err != nil {
		return 0
	}
	f := strings.Fields(string(b))
	if len(f) < 2 {
		return 0
	}
	pages, _ := strconv.ParseUint(f[1], 10, 64)
	return pages * pageSize
}

func owner(dir string) int {
	b, err := os.ReadFile(filepath.Join(dir, "status"))
	if err != nil {
		return -1
	}
	for _, line := range strings.Split(string(b), "\n") {
		if strings.HasPrefix(line, "Uid:") {
			f := strings.Fields(line)
			if len(f) > 1 {
				uid, _ := strconv.Atoi(f[1])
				return uid
			}
		}
	}
	return -1
}
