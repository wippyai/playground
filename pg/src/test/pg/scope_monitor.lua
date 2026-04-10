-- Test: instance monitor receives events for monitored group only
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local s = pg.open("app:pg")
    local group = "test.scope_monitor"

    -- subscribe to monitor for the group
    local sub, members, err = s:monitor(group)
    assert.no_error(sub, err, "monitor should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(members, "members should be a table")
    assert.eq(#members, 0, "initial members should be empty")

    local ch = sub:channel()

    -- join the group via instance — should trigger event
    local ok, err2 = s:join(group)
    assert.no_error(ok, err2, "join")

    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event")

    local evt = result.value
    assert.eq(evt.system, "pg", "event system should be pg")
    assert.eq(evt.kind, "member.joined", "event should be member.joined")
    assert.not_nil(evt.path, "event path should not be nil")

    -- leave via instance — should trigger leave event
    s:leave(group)

    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event")
    assert.eq(result.value.kind, "member.left", "should be member.left")

    -- joining a group on a different instance should NOT produce event on our monitor
    local s2 = pg.open("app:pg_alt")
    s2:join("test.scope_monitor.unrelated")

    timeout = time.after("500ms")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.eq(result.channel, timeout, "should NOT receive events for unrelated group on different instance")

    -- cleanup
    s2:leave("test.scope_monitor.unrelated")
    sub:close()
end

return { main = main }
