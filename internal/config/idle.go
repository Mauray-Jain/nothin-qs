package config

import "slices"

type Idle struct {
	SuspendMode string    `toml:"suspend_mode" json:"suspend_mode"` // suspend | hibernate | suspend-then-hibernate
	Fade        int       `toml:"fade" json:"fade"`                 // seconds of fade to black before the idle lock; 0 = none
	AC          IdleTimes `toml:"ac" json:"ac"`
	Battery     IdleTimes `toml:"battery" json:"battery"`
}

// IdleTimes are seconds of no input before each step; 0 turns a step off.
type IdleTimes struct {
	Lock          int `toml:"lock" json:"lock"`
	ScreenOff     int `toml:"screen_off" json:"screen_off"`
	Suspend       int `toml:"suspend" json:"suspend"`
	LockScreenOff int `toml:"lock_screen_off" json:"lock_screen_off"` // after the screen is locked
}

func (i Idle) validate() (string, string) {
	if !slices.Contains([]string{"suspend", "hibernate", "suspend-then-hibernate"}, i.SuspendMode) {
		return "idle.suspend_mode", `must be "suspend", "hibernate" or "suspend-then-hibernate"`
	}
	if i.Fade < 0 || i.Fade > 60 {
		return "idle.fade", "must be between 0 and 60 seconds"
	}
	for _, t := range []struct {
		name  string
		times IdleTimes
	}{{"ac", i.AC}, {"battery", i.Battery}} {
		for _, f := range []struct {
			key string
			v   int
		}{{"lock", t.times.Lock}, {"screen_off", t.times.ScreenOff}, {"suspend", t.times.Suspend}, {"lock_screen_off", t.times.LockScreenOff}} {
			if f.v < 0 || f.v > 86400 {
				return "idle." + t.name + "." + f.key, "must be between 0 (off) and 86400 seconds"
			}
		}
	}
	return "", ""
}
