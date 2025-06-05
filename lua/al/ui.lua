local Menu = require("nui.menu")
local Input = require("nui.input")
local event = require("nui.utils.autocmd").event
local M = {}

---@param on_submit? fun(item: NuiTree.Node)
---@param on_close? fun()
M.show_config_selection_menu = function(configs, on_submit, on_close)
	local items = {}
	for _, cfg in ipairs(configs) do
		table.insert(items, Menu.item(cfg.name, { config = cfg }))
	end

	local menu = Menu({
		position = {
			row = 0,
			col = "50%",
		},
		size = {
			width = 50,
			height = 5,
		},
		border = {
			style = "single",
			text = {
				top = "[Choose-configuration]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}, {
		lines = items,
		max_width = 20,
		keymap = {
			focus_next = { "j", "<Down>", "<Tab>" },
			focus_prev = { "k", "<Up>", "<S-Tab>" },
			close = { "<Esc>", "<C-c>" },
			submit = { "<CR>", "<Space>" },
		},
		on_close = on_close,
		on_submit = on_submit,
	})

	menu:mount()
end

M.show_input_username = function(on_submit, on_cancel)
	local popup_options = {
		position = {
			row = 0,
			col = "50%",
		},
		size = {
			width = 50,
			height = 1,
		},
		border = {
			style = "rounded",
			text = {
				top = "[Username]",
				top_align = "left",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal",
		},
	}

	local input = Input(popup_options, {
		prompt = "> ",
		default_value = "",
		on_close = on_cancel,
		on_submit = on_submit,
	})

	input:map("n", "<Esc>", function()
		input:unmount()
	end, { noremap = true })

	input:on(event.BufLeave, function()
		input:unmount()
	end)

	input:mount()
end

local SecretInput = Input:extend("SecretInput")

function SecretInput:init(popup_options, options)
	assert(
		not options.conceal_char or vim.api.nvim_strwidth(options.conceal_char) == 1,
		"conceal_char must be a single char"
	)

	popup_options.win_options = vim.tbl_deep_extend("force", popup_options.win_options or {}, {
		conceallevel = 2,
		concealcursor = "nvi",
	})

	SecretInput.super.init(self, popup_options, options)

	self._.conceal_char = type(options.conceal_char) == "nil" and "*" or options.conceal_char
end

function SecretInput:mount()
	SecretInput.super.mount(self)

	local conceal_char = self._.conceal_char
	local prompt_length = vim.api.nvim_strwidth(vim.fn.prompt_getprompt(self.bufnr))

	vim.api.nvim_buf_call(self.bufnr, function()
		vim.cmd(string.format(
			[[
        syn region SecretValue start=/^/ms=s+%s end=/$/ contains=SecretChar
        syn match SecretChar /./ contained conceal %s
      ]],
			prompt_length,
			conceal_char and "cchar=" .. (conceal_char or "*") or ""
		))
	end)
end

M.show_input_password = function(on_submit, on_cancel)
	local popup_options = {
		position = {
			row = 0,
			col = "50%",
		},
		size = {
			width = 50,
			height = 1,
		},
		border = {
			style = "rounded",
			text = {
				top = "[Password]",
				top_align = "left",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal",
		},
	}
	-- conceal secret characters with `*`
	local input = SecretInput(popup_options, {
		prompt = "> ",
		default_value = "",
		on_close = on_cancel,
		on_submit = on_submit,
	})

	input:map("n", "<Esc>", function()
		input:unmount()
	end, { noremap = true })

	input:on(event.BufLeave, function()
		input:unmount()
	end)

	input:mount()
end

return M
