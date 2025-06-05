local Ui = require("al.ui")

---@type "none" | "success" | "fail" | "cancelled"
local auth_result = "none"

local function username_co()
	local co = coroutine.running()

	Ui.show_input_username(function(value)
		coroutine.resume(co, value)
	end, function()
		coroutine.resume(co, nil)
	end)

	return coroutine.yield()
end

local function password_co()
	local co = coroutine.running()
	Ui.show_input_password(function(value)
		coroutine.resume(co, value)
	end, function()
		coroutine.resume(co, nil)
	end)

	return coroutine.yield()
end

---@return "none" | "success" | "fail" | "cancelled"
local authenticate_co = function(config)
	auth_result = "none"

	local username = username_co()
	if not username then
		auth_result = "cancelled"
		return auth_result
	end

	local password = password_co()

	if not password then
		auth_result = "cancelled"
		return auth_result
	end

	local params = {
		configuration = config,
		credentials = {
			username = username,
			password = password,
		},
	}

	local result = vim.lsp.buf_request_sync(0, "al/saveUsernamePassword", params, 5000)
	if result and result[1] and result[1].error then
		auth_result = "fail"
	else
		auth_result = "success"
	end

	return auth_result
end

return authenticate_co
