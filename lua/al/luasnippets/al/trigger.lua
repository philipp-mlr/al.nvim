local ls = require("luasnip")

local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        {
            trig = "ttrigger",
            desc = "Snippet: Trigger",
        },
        fmt(
            [[
            trigger {}({})
            var
                {}: {};
            begin
                {}
            end;
        ]],
            {
                i(1, "OnWhat"),
                i(2),
                i(3, "myInt"),
                i(4, "Integer"),
                i(0),
            }
        )
    ),
}
