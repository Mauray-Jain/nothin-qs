// Package weather fetches current conditions from Open-Meteo for a place
// name, "lat,lon", or (when empty) the location of the IP address.
package weather

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

type Weather struct {
	Place     string  `json:"place"`
	Temp      float64 `json:"temp"` // °C
	Min       float64 `json:"min"`
	Max       float64 `json:"max"`
	Code      int     `json:"code"` // WMO weather code
	Condition string  `json:"condition"`
	Icon      string  `json:"icon"` // Material Symbols name
	IsDay     bool    `json:"is_day"`
	Wind      float64 `json:"wind"`     // km/h
	Humidity  float64 `json:"humidity"` // %
}

type Client struct {
	GeoURL, IPURL, ForecastURL string
	HTTP                       *http.Client
}

func NewClient() *Client {
	return &Client{
		GeoURL:      "https://geocoding-api.open-meteo.com/v1/search",
		IPURL:       "https://ipinfo.io/json",
		ForecastURL: "https://api.open-meteo.com/v1/forecast",
		HTTP:        &http.Client{Timeout: 10 * time.Second},
	}
}

func (c *Client) Fetch(location string) (Weather, error) {
	place, lat, lon, err := c.locate(strings.TrimSpace(location))
	if err != nil {
		return Weather{}, err
	}
	q := url.Values{
		"latitude":      {fmt.Sprint(lat)},
		"longitude":     {fmt.Sprint(lon)},
		"current":       {"temperature_2m,weather_code,is_day,wind_speed_10m,relative_humidity_2m"},
		"daily":         {"temperature_2m_max,temperature_2m_min"},
		"timezone":      {"auto"},
		"forecast_days": {"1"},
	}
	var f struct {
		Current struct {
			Temp     float64 `json:"temperature_2m"`
			Code     int     `json:"weather_code"`
			IsDay    int     `json:"is_day"`
			Wind     float64 `json:"wind_speed_10m"`
			Humidity float64 `json:"relative_humidity_2m"`
		}
		Daily struct {
			Max []float64 `json:"temperature_2m_max"`
			Min []float64 `json:"temperature_2m_min"`
		}
	}
	if err := c.get(c.ForecastURL+"?"+q.Encode(), &f); err != nil {
		return Weather{}, err
	}
	w := Weather{
		Place: place, Temp: f.Current.Temp, Code: f.Current.Code, IsDay: f.Current.IsDay == 1,
		Wind: f.Current.Wind, Humidity: f.Current.Humidity,
	}
	if len(f.Daily.Max) > 0 && len(f.Daily.Min) > 0 {
		w.Max, w.Min = f.Daily.Max[0], f.Daily.Min[0]
	}
	w.Condition, w.Icon = condition(w.Code, w.IsDay)
	return w, nil
}

func (c *Client) locate(location string) (place string, lat, lon float64, err error) {
	if la, lo, ok := parseLatLon(location); ok {
		return location, la, lo, nil
	}
	if location == "" {
		var ip struct{ City, Loc string }
		if err := c.get(c.IPURL, &ip); err != nil {
			return "", 0, 0, fmt.Errorf("look up location by IP: %w", err)
		}
		la, lo, ok := parseLatLon(ip.Loc)
		if !ok {
			return "", 0, 0, fmt.Errorf("IP lookup gave no location; set weather.location")
		}
		return ip.City, la, lo, nil
	}
	var g struct {
		Results []struct {
			Name      string
			Latitude  float64
			Longitude float64
		}
	}
	if err := c.get(c.GeoURL+"?"+url.Values{"name": {location}, "count": {"1"}}.Encode(), &g); err != nil {
		return "", 0, 0, err
	}
	if len(g.Results) == 0 {
		return "", 0, 0, fmt.Errorf("weather.location %q: no such place", location)
	}
	r := g.Results[0]
	return r.Name, r.Latitude, r.Longitude, nil
}

func parseLatLon(s string) (float64, float64, bool) {
	a, b, ok := strings.Cut(s, ",")
	if !ok {
		return 0, 0, false
	}
	lat, err1 := strconv.ParseFloat(strings.TrimSpace(a), 64)
	lon, err2 := strconv.ParseFloat(strings.TrimSpace(b), 64)
	return lat, lon, err1 == nil && err2 == nil
}

func (c *Client) get(u string, v any) error {
	resp, err := c.HTTP.Get(u)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("%s: %s", u, resp.Status)
	}
	return json.NewDecoder(resp.Body).Decode(v)
}

// condition names a WMO weather code and picks a Material Symbols icon.
func condition(code int, day bool) (string, string) {
	switch {
	case code == 0:
		if day {
			return "Clear", "clear_day"
		}
		return "Clear", "clear_night"
	case code == 1 || code == 2:
		if day {
			return "Partly cloudy", "partly_cloudy_day"
		}
		return "Partly cloudy", "partly_cloudy_night"
	case code == 3:
		return "Overcast", "cloud"
	case code == 45 || code == 48:
		return "Fog", "foggy"
	case code >= 51 && code <= 57:
		return "Drizzle", "rainy"
	case code >= 61 && code <= 67, code >= 80 && code <= 82:
		return "Rain", "rainy"
	case code >= 71 && code <= 77, code == 85 || code == 86:
		return "Snow", "weather_snowy"
	case code == 95 || code == 96 || code == 99:
		return "Thunderstorm", "thunderstorm"
	}
	return "Unknown", "cloud"
}
