// Package main implements a debug adapter protocol proxy for AL language server.
// This proxy intercepts DAP messages between the client and AL EditorServices,
// modifying responses to ensure proper command field handling.
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
)

// Constants for magic numbers and repeated strings
const (
	bufferSize          = 4096
	minArgsRequired     = 2
	contentLengthPrefix = "Content-Length: "
	headerSeparatorLF   = "\n\n"
	headerSeparatorCRLF = "\n\r\n"
	separatorLFLength   = 2
	separatorCRLFLength = 3
)

// DAPMessage represents a Debug Adapter Protocol message
type DAPMessage struct {
	RequestSeq *int        `json:"request_seq,omitempty"`
	Success    *bool       `json:"success,omitempty"`
	Type       string      `json:"type,omitempty"`
	Command    string      `json:"command,omitempty"`
	Body       interface{} `json:"body,omitempty"`
}

// Global channel to signal termination
var terminateSignal = make(chan bool, 1)

func main() {
	// Check if we have arguments to pass to dotnet
	if len(os.Args) < minArgsRequired {
		os.Exit(1)
	}

	// Prepare the command: dotnet + all arguments passed to this proxy
	args := append([]string{"dotnet"}, os.Args[1:]...)
	// #nosec G204 - Command arguments are intentionally passed from command line
	cmd := exec.Command(args[0], args[1:]...)

	// Create pipes for communication
	stdinPipe, err := cmd.StdinPipe()
	if err != nil {
		os.Exit(1)
	}
	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		os.Exit(1)
	}
	cmd.Stderr = os.Stderr

	// Configure process attributes (Windows-specific settings handled in separate function)
	configureProcess(cmd)

	// Start the AL EditorServices process
	if err := cmd.Start(); err != nil {
		os.Exit(1)
	}

	// Set up signal handling for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	// Handle cleanup in a goroutine
	go func() {
		<-sigChan
		if cmd.Process != nil {
			_ = cmd.Process.Kill() // Ignore error as process may have already exited
		}
		os.Exit(0)
	}()

	// Start goroutines to handle input/output
	go handleInput(stdinPipe)
	go handleOutput(stdoutPipe)

	// Wait for either the AL EditorServices process to complete or termination signal
	done := make(chan bool)
	go func() {
		_ = cmd.Wait() // Ignore error, we just need to know when process completes
		done <- true
	}()

	select {
	case <-done:
		// Process completed normally
	case <-terminateSignal:
		// Received terminate command, give a moment for any final responses
		// then exit gracefully
		if cmd.Process != nil {
			_ = cmd.Process.Kill() // Ignore error as process may have already exited
		}
	}
}

// handleInput processes input from stdin and forwards to the process
func handleInput(io.writer io.WriteCloser) {
	defer io.writer.Close()

	// Read all data and process it as a stream, similar to handleOutput
	buffer := make([]byte, bufferSize)
	var accumulated []byte

	for {
		n, err := os.Stdin.Read(buffer)
		if n > 0 {
			accumulated = append(accumulated, buffer[:n]...)

			// Process complete messages from accumulated data
			for {
				processed, remaining := processInputBuffer(accumulated, io.writer)
				if processed == nil {
					break // No complete message found
				}

				accumulated = remaining
			}
		}

		if err != nil {
			if err == io.EOF {
				// Forward any remaining data
				if len(accumulated) > 0 {
					if _, writeErr := io.writer.Write(accumulated); writeErr != nil {
						// Error writing to pipe, connection may be closed
						break
					}
				}
				break
			}
			continue
		}
	}
}

// processInputBuffer looks for complete DAP messages in the input buffer and processes them
func processInputBuffer(data []byte, io.writer io.WriteCloser) (processed, remaining []byte) {
	dataStr := string(data)

	// Look for Content-Length header
	idx := strings.Index(dataStr, contentLengthPrefix)
	if idx == -1 {
		// No Content-Length found, return first part as-is if we have a complete line
		if newlineIdx := strings.Index(dataStr, "\n"); newlineIdx != -1 {
			if _, err := io.writer.Write(data[:newlineIdx+1]); err != nil {
				// Error writing to pipe, connection may be closed
				return data[:newlineIdx+1], data[newlineIdx+1:]
			}
			return data[:newlineIdx+1], data[newlineIdx+1:]
		}
		return nil, data // Wait for more data
	}

	// Parse content length
	headerEnd := strings.Index(dataStr[idx:], "\n")
	if headerEnd == -1 {
		return nil, data // Wait for complete header
	}
	headerEnd += idx

	lengthStr := strings.TrimSpace(dataStr[idx+len(contentLengthPrefix) : headerEnd])
	contentLength := 0
	if _, err := fmt.Sscanf(lengthStr, "%d", &contentLength); err != nil {
		// Can't parse length, forward up to this point
		_, _ = io.writer.Write(data[:headerEnd+1]) // Ignore write errors, connection may be closed
		return data[:headerEnd+1], data[headerEnd+1:]
	}

	// Find the start of JSON content (after the empty line)
	jsonStart := strings.Index(dataStr[headerEnd:], headerSeparatorLF)
	if jsonStart == -1 {
		jsonStart = strings.Index(dataStr[headerEnd:], headerSeparatorCRLF)
		if jsonStart == -1 {
			return nil, data // Wait for complete separator
		}
		jsonStart += headerEnd + separatorCRLFLength
	} else {
		jsonStart += headerEnd + separatorLFLength
	}

	// Check if we have the complete JSON content
	if len(data) < jsonStart+contentLength {
		return nil, data // Wait for complete message
	}

	// Extract and check the JSON content for terminate command
	jsonContent := string(data[jsonStart : jsonStart+contentLength])
	checkForTerminate(jsonContent)

	// Forward the complete message unchanged
	messageEnd := jsonStart + contentLength
	_, _ = io.writer.Write(data[:messageEnd]) // Ignore write errors, connection may be closed

	return data[:messageEnd], data[messageEnd:]
}

// checkForTerminate checks if the message is a terminate request
func checkForTerminate(jsonContent string) {
	var msg DAPMessage

	// Try to parse the JSON
	if err := json.Unmarshal([]byte(jsonContent), &msg); err != nil {
		return // If parsing fails, ignore
	}

	// Check if this is a terminate request
	if msg.Type == "request" && msg.Command == "terminate" {
		// Signal termination
		select {
		case terminateSignal <- true:
		default:
			// Channel already has a signal, don't block
		}
	}
}

// handleOutput processes output from the process and forwards to stdout
func handleOutput(reader io.ReadCloser) {
	defer reader.Close()

	// Simple approach: read all data and process it as a stream
	buffer := make([]byte, bufferSize)
	var accumulated []byte

	for {
		n, err := reader.Read(buffer)
		if n > 0 {
			accumulated = append(accumulated, buffer[:n]...)

			// Process complete messages from accumulated data
			for {
				processed, remaining := processBuffer(accumulated)
				if processed == nil {
					break // No complete message found
				}

				// Output the processed message
				// #nosec G104 - stdout write errors are not critical for proxy operation
				os.Stdout.Write(processed)
				accumulated = remaining
			}
		}

		if err != nil {
			if err == io.EOF {
				// Output any remaining data
				if len(accumulated) > 0 {
					// #nosec G104 - stdout write errors are not critical for proxy operation
					os.Stdout.Write(accumulated)
				}
				break
			}
			continue
		}
	}
}

// processBuffer looks for complete DAP messages in the buffer and processes them
func processBuffer(data []byte) (processed, remaining []byte) {
	dataStr := string(data)

	// Look for Content-Length header
	idx := strings.Index(dataStr, contentLengthPrefix)
	if idx == -1 {
		// No Content-Length found, return first part as-is if we have a complete line
		if newlineIdx := strings.Index(dataStr, "\n"); newlineIdx != -1 {
			return data[:newlineIdx+1], data[newlineIdx+1:]
		}
		return nil, data // Wait for more data
	}

	// Parse content length
	headerStart := idx
	headerEnd := strings.Index(dataStr[idx:], "\n")
	if headerEnd == -1 {
		return nil, data // Wait for complete header
	}
	headerEnd += idx

	lengthStr := strings.TrimSpace(dataStr[idx+len(contentLengthPrefix) : headerEnd])
	contentLength := 0
	if _, err := fmt.Sscanf(lengthStr, "%d", &contentLength); err != nil {
		// Can't parse length, return up to this point
		return data[:headerEnd+1], data[headerEnd+1:]
	}

	// Find the start of JSON content (after the empty line)
	jsonStart := strings.Index(dataStr[headerEnd:], headerSeparatorLF)
	if jsonStart == -1 {
		jsonStart = strings.Index(dataStr[headerEnd:], headerSeparatorCRLF)
		if jsonStart == -1 {
			return nil, data // Wait for complete separator
		}
		jsonStart += headerEnd + separatorCRLFLength
	} else {
		jsonStart += headerEnd + separatorLFLength
	}

	// Check if we have the complete JSON content
	if len(data) < jsonStart+contentLength {
		return nil, data // Wait for complete message
	}

	// Extract and process the JSON content
	jsonContent := string(data[jsonStart : jsonStart+contentLength])
	modifiedContent := processMessage(jsonContent)

	// Build the complete message
	var result []byte
	if modifiedContent != jsonContent {
		// Content was modified, update the Content-Length
		newLength := len(modifiedContent)
		result = append(result, data[:headerStart]...)
		result = append(result, fmt.Sprintf("Content-Length: %d\r\n\r\n%s", newLength, modifiedContent)...)
	} else {
		// Content unchanged, return original
		result = append(result, data[:jsonStart+contentLength]...)
	}

	return result, data[jsonStart+contentLength:]
}

// processMessage checks if the message matches our target response and modifies it
func processMessage(jsonContent string) string {
	var msg DAPMessage

	// Try to parse the JSON
	if err := json.Unmarshal([]byte(jsonContent), &msg); err != nil {
		// If parsing fails, return original content
		return jsonContent
	}

	// Check if this matches our target response pattern:
	// - Must be a response type
	// - Must be successful
	// - Must have a request_seq
	// - Must NOT already have a command set (empty string or missing)
	if msg.Type == "response" && msg.Success != nil && *msg.Success && msg.RequestSeq != nil && msg.Command == "" {
		// Add the command field only if it's not already set
		msg.Command = "empty"

		// Marshal back to JSON
		if modifiedJSON, err := json.Marshal(msg); err == nil {
			return string(modifiedJSON)
		}
	}

	// Return original content if:
	// - No modification needed (doesn't match pattern)
	// - Already has a command set (forward as-is)
	// - Marshaling failed
	return jsonContent
}
