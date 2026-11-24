package daemon

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os/exec"
	"syscall"
	"time"
)

// crashes remembers recent qs exits. Three within ten seconds means give up.
type crashes []time.Time

func (c *crashes) record(now time.Time) bool {
	kept := (*c)[:0]
	for _, t := range *c {
		if now.Sub(t) < 10*time.Second {
			kept = append(kept, t)
		}
	}
	*c = append(kept, now)
	return len(*c) >= 3
}

// supervise runs the command from start until ctx is cancelled, starting it
// again when it exits or when restart fires. started gets each new pid.
func supervise(ctx context.Context, start func() *exec.Cmd, started func(pid int), restart <-chan struct{}, log io.Writer) error {
	var cs crashes
	for {
		cmd := start()
		if err := cmd.Start(); err != nil {
			return fmt.Errorf("start %s: %w", cmd.Path, err)
		}
		fmt.Fprintf(log, "nothin: started %s (pid %d)\n", cmd.Path, cmd.Process.Pid)
		started(cmd.Process.Pid)
		done := make(chan error, 1)
		go func() { done <- cmd.Wait() }()

		select {
		case err := <-done:
			fmt.Fprintf(log, "nothin: qs exited: %v\n", err)
			if cs.record(time.Now()) {
				return errors.New("qs crashed 3 times within 10 seconds, giving up")
			}
		case <-restart:
			stop(cmd, done)
			fmt.Fprintln(log, "nothin: restarting qs")
		case <-ctx.Done():
			stop(cmd, done)
			return nil
		}
	}
}

func stop(cmd *exec.Cmd, done <-chan error) {
	cmd.Process.Signal(syscall.SIGTERM)
	select {
	case <-done:
	case <-time.After(3 * time.Second):
		cmd.Process.Kill()
		<-done
	}
}
