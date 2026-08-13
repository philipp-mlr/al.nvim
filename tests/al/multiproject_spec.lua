describe("al.multiproject._al_settings_from_workspace", function()
    local mp

    before_each(function()
        package.loaded["al.multiproject"] = nil
        mp = require("al.multiproject")
    end)

    it("extracts al.* keys, stripping the prefix", function()
        local result = mp._al_settings_from_workspace({
            ["al.ruleSetPath"] = "/x/ruleset.json",
            ["al.browser"] = "Edge",
        })
        assert.equals("/x/ruleset.json", result.ruleSetPath)
        assert.equals("Edge", result.browser)
    end)

    it("ignores non-al.* keys", function()
        local result = mp._al_settings_from_workspace({
            ["al.browser"] = "Edge",
            ["xml.validation.namespaces.enabled"] = "onNamespaceEncountered",
            ["git.branchProtection"] = { "main" },
        })
        assert.equals("Edge", result.browser)
        assert.is_nil(result["validation.namespaces.enabled"])
        assert.is_nil(result["branchProtection"])
    end)

    -- Decompiling ms-dynamics-smb.al's extension.js shows zero occurrences of
    -- the literal "${workspaceFolder}" substitution syntax anywhere in the
    -- extension itself. Confirmed against a real build: the AL compiler
    -- (alc, the same binary VS Code and al.nvim both invoke) received the
    -- *unsubstituted* literal string in al.ruleSetPath -- "${workspaceFolder}"
    -- was treated as an inert path segment absorbed into the surrounding
    -- "../" traversal by the compiler itself, not replaced with an actual
    -- folder path beforehand. So al.nvim must not substitute it either, or
    -- it produces a *different* wrong answer than the compiler's own.
    it("passes ${workspaceFolder} through literally, without substitution", function()
        local result = mp._al_settings_from_workspace({
            ["al.ruleSetPath"] = "${workspaceFolder}/../../../../fondof.ruleset.json",
        })
        assert.equals("${workspaceFolder}/../../../../fondof.ruleset.json", result.ruleSetPath)
    end)

    it("passes array-valued settings through literally too", function()
        local result = mp._al_settings_from_workspace({
            ["al.packageCachePath"] = { "${workspaceFolder}/../../../.alpackages" },
        })
        assert.same({ "${workspaceFolder}/../../../.alpackages" }, result.packageCachePath)
    end)

    it("returns an empty table for nil settings", function()
        local result = mp._al_settings_from_workspace(nil)
        assert.same({}, result)
    end)
end)

describe("al.multiproject.on_workspace_loaded seeds Config.workspace", function()
    local mp
    local Config
    local orig_al_settings

    before_each(function()
        package.loaded["al.multiproject"] = nil
        package.loaded["al.config"] = nil
        mp = require("al.multiproject")
        Config = require("al.config")
        orig_al_settings = vim.deepcopy(Config.workspace.alResourceConfigurationSettings)
    end)

    after_each(function()
        Config.workspace.alResourceConfigurationSettings = orig_al_settings
        vim.cmd("silent! %bwipeout!")
    end)

    -- Neovim's LSP client sends its static `settings` (Config.workspace's
    -- alResourceConfigurationSettings) exactly once via
    -- workspace/didChangeConfiguration at client initialize -- well before
    -- al/setActiveWorkspace ever runs for any folder. So the very first
    -- project opened in a workspace session previously got analyzed against
    -- only the generic single-project defaults (e.g.
    -- ruleSetPath = ".vscode/ruleset.json"), even in a multi-root workspace
    -- whose own settings specify something else entirely.
    it("merges the workspace file's al.* settings into the static default", function()
        mp.on_workspace_loaded({
            file = "/srv/Apps.code-workspace",
            name = "Apps",
            folders = {
                { name = "Base Application", path = "/srv/apps/BaseApplication/app" },
                { name = "Other", path = "/srv/apps/Other/app" },
            },
            settings = {
                ["al.ruleSetPath"] = "${workspaceFolder}/../../../../ruleset.json",
            },
        })

        assert.equals(
            "${workspaceFolder}/../../../../ruleset.json",
            Config.workspace.alResourceConfigurationSettings.ruleSetPath
        )
    end)

    it("does not clobber unrelated static defaults not present in workspace settings", function()
        mp.on_workspace_loaded({
            file = "/srv/Apps.code-workspace",
            name = "Apps",
            folders = { { name = "Base Application", path = "/srv/apps/BaseApplication/app" } },
            settings = { ["al.ruleSetPath"] = "${workspaceFolder}/../../../../ruleset.json" },
        })

        assert.equals(orig_al_settings.enableCodeAnalysis, Config.workspace.alResourceConfigurationSettings.enableCodeAnalysis)
    end)
end)
