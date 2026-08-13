local Config = require("al.config")
local Util = require("al.utils")
local Workspace = require("al.workspace")
local Lsp = require("al.lsp")

--- Open the quickfix list with any ERROR-severity diagnostics, if there are
--- any. al/createPackage's response has no error text of its own on
--- failure; the actual compiler errors arrive via publishDiagnostics.
local function show_error_diagnostics()
    local errors = vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })
    if #errors == 0 then
        return
    end
    vim.diagnostic.setqflist({ title = "AL build errors", severity = vim.diagnostic.severity.ERROR })
end

local build_package = function()
    local co = coroutine.running()
    local fname = vim.api.nvim_buf_get_name(0)
    local buf = vim.api.nvim_get_current_buf()
    local project_dir = require("al.multiproject").project_for_buf(buf)
    if not project_dir then
        local ws = Workspace.find({ path = fname })
        project_dir = ws and ws.root
    end
    if not project_dir then
        Util.error("Could not determine AL project directory for current buffer.")
        return
    end
    local params = {
        projectDir = project_dir,
        args = {
            "-project:" .. project_dir,
        },
        isRad = false,
        vSCodeExtensionVersion = Config.language_extension_version,
        forceBuildDependencies = false,
    }

    local client = Lsp.get_client_for_buf(buf)
    if not client then
        Util.error("No AL language server attached to the current buffer.")
        coroutine.resume(co)
        return
    end

    Util.info("Started creating package...")
    client:request("al/createPackage", params, function(err, result)
        if not result then
            Util.error("Failed creating AL package\r\n" .. vim.inspect(err))
            coroutine.resume(co)
            return
        end
        if result.success then
            Util.info("Success: The package is created")
        else
            Util.error("Failed creating AL package\r\n" .. vim.inspect(result))
            -- Give diagnostics for the failed files a moment to arrive.
            vim.defer_fn(show_error_diagnostics, 300)
        end
        coroutine.resume(co)
    end)
    return coroutine.yield()
end

return build_package
