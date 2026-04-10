-- Test: consumer handler receives message with timestamp header auto-set
local assert = require("assert")
local queue = require("queue")
local process = require("process")
local time = require("time")
local channel = require("channel")

local function main()
    local reg_ok, reg_err = process.registry.register("queue_test")
    assert.no_error(reg_ok, reg_err, "registry register should succeed")

    local result_ch = process.listen("verify_result")

    local ok, err = queue.publish("app:verify_tasks", {
        action = "timestamp_test",
    }, {
        x_test_id = "timestamp_test",
    })
    assert.no_error(ok, err, "publish should succeed")

    local deadline = time.after("5s")
    local result = nil
    while true do
        local sel = channel.select({
            result_ch:case_receive(),
            deadline:case_receive(),
        })
        if sel.index == 2 then break end
        if sel.value and sel.value.test_id == "timestamp_test" then
            result = sel.value
            break
        end
    end

    assert.not_nil(result, "should receive result before timeout")
    assert.eq(result.test_id, "timestamp_test", "test_id should match")

    -- the queue system auto-sets a timestamp header on every message
    assert.not_nil(result.headers, "headers should not be nil")
    assert.not_nil(result.headers["timestamp"], "timestamp header should be auto-set")

    process.registry.unregister("queue_test")
end

return { main = main }
