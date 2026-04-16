-- Test: worker joins both room1 and room2, broadcast to room1 only delivers room1 message
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local room1 = "test.bcast_mgi.room1"
    local room2 = "test.bcast_mgi.room2"

    -- join both groups
    local ok, err
    ok, err = scope:join(room1)
    assert.no_error(ok, err, "join room1 should succeed")
    ok, err = scope:join(room2)
    assert.no_error(ok, err, "join room2 should succeed")

    -- listen for broadcasts on two topics (one per room)
    local ch_r1 = process.listen("room1.msg", { message = true })
    local ch_r2 = process.listen("room2.msg", { message = true })

    -- broadcast only to room1
    ok, err = scope:broadcast(room1, "room1.msg", "hello_room1")
    assert.no_error(ok, err, "broadcast to room1 should succeed")

    -- room1 listener should receive the message
    local timeout = time.after("3s")
    local result = channel.select{
        ch_r1:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive room1 broadcast")

    local msg = result.value
    assert.not_nil(msg, "room1 message should not be nil")
    local payload = msg:payload()
    assert.not_nil(payload, "room1 payload should not be nil")
    assert.eq(payload:data(), "hello_room1", "room1 payload should match")

    -- room2 listener should NOT receive anything
    timeout = time.after("500ms")
    result = channel.select{
        ch_r2:case_receive(),
        timeout:case_receive(),
    }
    assert.eq(result.channel, timeout,
        "room2 should NOT receive any message from room1 broadcast")

    -- cleanup
    scope:leave(room1)
    scope:leave(room2)
end

return { main = main }
