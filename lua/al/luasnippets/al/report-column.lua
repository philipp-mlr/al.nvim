-- "Snippet: Column": {
--         "prefix": "tcolumn",
--         "body": [
--             "column(${1:ColumnName}; ${2:SourceFieldName})",
--             "{",
--             "\t${0}",
--             "}"
--         ],
--         "description": "Snippet: Column"
--     },

local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        {
            trig = "tcolumn",
            desc = "Snippet: Column",
        },
        fmt(
            [[
            column({}; {})
            {{
                {}
            }}
        ]],
            {
                i(1, "ColumnName"),
                i(2, "SourceFieldName"),
                i(0),
            }
        )
    ),
}
