# AL Debug Proxy Binaries

This directory contains pre-built binaries of the AL debug proxy for different platforms:

- `al-debug-proxy.exe` - Windows (x64)
- `al-debug-proxy` - Linux (x64)
- `al-debug-proxy-darwin` - macOS Intel (x64)
- `al-debug-proxy-darwin-arm64` - macOS Apple Silicon (arm64)

## Building from Source

To build the binaries yourself:

1. Install Go 1.21 or later
2. Navigate to the `proxy-src` directory
3. Run the build script:
   - On Windows: `build.bat`
   - On Unix systems: `./build.sh`

## What the Proxy Does

The proxy is a simple traffic forwarder that:

1. Accepts the same arguments as the AL EditorServices
2. Launches `dotnet Microsoft.Dynamics.Nav.EditorServices.Host.dll` with those arguments
3. Forwards all stdin/stdout traffic between nvim-dap and the AL debugger
4. Handles proper process cleanup and signal handling

This solves the stdio handle issues that occur when launching AL EditorServices directly from nvim-dap.
