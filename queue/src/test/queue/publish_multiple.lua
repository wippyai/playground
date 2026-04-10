-- Test: publish multiple messages in sequence
local assert = require("assert")
local queue = require("queue")

local function main()
    for i = 1, 5 do
        local ok, err = queue.publish("app:tasks", {
            action = "batch_item",
            index = i,
        })
        assert.no_error(ok, err, "publish message " .. i .. " should succeed")
        assert.eq(ok, true, "publish should return true")
    end
end

return { main = main }
