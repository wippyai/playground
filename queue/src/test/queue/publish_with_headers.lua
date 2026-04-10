-- Test: publish a message with custom headers
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {
        action = "send_email",
        user_id = 456,
    }, {
        priority = 10,
        correlation_id = "req-789",
    })
    assert.no_error(ok, err, "publish with headers should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
