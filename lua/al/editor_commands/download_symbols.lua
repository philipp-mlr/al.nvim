local Config = require("al.config")
local Util = require("al.utils")

local auth = require("al.editor_commands.auth")

---@param cb fun(err: lsp.ResponseError, result: any, ctx: lsp.HandlerContext, config?: table)
local download_symbols_lsp_request = function(params, cb)
	vim.lsp.buf_request(0, "al/downloadSymbols", params, cb)
end

local download_symbols_handler
---@param err lsp.ResponseError
---@param result any
---@param ctx lsp.HandlerContext
---@param config? table
download_symbols_handler = function(err, result, ctx, config)
	if err and err.data == 401 then
		Util.info("Needs authentication")
		coroutine.resume(coroutine.create(function()
			local auth_result = auth(ctx.params.configuration)
			if auth_result == "success" then
				download_symbols_lsp_request(ctx.params, download_symbols_handler)
			end
		end))
		return
	end

	if not err then
		if result.success then
			Util.info("Symbols have been downloaded")
		else
			Util.error("Could not download reference symbols.")
		end
	end
end

---@param config al.LaunchConfiguration
local download_symbols = function(config)
	config = vim.tbl_extend("force", Config.default_launch_cfg, config or {})

	local params = {
		configuration = config,
		browserInfo = {
			browser = Config.lsp.browser,
			incognito = false,
		},
		environmentInfo = {},
		force = true,
	}

	download_symbols_lsp_request(params, download_symbols_handler)
end

return download_symbols
