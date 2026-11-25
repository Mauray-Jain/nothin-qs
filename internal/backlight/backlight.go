// Package backlight reads the screen brightness from /sys/class/backlight.
// The kernel sends no file events for it, so callers poll.
package backlight

import (
	"errors"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

// Read returns the brightness of the panel's backlight as 0..1. A device
// other than acpi_video* wins, since those are usually inert duplicates.
func Read(root string) (float64, error) {
	devs, _ := filepath.Glob(filepath.Join(root, "sys/class/backlight/*"))
	if len(devs) == 0 {
		return 0, errors.New("no backlight")
	}
	sort.SliceStable(devs, func(i, j int) bool {
		return !strings.HasPrefix(filepath.Base(devs[i]), "acpi_video") &&
			strings.HasPrefix(filepath.Base(devs[j]), "acpi_video")
	})
	cur, err1 := number(filepath.Join(devs[0], "brightness"))
	max, err2 := number(filepath.Join(devs[0], "max_brightness"))
	if err := errors.Join(err1, err2); err != nil {
		return 0, err
	}
	if max == 0 {
		return 0, errors.New("max_brightness is 0")
	}
	return cur / max, nil
}

func number(path string) (float64, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return 0, err
	}
	return strconv.ParseFloat(strings.TrimSpace(string(b)), 64)
}
