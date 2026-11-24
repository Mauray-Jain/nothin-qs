package daemon

import (
	"bufio"
	"context"
	"encoding/json"
	"net"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type msg struct {
	Type   string `json:"type"`
	Error  string `json:"error"`
	Config struct {
		General struct {
			Name string `json:"name"`
		} `json:"general"`
	} `json:"config"`
}

type testClient struct {
	t    *testing.T
	conn net.Conn
	r    *bufio.Scanner
}

func dial(t *testing.T, sock string) *testClient {
	conn, err := net.Dial("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { conn.Close() })
	return &testClient{t, conn, bufio.NewScanner(conn)}
}

func (c *testClient) next() msg {
	c.t.Helper()
	c.conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	if !c.r.Scan() {
		c.t.Fatalf("no message: %v", c.r.Err())
	}
	var m msg
	if err := json.Unmarshal(c.r.Bytes(), &m); err != nil {
		c.t.Fatal(err)
	}
	return m
}

func (c *testClient) send(s string) {
	c.conn.Write([]byte(s + "\n"))
}

func TestHub(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "nothin", "config.toml")
	sock := filepath.Join(dir, "nothin.sock")
	h, err := newHub(path)
	if err != nil {
		t.Fatal(err)
	}
	ln, err := net.Listen("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go h.serve(ln)
	go h.watch(ctx)

	// First run writes the starter file and sends defaults.
	c := dial(t, sock)
	if m := c.next(); m.Type != "config" || m.Config.General.Name != "" {
		t.Fatalf("first message = %+v", m)
	}
	if b, _ := os.ReadFile(path); !strings.Contains(string(b), "# nothin settings") {
		t.Fatalf("starter not written:\n%s", b)
	}

	// A UI write patches the file in place and is broadcast once.
	c.send(`{"type":"set","path":"general.name","value":"bob"}`)
	if m := c.next(); m.Config.General.Name != "bob" {
		t.Fatalf("after set: %+v", m)
	}
	b, _ := os.ReadFile(path)
	if !strings.Contains(string(b), "# nothin settings") || !strings.Contains(string(b), `name = "bob"`) {
		t.Fatalf("patched file lost comments or value:\n%s", b)
	}

	// A bad set gets an error back, and the file is unchanged.
	c.send(`{"type":"set","path":"theme.accent","value":"red"}`)
	if m := c.next(); m.Type != "error" || !strings.Contains(m.Error, "theme.accent") {
		t.Fatalf("bad set: %+v", m)
	}

	// Editing the file by hand reloads it.
	os.WriteFile(path, []byte("[general]\nname = \"ada\"\n"), 0o644)
	if m := c.next(); m.Config.General.Name != "ada" {
		t.Fatalf("after edit: %+v", m)
	}

	// A syntax error reports the line and keeps the last good config.
	os.WriteFile(path, []byte("[general]\nname = \"ada\n"), 0o644)
	if m := c.next(); m.Type != "error" || !strings.Contains(m.Error, "line 2") {
		t.Fatalf("after bad edit: %+v", m)
	}
	c2 := dial(t, sock)
	if m := c2.next(); m.Config.General.Name != "ada" {
		t.Fatalf("new client after bad edit: %+v", m)
	}
	if m := c2.next(); m.Type != "error" {
		t.Fatalf("new client should also get the error: %+v", m)
	}

	// Saving is refused while the file has an error.
	c.send(`{"type":"set","path":"general.name","value":"eve"}`)
	if m := c.next(); m.Type != "error" {
		t.Fatalf("set on broken file: %+v", m)
	}
}
