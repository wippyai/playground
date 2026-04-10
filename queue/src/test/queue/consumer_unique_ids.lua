-- Test: each consumed message has a unique ID
local assert = require("assert")
local queue = require("queue")
local process = require("process")
local time = require("time")
local channel = require("channel")

local function main()
    local reg_ok, reg_err = process.registry.register("queue_test")
    assert.no_error(reg_ok, reg_err, "registry register should succeed")

    local result_ch = process.listen("verify_result")

    -- publish 5 messages
    local count = 5
    for i = 1, count do
        local ok, err = queue.publish("app:verify_tasks", {
            action = "unique_id_test",
            seq = i,
        }, {
            x_test_id = "uid_" .. i,
        })
        assert.no_error(ok, err, "publish #" .. i .. " should succeed")
    end

    -- collect all message IDs, filtering by expected test IDs
    local ids = {}
    local expected_ids = {}
    for i = 1, count do
        expected_ids["uid_" .. i] = true
    end
    local remaining = count
    local deadline = time.after("10s")

    while remaining > 0 do
        local sel = channel.select({
            result_ch:case_receive(),
            deadline:case_receive(),
        })
        if sel.index == 2 then break end

        local result = sel.value
        if result and result.test_id and expected_ids[result.test_id] and not ids[result.test_id] then
            assert.not_nil(result.msg_id, "msg_id should not be nil")
            assert.eq(result.has_id, true, "has_id should be true")

            -- check uniqueness of message IDs
            for _, existing_id in pairs(ids) do
                assert.neq(result.msg_id, existing_id, "message ID " .. result.msg_id .. " should be unique")
            end

            ids[result.test_id] = result.msg_id
            remaining = remaining - 1
        end
    end

    assert.eq(remaining, 0, "should have received all " .. count .. " messages")

    process.registry.unregister("queue_test")
end

return { main = main }
