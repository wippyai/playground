-- Test: broadcast_local delivers to self when self is a member
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.bcast_local_self"

    -- join the group
    local ok, err = pg.join(group)
    assert.no_error(ok, err, "pg.join should succeed")

    -- listen for the broadcast topic
    local bcast_ch = process.listen("pg.local.self", { message = true })

    -- broadcast_local to the group
    ok, err = pg.broadcast_local(group, "pg.local.self", "local hello")
    assert.no_error(ok, err, "pg.broadcast_local should succeed")

    -- we should receive the message
    local timeout = time.after("3s")
    local result = channel.select{
        bcast_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive local broadcast (not timeout)")

    -- verify payload data matches
    local msg = result.value
    assert.not_nil(msg, "message should not be nil")
    local payload = msg:payload()
    assert.not_nil(payload, "payload should not be nil")
    local data = payload:data()
    assert.eq(data, "local hello", "payload data should match")

    -- cleanup
    pg.leave(group)
end

return { main = main }
