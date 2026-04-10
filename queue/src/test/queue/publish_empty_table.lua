-- Test: publishing an empty table as data returns an error
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks", {})
    assert.eq(ok, nil, "publish empty table should return nil")
    assert.neq(err, nil, "publish empty table should return an error")
end

return { main = main }
