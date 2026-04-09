-- Test: pg.monitor() only receives events for the monitored group
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local target_group = "test.monitor_filter.target"
    local other_group = "test.monitor_filter.other"

    -- monitor only the target group
    local sub, members, err = pg.monitor(target_group)
    assert.no_error(sub, err, "pg.monitor should succeed")
    assert.is_table(members, "members should be a table")

    local ch = sub:channel()

    -- join the OTHER group first (should NOT trigger an event on our monitor)
    local ok, err2 = pg.join(other_group)
    assert.no_error(ok, err2, "join other group")

    -- join the TARGET group (should trigger an event)
    ok, err2 = pg.join(target_group)
    assert.no_error(ok, err2, "join target group")

    -- we should receive an event for the target group only
    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive target join event")

    local evt = result.value
    assert.eq(evt.path, target_group, "event should be for target group")
    assert.eq(evt.kind, "member.joined", "should be a join event")

    -- leave both groups
    pg.leave(target_group)
    pg.leave(other_group)

    -- we should receive a leave event for target only
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive target leave event")

    evt = result.value
    assert.eq(evt.path, target_group, "leave event should be for target group")
    assert.eq(evt.kind, "member.left", "should be a leave event")

    -- verify no more events are pending (the other_group events should not appear)
    timeout = time.after("500ms")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.eq(result.channel, timeout, "should NOT receive events for other group")

    -- cleanup
    sub:close()
end

return { main = main }
