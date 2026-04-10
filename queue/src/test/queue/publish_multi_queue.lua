-- Test: publish to two different queues in sequence
local assert = require("assert")
local queue = require("queue")

local function main()
    -- publish to first queue
    local ok1, err1 = queue.publish("app:tasks", {
        action = "queue_one",
        target = "tasks",
    })
    assert.no_error(ok1, err1, "publish to tasks queue should succeed")
    assert.eq(ok1, true, "publish should return true")

    -- publish to second queue
    local ok2, err2 = queue.publish("app:events", {
        action = "queue_two",
        target = "events",
    })
    assert.no_error(ok2, err2, "publish to events queue should succeed")
    assert.eq(ok2, true, "publish should return true")
end

return { main = main }
