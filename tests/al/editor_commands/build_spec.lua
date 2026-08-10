local helpers = require("tests.helpers")

describe("al.editor_commands.build", function()
    local build

    before_each(function()
        package.loaded["al.editor_commands.build"] = nil
        package.loaded["al.multiproject"] = {
            project_for_buf = function() return "/test/project" end,
        }
        build = require("al.editor_commands.build")
    end)

    after_each(function()
        package.loaded["al.multiproject"] = nil
    end)

    it("sends al/createPackage with the resolved project dir", function()
        local client = helpers.make_mock_client({
            responses = { ["al/createPackage"] = { result = { success = true } } },
        })
        local restore_lsp = helpers.stub_lsp_client(client)
        local notify = helpers.capture_notify()

        build()
        helpers.flush()

        assert.are.equal(1, #client.requests)
        assert.are.equal("al/createPackage", client.requests[1].method)
        assert.are.equal("/test/project", client.requests[1].params.projectDir)
        restore_lsp()
        notify.restore()
    end)

    it("notifies success when result.success is true", function()
        local client = helpers.make_mock_client({
            responses = { ["al/createPackage"] = { result = { success = true } } },
        })
        local restore_lsp = helpers.stub_lsp_client(client)
        local notify = helpers.capture_notify()

        build()
        helpers.flush()

        local found = false
        for _, m in ipairs(notify.messages) do
            if m.msg:match("Success") then found = true end
        end
        assert.is_true(found)
        restore_lsp()
        notify.restore()
    end)

    it("surfaces the full result (not just err) when result.success is false", function()
        local client = helpers.make_mock_client({
            responses = {
                ["al/createPackage"] = {
                    result = { success = false, errors = { "CompileError: 'X' does not exist" } },
                },
            },
        })
        local restore_lsp = helpers.stub_lsp_client(client)
        local notify = helpers.capture_notify()

        build()
        helpers.flush()

        local found = false
        for _, m in ipairs(notify.messages) do
            if m.msg:match("CompileError") then found = true end
        end
        assert.is_true(found)
        restore_lsp()
        notify.restore()
    end)

    it("errors clearly when no LSP client is attached", function()
        local restore_lsp = helpers.stub_lsp_client(nil)
        local notify = helpers.capture_notify()

        build()

        local found = false
        for _, m in ipairs(notify.messages) do
            if m.msg:match("No AL language server") then found = true end
        end
        assert.is_true(found)
        restore_lsp()
        notify.restore()
    end)

    it("errors clearly when the project directory cannot be determined", function()
        package.loaded["al.multiproject"].project_for_buf = function() return nil end
        package.loaded["al.workspace"] = { find = function() return nil end }
        package.loaded["al.editor_commands.build"] = nil
        build = require("al.editor_commands.build")

        local notify = helpers.capture_notify()
        build()

        local found = false
        for _, m in ipairs(notify.messages) do
            if m.msg:match("Could not determine AL project directory") then found = true end
        end
        assert.is_true(found)
        notify.restore()
        package.loaded["al.workspace"] = nil
    end)
end)
