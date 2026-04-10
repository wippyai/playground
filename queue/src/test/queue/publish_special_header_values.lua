-- Test: publish with headers containing special characters in values
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {
        action = "special_header_test",
    }, {
        trace_id = "abc-123-def-456",
        path = "/api/v1/users?page=1&limit=10",
        user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        custom_json = '{"key":"value"}',
    })
    assert.no_error(ok, err, "publish with special header values should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
