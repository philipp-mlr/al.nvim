local Config = require("al.config")
local Util = require("al.utils")

local clear_credential_cache

clear_credential_cache = function(config)
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
	vim.lsp.buf_request(0, "al/clearCredentialsCache", params, function(err, result)
		if err then
			Util.error(err.message)
		end

		Util.info("Credentials cache is cleared")
	end)
end

return clear_credential_cache
