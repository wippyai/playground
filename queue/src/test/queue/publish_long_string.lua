-- Test: publish with very long string data
local assert = require("assert")
local queue = require("queue")

local function main()
    -- create a 10KB string
    local long_string = string.rep("abcdefghij", 1000)

    local ok, err = queue.publish("app:tasks", {
        action = "long_string_test",
        content = long_string,
    })
    assert.no_error(ok, err, "publish with long string should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
