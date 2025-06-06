@echo off
REM Build script for al-debug-proxy on Windows
REM Builds binaries for Windows, Linux, and macOS

echo Building al-debug-proxy binaries...

REM Clean previous builds
del /Q ..\bin\al-debug-proxy* 2>nul

REM Build for Windows (amd64)
echo Building for Windows...
set GOOS=windows
set GOARCH=amd64
go build -ldflags="-s -w" -o ..\bin\al-debug-proxy.exe .

REM Build for Linux (amd64)
echo Building for Linux...
set GOOS=linux
set GOARCH=amd64
go build -ldflags="-s -w" -o ..\bin\al-debug-proxy .

REM Build for macOS (amd64)
echo Building for macOS (Intel)...
set GOOS=darwin
set GOARCH=amd64
go build -ldflags="-s -w" -o ..\bin\al-debug-proxy-darwin .

REM Build for macOS (arm64)
echo Building for macOS (Apple Silicon)...
set GOOS=darwin
set GOARCH=arm64
go build -ldflags="-s -w" -o ..\bin\al-debug-proxy-darwin-arm64 .

echo Build complete! Binaries are in ..\bin\
dir ..\bin\
