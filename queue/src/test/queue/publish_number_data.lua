-- Test: publish a number as message data
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", 42)
    assert.no_error(ok, err, "publish number data should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
