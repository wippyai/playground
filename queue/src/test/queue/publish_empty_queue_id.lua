-- Test: publishing with an empty queue ID returns an error
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("", { action = "test" })
    assert.eq(ok, nil, "publish to empty queue ID should return nil")
    assert.neq(err, nil, "publish to empty queue ID should return an error")
end

return { main = main }
