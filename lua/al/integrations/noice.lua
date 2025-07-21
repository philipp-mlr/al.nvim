local Lsp = require("al.lsp")
local require = require("noice.util.lazy")

local Manager = require("noice.message.manager")
local Message = require("noice.message")

local M = {}

---@enum MessageType
M.message_type = {
    error = 1,
    warn = 2,
    info = 3,
    debug = 4,
}

M.setup = function()
    local ok, noice = pcall(require, "noice")
    if not ok then
        return
    end

    -- vim.lsp.handlers["window/logMessage"] = M.on_message
end

---@param result ShowMessageParams
function M.on_message(_, result, ctx)
    ---@type number
    local client_id = ctx.client_id
    local client = vim.lsp.get_client_by_id(client_id)
    if not Lsp.supports(client) then
        return
    end

    local client_name = client and client.name or string.format("lsp id=%d", client_id)

    local message = Message("lsp", "message", result.message)
    message.opts.title = "al.nvim"
    for level, type in pairs(M.message_type) do
        if type == result.type then
            message.level = level
        end
    end
    Manager.add(message)
end

return M
