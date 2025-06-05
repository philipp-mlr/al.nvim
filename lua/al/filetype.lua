local M = {}

function M.setup()
	vim.filetype.add({
		extension = {
			al = "al",
		},
		pattern = {
			[".*%.al$"] = "al",
		},
	})
end

return M
