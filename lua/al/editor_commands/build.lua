local Config = require("al.config")
local Util = require("al.utils")
local Workspace = require("al.workspace")

local build_package = function()
    local co = coroutine.running()
    local fname = vim.api.nvim_buf_get_name(0)
    local ws = Workspace.find({ path = fname })
    local params = {
        projectDir = ws.root,
        args = {
            "-project:" .. ws.root,
        },
        isRad = false,
        vSCodeExtensionVersion = Config.language_extension_version,
        forceBuildDependencies = false,
    }

    Util.info("Started creating package...")
    vim.lsp.buf_request(0, "al/createPackage", params, function(err, result)
        if result.success then
            Util.info("Success: The package is created")
        else
            vim.notify("Failed creating AL package\r\n" .. vim.inspect(err), vim.log.levels.ERROR)
        end
        coroutine.resume(co)
    end)
    return coroutine.yield()
end

return build_package
