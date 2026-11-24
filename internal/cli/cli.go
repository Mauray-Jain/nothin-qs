// Package cli implements the nothin subcommands.
package cli

import (
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"syscall"
	"time"

	"github.com/Mauray-Jain/nothin-qs/internal/daemon"
	"github.com/Mauray-Jain/nothin-qs/shell"
)

const usage = `usage: nothin <command> [args]

commands:
  run [--dev DIR]          start the shell (DIR: repo checkout, live-reloads QML)
  restart                  restart qs under the running daemon
  kill                     stop nothin and the shell
  ipc <target> <fn> [args] call an IpcHandler in the shell
`

// Main runs the command in args and returns the exit code.
func Main(args []string, stderr io.Writer) int {
	if len(args) == 0 {
		fmt.Fprint(stderr, usage)
		return 2
	}
	var err error
	switch args[0] {
	case "help", "-h", "--help":
		fmt.Fprint(stderr, usage)
		return 0
	case "run":
		err = run(args[1:], stderr)
	case "restart":
		err = signalDaemon(syscall.SIGHUP)
	case "kill":
		err = kill()
	case "ipc":
		if len(args) < 3 {
			fmt.Fprint(stderr, usage)
			return 2
		}
		err = ipc(args[1:])
	default:
		fmt.Fprintf(stderr, "nothin: unknown command %q\n\n%s", args[0], usage)
		return 2
	}
	if err != nil {
		fmt.Fprintln(stderr, "nothin:", err)
		return 1
	}
	return 0
}

func run(args []string, stderr io.Writer) error {
	fl := flag.NewFlagSet("run", flag.ContinueOnError)
	fl.SetOutput(stderr)
	dev := fl.String("dev", "", "load QML from `DIR`/shell instead of the embedded copy")
	if err := fl.Parse(args); err != nil {
		return err
	}
	shellDir := ""
	if *dev != "" {
		abs, err := filepath.Abs(filepath.Join(*dev, "shell"))
		if err != nil {
			return err
		}
		if _, err := os.Stat(filepath.Join(abs, "shell.qml")); err != nil {
			return fmt.Errorf("--dev %s: no shell/shell.qml there", *dev)
		}
		shellDir = abs
	}
	return daemon.Run(shellDir, shell.FS, *dev != "", stderr)
}

func signalDaemon(sig syscall.Signal) error {
	pid, err := daemon.ReadPID("nothin.pid")
	if err != nil {
		return err
	}
	return syscall.Kill(pid, sig)
}

func kill() error {
	if err := signalDaemon(syscall.SIGTERM); err != nil {
		return err
	}
	for range 50 {
		if _, err := daemon.ReadPID("nothin.pid"); err != nil {
			return nil
		}
		time.Sleep(100 * time.Millisecond)
	}
	return fmt.Errorf("nothin did not stop within 5 seconds")
}

func ipc(args []string) error {
	pid, err := daemon.ReadPID("qs.pid")
	if err != nil {
		return err
	}
	cmd := exec.Command("qs", qsIPCArgs(pid, args)...)
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	return cmd.Run()
}

func qsIPCArgs(pid int, args []string) []string {
	return append([]string{"ipc", "--pid", strconv.Itoa(pid), "call"}, args...)
}
