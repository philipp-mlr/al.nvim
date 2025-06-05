---@type al.Config.mod
local Config = require("al.config")
---@type al.Utils.mod
local Utils = require("al.utils")
local Workspace = require("al.workspace")

local M = {}
M.attached = {} ---@type table<number, number>

---@param client? vim.lsp.Client
function M.assert(client)
	assert(M.supports(client), "al: Not a al_ls client??")
end

---@param client? vim.lsp.Client
function M.supports(client)
	return client and vim.tbl_contains({ "al_ls" }, client.name)
end

---@param client? vim.lsp.Client
function M.attach(client)
	if M.attached[client.id] then
		return
	end

	M.assert(client)

	M.attached[client.id] = client.id

	-- client.handlers = vim.tbl_extend("force", {}, client.handlers or {})

	-- M.set_handler(client, "workspace/configuration", M.on_workspace_configuration)
	-- M.set_handler(client, "al/setActiveWorkspace", M.on_set_active_workspace)
	M.set_handler(client, "al/progressNotification", M.on_progress_notification)
end

---@param err lsp.ResponseError
---@param result any
---@param ctx lsp.HandlerContext
function M.on_progress_notification(err, result, ctx)
	local kind = "report"
	if result.percent == 0 then
		kind = "begin"
	end
	if result.percent == 100 then
		kind = "end"
	end

	vim.api.nvim_exec_autocmds("LspProgress", {
		pattern = result.percent == 0 and "begin" or "end",
		modeline = false,
		data = {
			client_id = ctx.client_id,
			params = {
				token = "al_progress_" .. result.owner,
				value = {
					kind = kind,
					title = "AL loading",
					cancellable = result.cancel,
					message = result.message,
					percentage = result.percent,
				},
			},
		},
	})
end

---@param client vim.lsp.Client
---@param type string
---@param handler fun(err?: lsp.ResponseError, result: any, ctx: lsp.HandlerContext, cfg?: table)
function M.set_handler(client, type, handler)
	if vim.fn.has("nvim-0.10") == 0 then
		if M.did_global_handler then
			return
		end
		M.did_global_handler = true
		local orig = vim.lsp.handlers[type]
		vim.lsp.handlers[type] = function(err, params, ctx, cfg)
			if M.attached[ctx.client_id] then
				return handler(err, params, ctx, cfg)
			end
			return orig(err, params, ctx, cfg)
		end
	else
		client.handlers[type] = handler
	end
end

function M.setup()
	vim.lsp.config.al_ls = {
		cmd = M.cmd(),
		filetypes = { "al" },
		root_markers = { "app.json", ".alpackages" },
		root_dir = function(bufnr, on_dir)
			local fname = vim.api.nvim_buf_get_name(bufnr)
			local has_al_project_cfg = function(path)
				local alpath = vim.fs.joinpath(path, "app.json")
				return (vim.uv.fs_stat(alpath) or {}).type == "file"
			end
			on_dir(vim.iter(vim.fs.parents(fname)):find(has_al_project_cfg) or vim.fs.root(0, ".alpackages"))
		end,
		single_file_support = true,
		settings = Config.workspace,
		-- init_options = {
		-- 	logging = { level = "trace" },
		-- 	trace = { server = "verbose" },
		-- },
		-- capabilities = capabilities,
	}

	vim.lsp.enable("al_ls")
end

function M.cmd()
	return {
		M.find_lsp_path(Config.vscodeExtensionsPath),
		"/telemetryLevel:" .. Config.lsp.telemetryLevel,
		"/browser:" .. Config.lsp.browser,
		"/inlayHintsParameterNames:" .. tostring(Config.lsp.inlayHintsParameterNames),
		"/inlayHintsFunctionReturnTypes:" .. tostring(Config.lsp.inlayHintsFunctionReturnTypes),
		"/semanticFolding:" .. tostring(Config.lsp.semanticFolding),
		"/extendGoToSymbolInWorkspace:" .. tostring(Config.lsp.extendGoToSymbolInWorkspace),
		"/extendGoToSymbolInWorkspaceResultLimit:" .. tostring(Config.lsp.extendGoToSymbolInWorkspaceResultLimit),
		"/extendGoToSymbolInWorkspaceIncludeSymbolFiles:"
		.. tostring(Config.lsp.extendGoToSymbolInWorkspaceIncludeSymbolFiles),
		"/sessionId:" .. (Utils.create_uuid()),
	}
end

function M.find_lsp_path(basePath)
	local path = ""
	for filename in io.popen('dir "' .. vim.fn.expand(basePath) .. '" /b /ad'):lines() do
		local match = filename:match("ms%-dynamics%-smb.al%-(.+)")
		if match then
			Config.language_extension_version = match
			path = vim.fn.expand(basePath)
				.. (basePath:sub(- #basePath) == "\\" and "\\" or "")
				.. filename
				.. "\\bin\\win32\\Microsoft.Dynamics.Nav.EditorServices.Host.exe"
		end
	end
	return path
end

return M
