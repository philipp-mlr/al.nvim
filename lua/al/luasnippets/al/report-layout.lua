-- "Snippet: Report Layout": {
--     "prefix": "treportlayout",
--     "body": [
--         "layout(${0:LayoutName})",
--         "{",
--         "\tType = ${1:Excel};",
--         "\tLayoutFile = '${2:mySpreadsheet.xlsx}';",
--         "}"
--     ],
--     "description": "Snippet: Report Layout"
-- }

local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        {
            trig = "treportlayout",
            desc = "Snippet: Report Layout",
        },
        fmt(
            [[
            layout({})
            {{
                Type = {};
                LayoutFile = '{}';
            }}
        ]],
            {
                i(1, "LayoutName"),
                i(2, "Excel"),
                i(3, "mySpreadsheet.xlsx"),
                -- i(0),
            }
        )
    ),
}
