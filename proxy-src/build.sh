#!/bin/bash

# Build script for al-debug-proxy
# Builds binaries for Windows, Linux, and macOS

set -e

echo "Building al-debug-proxy binaries..."

# Clean previous builds
rm -f ../bin/al-debug-proxy*

# Build for Windows (amd64)
echo "Building for Windows..."
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o ../bin/al-debug-proxy.exe .

# Build for Linux (amd64)
echo "Building for Linux..."
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ../bin/al-debug-proxy .

# Build for macOS (amd64)
echo "Building for macOS (Intel)..."
GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o ../bin/al-debug-proxy-darwin .

# Build for macOS (arm64)
echo "Building for macOS (Apple Silicon)..."
GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o ../bin/al-debug-proxy-darwin-arm64 .

echo "Build complete! Binaries are in ../bin/"
ls -la ../bin/
