-- Test: publish with all standard header types (string, number, boolean)
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {
        action = "test_headers",
    }, {
        -- string header
        correlation_id = "corr-12345",
        -- integer header
        priority = 5,
        -- float header
        ttl = 3600.5,
        -- boolean headers
        persistent = true,
        urgent = false,
        -- message type
        message_type = "order.created",
        -- content type
        content_type = "application/json",
    })
    assert.no_error(ok, err, "publish with typed headers should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
