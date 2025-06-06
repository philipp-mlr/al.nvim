//go:build windows

package main

import (
	"os/exec"
	"syscall"
)

func configureProcess(cmd *exec.Cmd) {
	// On Windows, prevent opening a new command window
	cmd.SysProcAttr = &syscall.SysProcAttr{
		HideWindow:    true,
		CreationFlags: 0x08000000, // CREATE_NO_WINDOW
	}
}
