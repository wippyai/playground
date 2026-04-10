-- Test: publish a basic message to the tasks queue
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {
        action = "process_order",
        order_id = 12345,
    })
    assert.no_error(ok, err, "publish should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
