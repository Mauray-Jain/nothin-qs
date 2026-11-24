package cli

import (
	"io"
	"slices"
	"testing"
)

func TestMainExitCodes(t *testing.T) {
	tests := []struct {
		args []string
		want int
	}{
		{nil, 2},
		{[]string{"nope"}, 2},
		{[]string{"help"}, 0},
		{[]string{"ipc"}, 2},
		{[]string{"ipc", "target"}, 2},
	}
	for _, tt := range tests {
		if got := Main(tt.args, io.Discard); got != tt.want {
			t.Errorf("Main(%q) = %d, want %d", tt.args, got, tt.want)
		}
	}
}

func TestQsIPCArgs(t *testing.T) {
	got := qsIPCArgs(42, []string{"testpage", "toggle", "a b"})
	want := []string{"ipc", "--pid", "42", "call", "testpage", "toggle", "a b"}
	if !slices.Equal(got, want) {
		t.Errorf("got %q, want %q", got, want)
	}
}
