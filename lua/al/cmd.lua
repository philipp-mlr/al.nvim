local Lsp = require("al.lsp")
local Workspace = require("al.workspace")
local Util = require("al.utils")
local Ui = require("al.ui")

local download_symbols = require("al.editor_commands.download_symbols")
local clear_credential_cache = require("al.editor_commands.clear_credential_cache")
local build_package = require("al.editor_commands.build")

local M = {}

M.commands = {
	lsp = function()
		local clients = Util.get_clients({ bufnr = 0 })

		clients = vim.tbl_filter(function(client)
			return client and Lsp.supports(client)
		end, clients)

		local lines = {} ---@type string[]
		for _, client in ipairs(clients) do
			lines[#lines + 1] = "## " .. client.name
			lines[#lines + 1] = "```lua"
			lines[#lines + 1] = "settings = " .. vim.inspect(client.settings)
			lines[#lines + 1] = "```"
		end
		Util.info(lines)
	end,
	build = function()
		build_package()
	end,
	downloadSymbols = function()
		local configs = M.get_launch_configurations()
		Ui.show_config_selection_menu(configs.configurations, M.on_submit_config)
	end,
	clearCredentialsCache = function()
		local configs = M.get_launch_configurations()
		clear_credential_cache(configs.configurations)
	end,
	definition = function()
		Lsp.go_to_definition()
	end
}

M.get_launch_configurations = function()
	local fname = vim.api.nvim_buf_get_name(0)
	local ws = Workspace.find({ path = fname })

	local configs = Util.read_json_file(vim.fs.joinpath(ws.root, ".vscode/launch.json"))
	return configs
end

---@param item NuiTree.Node
M.on_submit_config = function(item)
	download_symbols(item.config)
end

function M.execute(input)
	local prefix, args = M.parse(input.args)
	prefix = prefix and prefix ~= "" and prefix or "debug"
	if not M.commands[prefix or ""] then
		return Util.error("Invalid command")
	end
	M.commands[prefix](args)
end

function M.complete(_, line)
	local prefix, args = M.parse(line)
	if #args > 0 then
		return {}
	end

	---@param key string
	return vim.tbl_filter(function(key)
		return key:find(prefix, 1, true) == 1
	end, vim.tbl_keys(M.commands))
end

---@return string, string[]
function M.parse(args)
	local parts = vim.split(vim.trim(args), "%s+")
	if parts[1]:find("AL") then
		table.remove(parts, 1)
	end
	if args:sub(-1) == " " then
		parts[#parts + 1] = ""
	end
	return table.remove(parts, 1) or "", parts
end

return M
