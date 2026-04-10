-- Test: consumer receives message and msg:id() returns non-empty string
local assert = require("assert")
local queue = require("queue")
local process = require("process")
local time = require("time")
local channel = require("channel")

local function main()
    -- register so handler can find us
    local reg_ok, reg_err = process.registry.register("queue_test")
    assert.no_error(reg_ok, reg_err, "registry register should succeed")

    -- listen for verify results before publishing
    local result_ch = process.listen("verify_result")

    -- publish with test marker
    local ok, err = queue.publish("app:verify_tasks", {
        action = "test_msg_id",
    }, {
        x_test_id = "msg_id_test",
    })
    assert.no_error(ok, err, "publish should succeed")

    -- wait for our specific result (discard messages from other tests)
    local deadline = time.after("5s")
    local result = nil
    while true do
        local sel = channel.select({
            result_ch:case_receive(),
            deadline:case_receive(),
        })
        if sel.index == 2 then
            break -- timeout
        end
        if sel.value and sel.value.test_id == "msg_id_test" then
            result = sel.value
            break
        end
        -- else: stale message from another test, keep waiting
    end

    assert.not_nil(result, "should receive result before timeout")
    assert.eq(result.test_id, "msg_id_test", "test_id should match")
    assert.eq(result.has_id, true, "message should have a non-empty ID")
    assert.not_nil(result.msg_id, "msg_id should not be nil")

    process.registry.unregister("queue_test")
end

return { main = main }
