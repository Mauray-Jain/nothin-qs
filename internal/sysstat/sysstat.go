// Package sysstat reads CPU, memory, disk and temperature for the desktop's
// system widget. Paths are read under a root so tests can use fixtures.
package sysstat

import (
	"bufio"
	"errors"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
)

const historyLen = 30

type Stats struct {
	CPU        float64   `json:"cpu"`         // 0..1 since the last sample
	CPUHistory []float64 `json:"cpu_history"` // oldest first, up to 30 samples
	MemUsed    uint64    `json:"mem_used"`    // bytes
	MemTotal   uint64    `json:"mem_total"`
	DiskUsed   uint64    `json:"disk_used"` // bytes, the root filesystem
	DiskTotal  uint64    `json:"disk_total"`
	Temp       float64   `json:"temp"`     // °C
	HasTemp    bool      `json:"has_temp"` // false when no CPU sensor was found
}

// Sampler remembers what CPU usage needs between samples.
type Sampler struct {
	idle, total uint64
	history     []float64
}

// Sample reads everything under root ("/" on a real system).
func (s *Sampler) Sample(root string) Stats {
	var st Stats
	if idle, total, err := cpuTimes(root); err == nil {
		if s.total != 0 {
			st.CPU = usage(s.idle, s.total, idle, total)
			s.push(st.CPU)
		}
		s.idle, s.total = idle, total
	}
	st.CPUHistory = append([]float64{}, s.history...)
	st.MemUsed, st.MemTotal, _ = memory(root)
	var fs syscall.Statfs_t
	if syscall.Statfs(root, &fs) == nil {
		st.DiskTotal = fs.Blocks * uint64(fs.Bsize)
		st.DiskUsed = (fs.Blocks - fs.Bfree) * uint64(fs.Bsize)
	}
	st.Temp, st.HasTemp = temperature(root)
	return st
}

func (s *Sampler) push(v float64) {
	s.history = append(s.history, v)
	if len(s.history) > historyLen {
		s.history = s.history[len(s.history)-historyLen:]
	}
}

// cpuTimes reads the summed "cpu" line of /proc/stat. Idle includes iowait.
func cpuTimes(root string) (idle, total uint64, err error) {
	f, err := os.Open(filepath.Join(root, "proc/stat"))
	if err != nil {
		return 0, 0, err
	}
	defer f.Close()
	sc := bufio.NewScanner(f)
	if !sc.Scan() {
		return 0, 0, errors.New("empty /proc/stat")
	}
	fields := strings.Fields(sc.Text())
	if len(fields) < 5 || fields[0] != "cpu" {
		return 0, 0, errors.New("unexpected /proc/stat")
	}
	for i, f := range fields[1:] {
		v, _ := strconv.ParseUint(f, 10, 64)
		total += v
		if i == 3 || i == 4 { // idle, iowait
			idle += v
		}
	}
	return idle, total, nil
}

func usage(prevIdle, prevTotal, idle, total uint64) float64 {
	dt := total - prevTotal
	if dt == 0 {
		return 0
	}
	return 1 - float64(idle-prevIdle)/float64(dt)
}

// memory returns used (total minus available) and total bytes.
func memory(root string) (used, total uint64, err error) {
	b, err := os.ReadFile(filepath.Join(root, "proc/meminfo"))
	if err != nil {
		return 0, 0, err
	}
	var avail uint64
	for _, line := range strings.Split(string(b), "\n") {
		f := strings.Fields(line)
		if len(f) < 2 {
			continue
		}
		v, _ := strconv.ParseUint(f[1], 10, 64)
		switch f[0] {
		case "MemTotal:":
			total = v * 1024
		case "MemAvailable:":
			avail = v * 1024
		}
	}
	return total - avail, total, nil
}

// CPU sensors in order of preference: hwmon chip names, then thermal zone types.
var (
	hwmonNames = []string{"coretemp", "k10temp", "zenpower", "cpu_thermal", "acpitz"}
	zoneTypes  = []string{"x86_pkg_temp", "cpu-thermal", "acpitz"}
)

// temperature finds the CPU temperature in °C.
func temperature(root string) (float64, bool) {
	if t, ok := firstMatch(filepath.Join(root, "sys/class/hwmon/hwmon*"), "name", "temp1_input", hwmonNames); ok {
		return t, true
	}
	return firstMatch(filepath.Join(root, "sys/class/thermal/thermal_zone*"), "type", "temp", zoneTypes)
}

func firstMatch(glob, nameFile, valueFile string, prefs []string) (float64, bool) {
	dirs, _ := filepath.Glob(glob)
	found := map[string]string{}
	for _, d := range dirs {
		name, err := os.ReadFile(filepath.Join(d, nameFile))
		if err == nil {
			found[strings.TrimSpace(string(name))] = d
		}
	}
	for _, p := range prefs {
		d, ok := found[p]
		if !ok {
			continue
		}
		b, err := os.ReadFile(filepath.Join(d, valueFile))
		if err != nil {
			continue
		}
		milli, err := strconv.ParseFloat(strings.TrimSpace(string(b)), 64)
		if err == nil {
			return milli / 1000, true
		}
	}
	return 0, false
}
