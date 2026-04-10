-- Test: broadcast to one topic does not deliver to listeners of another topic
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.bcast_topic_iso"

    -- join the group
    local ok, err = pg.join(group)
    assert.no_error(ok, err, "pg.join should succeed")

    -- listen for two different topics
    local ch_a = process.listen("topic.A", { message = true })
    local ch_b = process.listen("topic.B", { message = true })

    -- broadcast only to topic.A
    ok, err = pg.broadcast(group, "topic.A", "msg_a")
    assert.no_error(ok, err, "pg.broadcast to topic.A should succeed")

    -- topic.A should receive the message
    local timeout = time.after("3s")
    local result = channel.select{
        ch_a:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive topic.A broadcast (not timeout)")

    local msg = result.value
    assert.not_nil(msg, "topic.A message should not be nil")
    local payload = msg:payload()
    assert.not_nil(payload, "topic.A payload should not be nil")
    assert.eq(payload:data(), "msg_a", "topic.A payload data should match")

    -- topic.B should NOT receive anything (wait 500ms)
    timeout = time.after("500ms")
    result = channel.select{
        ch_b:case_receive(),
        timeout:case_receive(),
    }
    assert.eq(result.channel, timeout,
        "topic.B should NOT receive any message (got timeout as expected)")

    -- cleanup
    pg.leave(group)
end

return { main = main }
