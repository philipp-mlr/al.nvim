local random = math.random

---@class al.Utils.mod
local M = {}

function M.create_uuid()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
        return string.format("%x", v)
    end)
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.notify(msg, opts)
    opts = opts or {}
    msg = type(msg) == "table" and table.concat(msg, "\n") or msg
    ---@cast msg string
    msg = vim.trim(msg)
    return vim[opts.once and "notify_once" or "notify"](msg, opts.level, {
        title = opts.title or "al.nvim",
        on_open = function(win)
            vim.wo[win].conceallevel = 3
            vim.wo[win].concealcursor = "n"
            vim.wo[win].spell = false
            vim.treesitter.start(vim.api.nvim_win_get_buf(win), "markdown")
        end,
    })
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.warn(msg, opts)
    M.notify(msg, vim.tbl_extend("keep", { level = vim.log.levels.WARN }, opts or {}))
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.error(msg, opts)
    M.notify(msg, vim.tbl_extend("keep", { level = vim.log.levels.ERROR }, opts or {}))
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.info(msg, opts)
    M.notify(msg, vim.tbl_extend("keep", { level = vim.log.levels.INFO }, opts or {}))
end

M.get_clients = vim.lsp.get_clients

--- Strip trailing commas from JSONC (before a closing ] or }), string-aware
--- so a string value containing ",}" or ",]" isn't mistaken for one.
---@param text string
---@return string
local function strip_trailing_commas(text)
    local out = {}
    local len = #text
    local i = 1
    local in_string = false
    -- Buffered comma + following whitespace, held back until the next
    -- non-whitespace character reveals whether it's a real separator (flush)
    -- or a trailing comma before ]/} (drop).
    local pending_comma_ws = nil

    local function flush_pending()
        if pending_comma_ws then
            out[#out + 1] = ","
            out[#out + 1] = pending_comma_ws
            pending_comma_ws = nil
        end
    end

    while i <= len do
        local c = text:sub(i, i)

        if in_string then
            flush_pending()
            out[#out + 1] = c
            if c == "\\" and i < len then
                out[#out + 1] = text:sub(i + 1, i + 1)
                i = i + 2
            else
                if c == '"' then
                    in_string = false
                end
                i = i + 1
            end
        elseif c == '"' then
            flush_pending()
            in_string = true
            out[#out + 1] = c
            i = i + 1
        elseif c == "," and not pending_comma_ws then
            pending_comma_ws = ""
            i = i + 1
        elseif pending_comma_ws and c:match("%s") then
            pending_comma_ws = pending_comma_ws .. c
            i = i + 1
        elseif pending_comma_ws and (c == "]" or c == "}") then
            pending_comma_ws = nil
            out[#out + 1] = c
            i = i + 1
        else
            flush_pending()
            out[#out + 1] = c
            i = i + 1
        end
    end
    flush_pending()

    return table.concat(out)
end

--- Read and parse a JSON(C) file. Tolerates comments and trailing commas,
--- common in hand-edited VS Code .vscode/*.json files like launch.json.
---@param path string
---@return table
function M.read_json_file(path)
    local f = assert(io.open(path))
    local content = f:read("*a")
    f:close()
    local table_content = vim.json.decode(strip_trailing_commas(content), { skip_comments = true })
    return table_content
end

return M
