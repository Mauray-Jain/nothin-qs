package config

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestResolveWallpaper(t *testing.T) {
	home := t.TempDir()
	dir := filepath.Join(home, "Pictures", "Wallpapers")
	os.MkdirAll(dir, 0o755)
	write := func(name string, age time.Duration) {
		p := filepath.Join(dir, name)
		os.WriteFile(p, []byte("x"), 0o644)
		when := time.Now().Add(-age)
		os.Chtimes(p, when, when)
	}
	write("old.jpg", 3*time.Hour)
	write("new.png", time.Hour)
	write("newest.txt", 0) // not an image
	os.Mkdir(filepath.Join(dir, "sub.jpg"), 0o755)

	pick := "old.jpg"
	abs := filepath.Join(home, "elsewhere.webp")
	tests := []struct {
		name string
		w    Wallpaper
		want string
	}{
		{"newest image in dir", Wallpaper{Dir: "~/Pictures/Wallpapers"}, filepath.Join(dir, "new.png")},
		{"file relative to dir", Wallpaper{Dir: "~/Pictures/Wallpapers", File: "old.jpg"}, filepath.Join(dir, "old.jpg")},
		{"absolute file", Wallpaper{Dir: "~/Pictures/Wallpapers", File: abs}, abs},
		{"tilde file", Wallpaper{Dir: "/nope", File: "~/elsewhere.webp"}, abs},
		{"empty dir", Wallpaper{Dir: "~/missing"}, ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := tt.w
			w.Resolve(home)
			if w.Path != tt.want {
				t.Errorf("Path = %q, want %q", w.Path, tt.want)
			}
		})
	}

	// An override with its own file gets its own path; one without inherits.
	w := Wallpaper{Dir: "~/Pictures/Wallpapers", Monitors: map[string]WallpaperOverride{
		"DP-1":     {File: &pick},
		"HDMI-A-1": {},
	}}
	w.Resolve(home)
	if got := w.Monitors["DP-1"].Path; got != filepath.Join(dir, "old.jpg") {
		t.Errorf("DP-1 path = %q", got)
	}
	if got := w.Monitors["HDMI-A-1"].Path; got != "" {
		t.Errorf("HDMI-A-1 should inherit (empty Path), got %q", got)
	}
}
