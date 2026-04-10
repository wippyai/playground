-- Test: publish to a second queue and verify consumer receives it
local assert = require("assert")
local queue = require("queue")
local process = require("process")
local time = require("time")
local channel = require("channel")

local function main()
    local reg_ok, reg_err = process.registry.register("queue_test")
    assert.no_error(reg_ok, reg_err, "registry register should succeed")

    local result_ch = process.listen("verify_result")

    -- publish to the events queue (separate from tasks)
    local ok, err = queue.publish("app:events", {
        action = "event_test",
        event_type = "user.created",
    }, {
        x_test_id = "events_queue_test",
    })
    assert.no_error(ok, err, "publish to events queue should succeed")

    local deadline = time.after("5s")
    local result = nil
    while true do
        local sel = channel.select({
            result_ch:case_receive(),
            deadline:case_receive(),
        })
        if sel.index == 2 then break end
        if sel.value and sel.value.test_id == "events_queue_test" then
            result = sel.value
            break
        end
    end

    assert.not_nil(result, "should receive result before timeout")
    assert.eq(result.test_id, "events_queue_test", "test_id should match")
    assert.eq(result.has_id, true, "message should have an ID")

    process.registry.unregister("queue_test")
end

return { main = main }
