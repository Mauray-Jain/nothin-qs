package backlight

import "testing"

func TestRead(t *testing.T) {
	got, err := Read("testdata/one")
	if err != nil || got != 0.5 {
		t.Errorf("Read = %v, %v; want 0.5", got, err)
	}
}

// A GPU backlight is the real panel; acpi_video is usually a dead duplicate.
func TestPrefersNonACPIDevice(t *testing.T) {
	got, err := Read("testdata/two")
	if err != nil || got != 1 {
		t.Errorf("Read = %v, %v; want amdgpu_bl1 at 1", got, err)
	}
}

func TestNoBacklight(t *testing.T) {
	if _, err := Read(t.TempDir()); err == nil {
		t.Error("want an error without a backlight")
	}
}
