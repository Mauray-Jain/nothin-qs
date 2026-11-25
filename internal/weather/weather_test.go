package weather

import (
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
)

// server answers like Open-Meteo and ipinfo, from testdata, and records queries.
func server(t *testing.T, geocode string) (*Client, *[]string) {
	var seen []string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		seen = append(seen, r.URL.Path+"?"+r.URL.RawQuery)
		file := map[string]string{"/geo": geocode, "/ip": "ipinfo.json", "/forecast": "forecast.json"}[r.URL.Path]
		b, err := os.ReadFile("testdata/" + file)
		if err != nil {
			http.Error(w, "no", 404)
			return
		}
		w.Write(b)
	}))
	t.Cleanup(srv.Close)
	return &Client{GeoURL: srv.URL + "/geo", IPURL: srv.URL + "/ip", ForecastURL: srv.URL + "/forecast", HTTP: srv.Client()}, &seen
}

func TestFetchByPlaceName(t *testing.T) {
	c, seen := server(t, "geocode.json")
	w, err := c.Fetch("Pune")
	if err != nil {
		t.Fatal(err)
	}
	want := Weather{Place: "Pune", Temp: 17.4, Min: 15.2, Max: 29.8, Code: 2, Condition: "Partly cloudy",
		Icon: "partly_cloudy_night", IsDay: false, Wind: 6.1, Humidity: 71}
	if w != want {
		t.Errorf("got  %+v\nwant %+v", w, want)
	}
	if !strings.Contains((*seen)[0], "name=Pune") || !strings.Contains((*seen)[1], "latitude=18.51957") {
		t.Errorf("queries: %v", *seen)
	}
}

func TestFetchByCoordinates(t *testing.T) {
	c, seen := server(t, "geocode.json")
	w, err := c.Fetch("18.52, 73.86")
	if err != nil {
		t.Fatal(err)
	}
	if len(*seen) != 1 || !strings.Contains((*seen)[0], "latitude=18.52") {
		t.Errorf("coordinates should skip geocoding: %v", *seen)
	}
	if w.Place != "18.52, 73.86" {
		t.Errorf("place = %q", w.Place)
	}
}

func TestFetchByIP(t *testing.T) {
	c, seen := server(t, "geocode.json")
	w, err := c.Fetch("")
	if err != nil {
		t.Fatal(err)
	}
	if w.Place != "Pune" || !strings.HasPrefix((*seen)[0], "/ip") || !strings.Contains((*seen)[1], "latitude=18.5196") {
		t.Errorf("place %q, queries %v", w.Place, *seen)
	}
}

func TestUnknownPlace(t *testing.T) {
	c, _ := server(t, "geocode_empty.json")
	if _, err := c.Fetch("Atlantis"); err == nil || !strings.Contains(err.Error(), "Atlantis") {
		t.Errorf("err = %v", err)
	}
}

func TestConditions(t *testing.T) {
	tests := []struct {
		code      int
		day       bool
		condition string
		icon      string
	}{
		{0, true, "Clear", "clear_day"},
		{0, false, "Clear", "clear_night"},
		{3, true, "Overcast", "cloud"},
		{45, true, "Fog", "foggy"},
		{63, true, "Rain", "rainy"},
		{75, true, "Snow", "weather_snowy"},
		{95, true, "Thunderstorm", "thunderstorm"},
		{999, true, "Unknown", "cloud"},
	}
	for _, tt := range tests {
		c, i := condition(tt.code, tt.day)
		if c != tt.condition || i != tt.icon {
			t.Errorf("condition(%d, %v) = %q, %q; want %q, %q", tt.code, tt.day, c, i, tt.condition, tt.icon)
		}
	}
}
