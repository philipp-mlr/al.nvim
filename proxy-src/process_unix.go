//go:build !windows

package main

import (
	"os/exec"
)

func configureProcess(cmd *exec.Cmd) {
	// No special configuration needed for non-Windows platforms
}
