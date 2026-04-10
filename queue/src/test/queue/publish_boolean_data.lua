-- Test: publish a boolean as message data
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", true)
    assert.no_error(ok, err, "publish boolean data should succeed")
    assert.eq(ok, true, "publish should return true")
end

return { main = main }
