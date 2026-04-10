-- Test: publish with table data containing mixed value types
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {
        string_val = "hello",
        number_val = 99.9,
        int_val = 42,
        bool_val = true,
        nil_val_skipped = nil, -- nil values should be skipped in Lua tables
        nested = {
            a = 1,
            b = "two",
            c = false,
        },
    })
    assert.no_error(ok, err, "publish mixed types should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
