package main

import (
	"os"

	"github.com/Mauray-Jain/nothin-qs/internal/cli"
)

func main() {
	os.Exit(cli.Main(os.Args[1:], os.Stderr))
}
