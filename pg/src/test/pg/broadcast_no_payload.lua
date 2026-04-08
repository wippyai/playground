-- Test: broadcast with no extra payload data (just group + topic)
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.broadcast_no_payload"

    -- join the group ourselves
    local ok, err = pg.join(group)
    assert.no_error(ok, err, "pg.join should succeed")

    -- listen for broadcast
    local bcast_ch = process.listen("pg.no.payload", { message = true })

    -- broadcast with no payload args (only group and topic)
    ok, err = pg.broadcast(group, "pg.no.payload")
    assert.no_error(ok, err, "broadcast with no payload should succeed")

    -- we should still receive the message (though payload may be nil)
    local timeout = time.after("3s")
    local result = channel.select{
        bcast_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive broadcast (not timeout)")
    assert.not_nil(result.value, "message should not be nil")

    -- cleanup
    pg.leave(group)
end

return { main = main }
