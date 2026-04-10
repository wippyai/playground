-- Test: rapid sequential publish (20 messages in a loop)
local assert = require("assert")
local queue = require("queue")

local function main()
    for i = 1, 20 do
        local ok, err = queue.publish("app:tasks", {
            action = "rapid_fire",
            seq = i,
        })
        assert.no_error(ok, err, "rapid publish #" .. i .. " should succeed")
        assert.eq(ok, true, "publish should return true")
    end
end

return { main = main }
