local ls = require("luasnip")

local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        {
            trig = "tdataitem",
            desc = "Snippet: Report Data Item",
        },
        fmt(
            [[
            dataitem({}; {})
            {{
                column({}, {})
                {{
                    {}
                }}
            }}
        ]],
            {
                i(1, "DataItemName"),
                i(2, "SourceTableName"),
                i(3, "ColumnName"),
                i(4, "SourceFieldName"),
                i(0),
            }
        )
    ),
}
