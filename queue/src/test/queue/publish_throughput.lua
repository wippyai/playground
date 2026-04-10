-- Test: publish to the same queue many times concurrently (sequential rapid fire
-- to verify the queue handles high throughput without errors)
local assert = require("assert")
local queue = require("queue")

local function main()
    local count = 50
    local errors = {}

    for i = 1, count do
        local ok, err = queue.publish("app:tasks", {
            action = "throughput_test",
            seq = i,
            payload = string.rep("x", 100), -- 100-byte payload each
        })
        if not ok or err then
            table.insert(errors, {
                index = i,
                error = tostring(err),
            })
        end
    end

    assert.eq(#errors, 0, "all " .. count .. " publishes should succeed, got " .. #errors .. " errors")
end

return { main = main }
