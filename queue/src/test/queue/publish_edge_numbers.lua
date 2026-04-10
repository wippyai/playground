-- Test: publish with numeric zero and negative values in data and headers
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {
        zero = 0,
        negative = -42,
        negative_float = -3.14,
        large = 999999999,
    }, {
        priority = 0,
        ttl = -1,
    })
    assert.no_error(ok, err, "publish with zero/negative values should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
