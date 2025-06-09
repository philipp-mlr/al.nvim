# AL Debug Proxy Binaries

This directory contains pre-built binaries of the AL debug proxy for different platforms:

- `al-debug-proxy.exe` - Windows (x64)
- `al-debug-proxy` - Linux (x64)  
- `al-debug-proxy-darwin` - macOS Intel (x64)
- `al-debug-proxy-darwin-arm64` - macOS Apple Silicon (arm64)
- `al-debug-proxy.bat` - Windows fallback script (temporary)

## Automatic Platform Detection

The plugin automatically selects the correct binary for your platform:

- **Windows**: Uses `.exe` binary, falls back to `.bat` if needed
- **Linux**: Uses the standard binary
- **macOS Intel**: Uses the `-darwin` binary
- **macOS Apple Silicon**: Uses the `-darwin-arm64` binary

## Building from Source

To build the binaries yourself:

1. **Install Go 1.21 or later**
2. **Navigate to the `proxy-src` directory**
3. **Run the build script**:
   - On Windows: `build.bat`
   - On Unix systems: `./build.sh`

The build scripts will create optimized binaries for all supported platforms.

## What the Proxy Does

The proxy is a sophisticated traffic forwarder that:

1. **Accepts the same arguments** as the AL EditorServices
2. **Launches AL EditorServices** with proper console initialization
3. **Forwards all DAP protocol messages** between nvim-dap and the AL debugger
4. **Handles cross-platform process management** with proper signal handling
5. **Provides automatic build integration** - builds AL packages before debugging
6. **Manages process lifecycle** with graceful cleanup and error handling

## Key Features

- ✅ **Solves stdio handle issues** that crash AL EditorServices when launched from nvim-dap
- ✅ **Cross-platform compatibility** with optimized binaries for all major platforms
- ✅ **Zero configuration** - works transparently with existing nvim-dap setups
- ✅ **Lightweight** - small binary size (~2-5MB) with minimal overhead
- ✅ **Robust error handling** - proper logging and graceful failure modes
- ✅ **Signal management** - handles interrupts and termination signals correctly

## Technical Implementation

The proxy solves the fundamental issue where AL EditorServices expects proper console handles but nvim-dap's process spawning doesn't provide them correctly. By acting as an intermediary, the proxy:

- Creates proper stdio pipes when launched by nvim-dap
- Provides valid console handles to the AL EditorServices
- Forwards all communication transparently
- Manages the complete debugging session lifecycle

This approach is more reliable than attempting to work around the stdio issues directly in nvim-dap configuration.
