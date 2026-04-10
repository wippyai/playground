-- Test: publish with standard queue headers (timestamp, priority, ttl, etc.)
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
        action = "test_standard_headers",
    }, {
        x_test_id = "standard_headers_test",
        priority = 9,
        ttl = 3600,
        correlation_id = "req-standard-001",
        reply_to = "app:tasks",
        content_type = "application/json",
        message_type = "order.created",
    })
    assert.no_error(ok, err, "publish with standard headers should succeed")

    local deadline = time.after("5s")
    local result = nil
    while true do
        local sel = channel.select({
            result_ch:case_receive(),
            deadline:case_receive(),
        })
        if sel.index == 2 then break end
        if sel.value and sel.value.test_id == "standard_headers_test" then
            result = sel.value
            break
        end
    end

    assert.not_nil(result, "should receive result before timeout")
    assert.eq(result.test_id, "standard_headers_test", "test_id should match")

    -- verify standard headers are present
    assert.not_nil(result.headers, "headers should not be nil")
    assert.eq(result.headers["correlation_id"], "req-standard-001", "correlation_id should match")
    assert.eq(result.headers["reply_to"], "app:tasks", "reply_to should match")
    assert.eq(result.headers["content_type"], "application/json", "content_type should match")
    assert.eq(result.headers["message_type"], "order.created", "message_type should match")

    process.registry.unregister("queue_test")
end

return { main = main }
