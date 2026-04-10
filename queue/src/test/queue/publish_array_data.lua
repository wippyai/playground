-- Test: publish with array-style table data
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {
        "first",
        "second",
        "third",
        42,
        true,
    })
    assert.no_error(ok, err, "publish array table should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
