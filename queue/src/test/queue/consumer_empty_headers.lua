-- Test: consumer receives a message with empty headers
local assert = require("assert")
local queue = require("queue")
local process = require("process")
local time = require("time")
local channel = require("channel")

local function main()
    local reg_ok, reg_err = process.registry.register("queue_test")
    assert.no_error(reg_ok, reg_err, "registry register should succeed")

    local result_ch = process.listen("verify_result")

    -- publish without any custom headers (only x_test_id for routing)
    local ok, err = queue.publish("app:verify_tasks", {
        action = "no_custom_headers",
    }, {
        x_test_id = "empty_headers_consumer_test",
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
        if sel.value and sel.value.test_id == "empty_headers_consumer_test" then
            result = sel.value
            break
        end
    end

    assert.not_nil(result, "should receive result before timeout")
    assert.eq(result.test_id, "empty_headers_consumer_test", "test_id should match")

    -- headers should be a table (even if minimal — at least timestamp is auto-set)
    assert.is_table(result.headers, "headers should be a table")

    -- nonexistent header via msg:header() should be nil
    assert.is_nil(result.header_nonexistent, "nonexistent header should be nil")

    process.registry.unregister("queue_test")
end

return { main = main }
