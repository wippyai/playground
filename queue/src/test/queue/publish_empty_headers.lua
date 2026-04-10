-- Test: publish with an empty headers table (should succeed)
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {
        action = "no_headers",
    }, {})
    assert.no_error(ok, err, "publish with empty headers should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
