-- Test: consumer handler receives multiple messages in sequence
local assert = require("assert")
local queue = require("queue")
local process = require("process")
local time = require("time")
local channel = require("channel")

local function main()
    local reg_ok, reg_err = process.registry.register("queue_test")
    assert.no_error(reg_ok, reg_err, "registry register should succeed")

    local result_ch = process.listen("verify_result")

    -- publish 3 messages with distinct test IDs
    local count = 3
    for i = 1, count do
        local ok, err = queue.publish("app:verify_tasks", {
            action = "multi_consume",
            index = i,
        }, {
            x_test_id = "multi_" .. i,
        })
        assert.no_error(ok, err, "publish #" .. i .. " should succeed")
    end

    -- collect all results, filtering by expected test IDs
    local received = {}
    local expected = count
    local deadline = time.after("10s")

    while expected > 0 do
        local sel = channel.select({
            result_ch:case_receive(),
            deadline:case_receive(),
        })
        if sel.index == 2 then break end

        local result = sel.value
        if result and result.test_id then
            -- check if this is one of ours
            for i = 1, count do
                if result.test_id == "multi_" .. i and not received[result.test_id] then
                    received[result.test_id] = true
                    expected = expected - 1
                    break
                end
            end
        end
    end

    -- verify all messages were received
    for i = 1, count do
        local key = "multi_" .. i
        assert.eq(received[key], true, "should have received message " .. key)
    end

    process.registry.unregister("queue_test")
end

return { main = main }
