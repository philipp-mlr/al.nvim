local Config = require("al.config")
local Util = require("al.utils")
local Lsp = require("al.lsp")

local clear_credential_cache

clear_credential_cache = function(config)
	config = vim.tbl_extend("force", Config.default_launch_cfg, config or {})
	local bufnr = vim.api.nvim_get_current_buf()
	local client = Lsp.get_client_for_buf(bufnr)

	if not client then
		Util.error("No AL language server attached to the current buffer.")
		return
	end

	local params = {
		configuration = config,
		browserInfo = {
			browser = Config.lsp.browser,
			incognito = false,
		},
		environmentInfo = {},
		force = true,
	}
	client.request(client, "al/clearCredentialsCache", params, function(err, result)
		if err then
			Util.error(err.message)
		end

		Util.info("Credentials cache is cleared")
	end)
end

return clear_credential_cache
