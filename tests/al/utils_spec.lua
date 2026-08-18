describe("al.utils.read_json_file", function()
    local utils

    before_each(function()
        package.loaded["al.utils"] = nil
        utils = require("al.utils")
    end)

    local function write_file(content)
        local path = vim.fn.tempname() .. ".json"
        local f = assert(io.open(path, "w"))
        f:write(content)
        f:close()
        return path
    end

    it("parses strict JSON", function()
        local path = write_file('{"a": 1, "b": [1, 2, 3]}')
        local data = utils.read_json_file(path)
        assert.equals(1, data.a)
        assert.same({ 1, 2, 3 }, data.b)
    end)

    it("strips a trailing comma before a closing ]", function()
        local path = write_file('{"a": [1, 2, 3,]}')
        local data = utils.read_json_file(path)
        assert.same({ 1, 2, 3 }, data.a)
    end)

    it("strips a trailing comma before a closing }", function()
        local path = write_file('{"a": 1, "b": 2,}')
        local data = utils.read_json_file(path)
        assert.equals(1, data.a)
        assert.equals(2, data.b)
    end)

    it("strips nested trailing commas, matching a real launch.json shape", function()
        local path = write_file([[
{
    "configurations": [
        {
            "name": "Launch",
            "type": "al",
        },
    ]
}
]])
        local data = utils.read_json_file(path)
        assert.equals(1, #data.configurations)
        assert.equals("Launch", data.configurations[1].name)
    end)

    it("tolerates // and /* */ comments (skip_comments)", function()
        local path = write_file([[
// header comment
{
    "a": 1, /* inline */ "b": 2
}
]])
        local data = utils.read_json_file(path)
        assert.equals(1, data.a)
        assert.equals(2, data.b)
    end)

    it("does not strip a comma that is part of a string value", function()
        local path = write_file('{"a": "literally ,}"}')
        local data = utils.read_json_file(path)
        assert.equals("literally ,}", data.a)
    end)

    it("errors for a nonexistent file", function()
        assert.has_error(function()
            utils.read_json_file("/nonexistent/path/launch.json")
        end)
    end)
end)
