package config

import (
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strings"
	"time"
)

type Wallpaper struct {
	Dir      string                       `toml:"dir" json:"dir"`
	File     string                       `toml:"file" json:"file"` // "" = newest image in Dir
	Effect   string                       `toml:"effect" json:"effect"`
	DotSize  int                          `toml:"dot_size" json:"dot_size"`
	Light    int                          `toml:"light" json:"light"`
	Monitors map[string]WallpaperOverride `toml:"monitors" json:"monitors"`
	Path     string                       `toml:"-" json:"path"` // set by Resolve
}

// WallpaperOverride changes some wallpaper settings on one monitor.
type WallpaperOverride struct {
	File    *string `toml:"file" json:"file"`
	Effect  *string `toml:"effect" json:"effect"`
	DotSize *int    `toml:"dot_size" json:"dot_size"`
	Light   *int    `toml:"light" json:"light"`
	Path    string  `toml:"-" json:"path"` // set by Resolve; "" = use the shared one
}

var effects = []string{"none", "dots", "mono", "color"}

func checkLook(prefix, effect string, dotSize, light int) (string, string) {
	switch {
	case !slices.Contains(effects, effect):
		return prefix + "effect", `must be "none", "dots", "mono" or "color"`
	case dotSize < 4 || dotSize > 64:
		return prefix + "dot_size", "must be between 4 and 64"
	case light < 0 || light > 100:
		return prefix + "light", "must be between 0 and 100"
	}
	return "", ""
}

func (w Wallpaper) validate() (string, string) {
	if p, m := checkLook("wallpaper.", w.Effect, w.DotSize, w.Light); p != "" {
		return p, m
	}
	names := make([]string, 0, len(w.Monitors))
	for n := range w.Monitors {
		names = append(names, n)
	}
	sort.Strings(names)
	for _, n := range names {
		o := w.Monitors[n]
		effect, dot, light := w.Effect, w.DotSize, w.Light
		if o.Effect != nil {
			effect = *o.Effect
		}
		if o.DotSize != nil {
			dot = *o.DotSize
		}
		if o.Light != nil {
			light = *o.Light
		}
		if p, m := checkLook(fmt.Sprintf("wallpaper.monitors.%s.", n), effect, dot, light); p != "" {
			return p, m
		}
	}
	return "", ""
}

// Resolve sets Path (and each override's Path) to the image to show: File if
// set (relative to Dir, or absolute, or ~/...), else the newest image in Dir.
func (w *Wallpaper) Resolve(home string) {
	dir := expand(w.Dir, home)
	w.Path = pick(w.File, dir, home)
	for n, o := range w.Monitors {
		o.Path = ""
		if o.File != nil {
			o.Path = pick(*o.File, dir, home)
		}
		w.Monitors[n] = o
	}
}

func pick(file, dir, home string) string {
	switch {
	case file == "":
		return newestImage(dir)
	case strings.HasPrefix(file, "~/") || filepath.IsAbs(file):
		return expand(file, home)
	}
	return filepath.Join(dir, file)
}

func expand(p, home string) string {
	if p == "~" || strings.HasPrefix(p, "~/") {
		return filepath.Join(home, p[1:])
	}
	return p
}

var imageExts = []string{".jpg", ".jpeg", ".png", ".webp", ".bmp"}

func newestImage(dir string) string {
	if list := listImages(dir); len(list) > 0 {
		return list[0]
	}
	return ""
}

// ExpandHome turns a leading ~ into home.
func ExpandHome(p, home string) string { return expand(p, home) }

// ListImages lists the images in dir (with ~ for home), newest first. A
// missing folder gives an empty list.
func ListImages(dir, home string) []string {
	return listImages(expand(dir, home))
}

func listImages(dir string) []string {
	type img struct {
		path string
		mod  time.Time
	}
	var imgs []img
	entries, _ := os.ReadDir(dir)
	for _, e := range entries {
		if e.IsDir() || !slices.Contains(imageExts, strings.ToLower(filepath.Ext(e.Name()))) {
			continue
		}
		if info, err := e.Info(); err == nil {
			imgs = append(imgs, img{filepath.Join(dir, e.Name()), info.ModTime()})
		}
	}
	sort.SliceStable(imgs, func(i, j int) bool { return imgs[i].mod.After(imgs[j].mod) })
	out := make([]string, len(imgs))
	for i, m := range imgs {
		out[i] = m.path
	}
	return out
}
