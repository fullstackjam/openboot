package main

import (
	"os"

	"github.com/fullstackjam/openboot/internal/cli"
)

func main() {
	if err := cli.Execute(); err != nil {
		os.Exit(1)
	}
}
