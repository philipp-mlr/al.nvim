//go:build !windows

// Package main implements a debug adapter protocol proxy for AL language server.
// This file contains Unix-specific process configuration.
package main

import (
	"os/exec"
)

func configureProcess(cmd *exec.Cmd) {
	// No special configuration needed for non-Windows platforms
}
