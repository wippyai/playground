-- Test: publishing to a non-existent queue returns an error
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:nonexistent_queue", {
        action = "test",
    })
    assert.eq(ok, nil, "publish to non-existent queue should return nil")
    assert.neq(err, nil, "publish to non-existent queue should return an error")
end

return { main = main }
