package sysstat

import (
	"math"
	"testing"
)

func TestCPUTimes(t *testing.T) {
	idle, total, err := cpuTimes("testdata/root")
	if err != nil {
		t.Fatal(err)
	}
	// idle includes iowait: 8000 + 500; total: 1000+500+8000+500
	if idle != 8500 || total != 10000 {
		t.Errorf("idle, total = %d, %d", idle, total)
	}
}

func TestCPUUsage(t *testing.T) {
	tests := []struct {
		prevIdle, prevTotal, idle, total uint64
		want                             float64
	}{
		{8500, 10000, 8600, 10400, 0.75}, // 300 of 400 busy
		{8500, 10000, 8500, 10000, 0},    // no time passed
	}
	for _, tt := range tests {
		if got := usage(tt.prevIdle, tt.prevTotal, tt.idle, tt.total); math.Abs(got-tt.want) > 1e-9 {
			t.Errorf("usage = %v, want %v", got, tt.want)
		}
	}
}

func TestMemory(t *testing.T) {
	used, total, err := memory("testdata/root")
	if err != nil {
		t.Fatal(err)
	}
	if total != 16000000*1024 || used != 10000000*1024 {
		t.Errorf("used, total = %d, %d", used, total)
	}
}

func TestTemperatureFromHwmon(t *testing.T) {
	got, ok := temperature("testdata/root")
	if !ok || got != 52.125 {
		t.Errorf("temperature = %v, %v; want the CPU sensor (k10temp), not the nvme one", got, ok)
	}
}

func TestTemperatureFromThermalZone(t *testing.T) {
	got, ok := temperature("testdata/zone")
	if !ok || got != 61 {
		t.Errorf("temperature = %v, %v; want x86_pkg_temp over acpitz", got, ok)
	}
}

func TestTemperatureUnknown(t *testing.T) {
	if _, ok := temperature(t.TempDir()); ok {
		t.Error("want no temperature when there are no sensors")
	}
}

func TestHistoryKeepsLastSamples(t *testing.T) {
	var s Sampler
	for i := range 40 {
		s.push(float64(i))
	}
	if len(s.history) != historyLen || s.history[0] != 40-historyLen || s.history[historyLen-1] != 39 {
		t.Errorf("history = %v", s.history)
	}
}

func TestSampleOnThisMachine(t *testing.T) {
	var s Sampler
	st := s.Sample("/")
	if st.MemTotal == 0 || st.DiskTotal == 0 {
		t.Errorf("expected memory and disk on a Linux box: %+v", st)
	}
}
