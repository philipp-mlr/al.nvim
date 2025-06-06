# AL Debugging with nvim-dap

This document explains how al.nvim solves the AL debugger stdio handle issues when using nvim-dap.

## The Problem

When launching Microsoft.Dynamics.Nav.EditorServices directly from nvim-dap with the `/startDebugging` parameter, you encounter this error:

```
Unhandled exception. System.AggregateException: One or more errors occurred. (The handle is invalid.)
 ---> System.IO.IOException: The handle is invalid.
   at System.ConsolePal.SetConsoleInputEncoding(Encoding enc)
   at System.Console.set_InputEncoding(Encoding value)
   at Microsoft.Dynamics.Nav.EditorServices.Protocol.Channel.StdioServerChannel.Initialize(...)
```

This happens because the AL EditorServices expects proper console handles, but when launched from nvim-dap, the stdio handles are not properly initialized.

## The Solution: Proxy Application

al.nvim includes a lightweight proxy application that:

1. **Accepts the same arguments** as the AL EditorServices
2. **Launches the AL EditorServices** with proper console setup
3. **Forwards all communication** between nvim-dap and the AL debugger
4. **Handles process lifecycle** and cleanup

## Architecture

```
nvim-dap <--stdio--> al-debug-proxy <--stdio--> Microsoft.Dynamics.Nav.EditorServices
```

## Implementation

### Proxy Application (Go)

The proxy is written in Go for cross-platform compatibility and small binary size:

```go
// Simplified version
func main() {
    // Launch AL EditorServices with all passed arguments
    cmd := exec.Command("dotnet", os.Args[1:]...)
    
    // Set up proper stdio pipes
    cmd.Stdin = os.Stdin
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    
    // Start and wait for completion
    cmd.Start()
    cmd.Wait()
}
```

### Integration with nvim-dap

The debugger configuration uses the proxy instead of calling dotnet directly:

```lua
dap.adapters.al = function(callback, config)
    callback({
        type = "executable",
        command = M.get_proxy_path(), -- Points to proxy binary
        args = M.args(),              -- Same AL EditorServices arguments
        -- No special stdio configuration needed
    })
end
```

### Platform Support

The proxy supports multiple platforms:

- **Windows**: `al-debug-proxy.exe` (with `.bat` fallback)
- **Linux**: `al-debug-proxy`
- **macOS Intel**: `al-debug-proxy-darwin`
- **macOS Apple Silicon**: `al-debug-proxy-darwin-arm64`

## Usage

1. **Install al.nvim** with nvim-dap support
2. **Configure your launch.json** with AL debug configurations
3. **Set breakpoints** in your AL code
4. **Start debugging** with `:DapContinue` or your preferred nvim-dap command

The proxy handles all the stdio complexity automatically.

## Benefits

- ✅ **Solves stdio handle issues** completely
- ✅ **Zero configuration** required
- ✅ **Cross-platform** support
- ✅ **Lightweight** (~2-5MB binary)
- ✅ **Transparent** operation
- ✅ **Reliable** process management

## Building from Source

If you need to build the proxy yourself:

```bash
cd proxy-src
./build.sh    # Unix systems
build.bat     # Windows
```

Or use the GitHub Actions workflow to build all platform binaries automatically.

## Troubleshooting

### Proxy Not Found
- Ensure the proxy binary exists in the `bin/` directory
- Check file permissions on Unix systems (`chmod +x`)

### Still Getting Handle Errors
- Verify you're using the latest version of al.nvim
- Check that the proxy is being used (not direct dotnet calls)

### Debugger Not Connecting
- Verify your launch.json configuration
- Check Business Central server accessibility
- Ensure AL code is published to the server

## Technical Details

The proxy solves the handle issue by:

1. **Creating proper stdio pipes** when launched by nvim-dap
2. **Providing valid console handles** to the AL EditorServices
3. **Forwarding all DAP protocol messages** transparently
4. **Managing process lifecycle** correctly

This approach is more reliable than trying to work around the stdio issues directly in the nvim-dap configuration.
