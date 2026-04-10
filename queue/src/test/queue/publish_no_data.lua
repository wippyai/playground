-- Test: publishing with no data argument returns an error
local assert = require("assert")
local queue = require("queue")

local function main()
    local ok, err = queue.publish("app:tasks")
    assert.eq(ok, nil, "publish with no data should return nil")
    assert.neq(err, nil, "publish with no data should return an error")
end

return { main = main }
