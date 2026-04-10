-- Test: publish returns two values (ok, err) consistently
local assert = require("assert")
local queue = require("queue")

local function main()
    -- successful publish should return (true, nil)
    local ok, err = queue.publish("app:tasks", { action = "test" })
    assert.eq(ok, true, "successful publish should return true")
    assert.is_nil(err, "successful publish should have nil error")

    -- failed publish should return (nil, error)
    local ok2, err2 = queue.publish("app:nonexistent", { action = "test" })
    assert.is_nil(ok2, "failed publish should return nil")
    assert.not_nil(err2, "failed publish should return an error")

    -- verify error has useful info
    local err_str = tostring(err2)
    assert.neq(err_str, "", "error string should not be empty")
end

return { main = main }
