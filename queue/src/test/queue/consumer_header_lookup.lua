-- Test: consumer handler can read individual headers via msg:header(key)
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
        action = "test_single_header",
    }, {
        x_test_id = "single_header_test",
        priority = 42,
        correlation_id = "lookup-xyz",
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
        if sel.value and sel.value.test_id == "single_header_test" then
            result = sel.value
            break
        end
    end

    assert.not_nil(result, "should receive result before timeout")
    assert.eq(result.test_id, "single_header_test", "test_id should match")

    -- verify msg:header("priority") returned the correct value
    assert.not_nil(result.header_priority, "header_priority should not be nil")

    -- verify msg:header("correlation_id") returned the correct value
    assert.eq(result.header_correlation_id, "lookup-xyz", "correlation_id should match")

    -- verify msg:header("nonexistent_key") returned nil
    assert.is_nil(result.header_nonexistent, "nonexistent header should be nil")

    process.registry.unregister("queue_test")
end

return { main = main }
