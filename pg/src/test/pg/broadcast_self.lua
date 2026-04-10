-- Test: broadcast to self — broadcaster is a member and receives its own message
-- In Erlang PG, if the sending process is a member, it receives the broadcast too.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.broadcast_self"

    -- join the group ourselves
    local ok, err = scope:join(group)
    assert.no_error(ok, err, "pg.join should succeed")

    -- listen for broadcast messages
    local bcast_ch = process.listen("pg.self.bcast", { message = true })

    -- broadcast a message to the group (we are a member)
    ok, err = scope:broadcast(group, "pg.self.bcast", "hello from self")
    assert.no_error(ok, err, "pg.broadcast should succeed")

    -- we should receive our own broadcast
    local timeout = time.after("3s")
    local result = channel.select{
        bcast_ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive own broadcast (not timeout)")

    local msg = result.value
    assert.not_nil(msg, "message should not be nil")
    local payload = msg:payload()
    assert.not_nil(payload, "payload should not be nil")
    local data = payload:data()
    assert.eq(data, "hello from self", "payload data should match")

    -- cleanup
    scope:leave(group)
end

return { main = main }
