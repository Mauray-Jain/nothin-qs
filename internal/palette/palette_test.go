package palette

import (
	"errors"
	"os"
	"strings"
	"testing"
)

func TestParseEveryMatugenShape(t *testing.T) {
	tests := []struct {
		file string
		want Palette
	}{
		{"v4.json", Palette{Accent: "#a8c8ff", Background: "#111318", Surface: "#1d2024", SurfaceHigh: "#282a2f"}},
		{"v4-old.json", Palette{Accent: "#ffb4a9", Background: "#1a1110", Surface: "#271d1b", SurfaceHigh: "#322826"}},
		{"v2.json", Palette{Accent: "#b5d36a", Background: "#13140d", Surface: "#1f2018", SurfaceHigh: "#2a2b22"}},
	}
	for _, tt := range tests {
		b, _ := os.ReadFile("testdata/" + tt.file)
		got, err := Parse(b)
		if err != nil || got != tt.want {
			t.Errorf("%s: %+v, %v", tt.file, got, err)
		}
	}
}

func TestParseRejectsJunk(t *testing.T) {
	for _, s := range []string{`{}`, `{"colors":{}}`, `not json`, `{"colors":{"primary":{"dark":{"color":"blue"}}}}`} {
		if _, err := Parse([]byte(s)); err == nil {
			t.Errorf("Parse(%s) should fail", s)
		}
	}
}

// From reads matugen's output through run; older versions don't know
// --source-color-index, so it tries again without it.
func TestFromRetriesWithoutIndexFlag(t *testing.T) {
	v2, _ := os.ReadFile("testdata/v2.json")
	var calls [][]string
	run := func(args []string) ([]byte, error) {
		calls = append(calls, args)
		for _, a := range args {
			if a == "--source-color-index" {
				return []byte("error: unexpected argument '--source-color-index' found"), errors.New("exit status 2")
			}
		}
		return v2, nil
	}
	p, err := From("/w/a.png", run)
	if err != nil || p.Accent != "#b5d36a" {
		t.Fatalf("got %+v, %v", p, err)
	}
	if len(calls) != 2 || strings.Join(calls[0][:2], " ") != "image /w/a.png" {
		t.Errorf("calls: %v", calls)
	}
}

func TestFromReportsMatugenErrors(t *testing.T) {
	run := func([]string) ([]byte, error) { return []byte("no such file"), errors.New("exit status 1") }
	if _, err := From("/w/missing.png", run); err == nil || !strings.Contains(err.Error(), "no such file") {
		t.Errorf("err = %v", err)
	}
	if _, err := From("", run); err == nil {
		t.Error("no wallpaper: want an error")
	}
}
