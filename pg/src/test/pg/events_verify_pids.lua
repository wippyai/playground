-- Test: pg.events() event data.PIDs contains the correct PID value
-- Verifies that the PIDs field in membership events matches the actual process PID.
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.events_verify_pids"
    local my_pid = process.pid()

    -- subscribe to pg events
    local sub, err = pg.events()
    assert.no_error(sub, err, "pg.events should succeed")

    local ch = sub:channel()

    -- join a group
    local ok, err2 = pg.join(group)
    assert.no_error(ok, err2, "pg.join should succeed")

    -- receive the join event
    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event (not timeout)")

    local evt = result.value
    assert.eq(evt.kind, "member.joined", "event should be member.joined")
    assert.not_nil(evt.data.PIDs, "event data.PIDs should not be nil")
    assert.is_table(evt.data.PIDs, "event data.PIDs should be a table")
    assert.eq(#evt.data.PIDs, 1, "event data.PIDs should have 1 entry")
    assert.eq(evt.data.PIDs[1], my_pid, "PIDs[1] should match our process PID")

    -- leave the group
    pg.leave(group)

    -- receive the leave event
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event (not timeout)")

    local levt = result.value
    assert.eq(levt.kind, "member.left", "event should be member.left")
    assert.not_nil(levt.data.PIDs, "leave event data.PIDs should not be nil")
    assert.is_table(levt.data.PIDs, "leave event data.PIDs should be a table")
    assert.eq(#levt.data.PIDs, 1, "leave event data.PIDs should have 1 entry")
    assert.eq(levt.data.PIDs[1], my_pid, "leave PIDs[1] should match our process PID")

    -- cleanup
    sub:close()
end

return { main = main }
