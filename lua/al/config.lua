---@class al.Config.mod: al.Config
local M = {}

---@alias al.LSP.LogLevel "Debug" | "Verbose" | "Normal" | "Warning" | "Error"
---@alias al.LSP.TelemetryLevel "none" | "crash" | "error" | "all"
---@alias al.LSP.Browser "SystemDefault" | "Chrome" | "Firefox" | "Edge" | "EdgeBeta"

---@class al.Config.LSP
---@field telemetryLevel al.LSP.TelemetryLevel
---@field browser al.LSP.Browser
---@field inlayHintsParameterNames boolean
---@field inlayHintsFunctionReturnTypes boolean
---@field semanticFolding boolean
---@field extendGoToSymbolInWorkspace boolean
---@field extendGoToSymbolInWorkspaceResultLimit integer
---@field extendGoToSymbolInWorkspaceIncludeSymbolFiles boolean
---@field log {path: string, level: al.LSP.LogLevel }

---@class al.Config
---@field lsp al.Config.LSP
local defaults = {
	vscodeExtensionsPath = "~\\.vscode\\extensions\\",
	workspace = {
		alResourceConfigurationSettings = {
			assemblyProbingPaths = {
				"./.netpackages",
			},
			codeAnalyzers = {
				"${CodeCop}",
				"${analyzerFolder}BusinessCentral.LinterCop.dll",
			},
			enableCodeAnalysis = true,
			backgroundCodeAnalysis = true,
			packageCachePaths = {
				"./.alpackages",
			},
			ruleSetPath = ".vscode/ruleset.json",
			enableCodeActions = true,
			incrementalBuild = false,
			outputAnalyzerStatistics = false,
			enableExternalRulesets = true,
		},
	},
	lsp = {
		telemetryLevel = "all",
		browser = "SystemDefault",
		inlayHintsParameterNames = true,
		inlayHintsFunctionReturnTypes = true,
		semanticFolding = true,
		extendGoToSymbolInWorkspace = true,
		extendGoToSymbolInWorkspaceResultLimit = 100,
		extendGoToSymbolInWorkspaceIncludeSymbolFiles = true,
		log = {
			path = "",
			level = "Normal",
		},
	},
}

---@class al.LaunchConfiguration
M.default_launch_cfg = {
	name = "",
	type = "al",
	request = "launch",
	publishOnly = false,
	isRad = false,
	justDebug = false,
	authentication = "UserPassword",
	port = 443,
	schemaUpdateMode = "Synchronize",
	server = "",
	serverInstance = "",
	tenant = "default",
	breakOnErrorBehaviour = "None",
	enableSqlInformationDebugger = true,
	enableLongRunningSqlStatements = true,
	longRunningSqlStatementsThreshold = 500,
	numberOfSqlStatements = 10,
	projectReferenceDefinitions = {},
	disableHttpRequestTimeout = true,
	usePublicURLFromServer = true,
	validateServerCertificate = true,
	useInteractiveLogin = true,
	isResolved = true,
}

M.language_extension_version = ""

---@type al.Config
local options

---@param opts? al.Config
function M.setup(opts)
	---@type al.Config
	options = vim.tbl_deep_extend("force", {}, options or defaults, opts or {})

	vim.api.nvim_create_user_command("AL", function(...)
		require("al.cmd").execute(...)
	end, {
		nargs = "*",
		complete = function(...)
			return require("al.cmd").complete(...)
		end,
		desc = "al.nvim",
	})

	-- vim.keymap.set("n", "<leader>ab", "<cmd>AL build<cr>", {
	-- 	desc = "Build AL package",
	-- })

	vim.schedule(function()
		require("al.filetype").setup()
		require("al.lsp").setup()
		require("al.buf").setup()
	end)
	return options
end

return setmetatable(M, {
	__index = function(_, key)
		options = options or M.setup()
		return options[key]
	end,
})
