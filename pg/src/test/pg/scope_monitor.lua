-- Test: scope monitor receives events for scoped group only
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local s = pg.scope("scope_mon")
    local group = "test.scope_monitor"

    -- subscribe to scoped monitor for the group
    local sub, members, err = s.monitor(group)
    assert.no_error(sub, err, "scoped monitor should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(members, "members should be a table")
    assert.eq(#members, 0, "initial members should be empty")

    local ch = sub:channel()

    -- join the group via scope — should trigger event
    local ok, err2 = s.join(group)
    assert.no_error(ok, err2, "scoped join")

    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event")

    local evt = result.value
    assert.eq(evt.system, "pg", "event system should be pg")
    assert.eq(evt.kind, "member.joined", "event should be member.joined")
    -- monitor path should be the full prefixed group since monitor subscribes to it
    assert.not_nil(evt.path, "event path should not be nil")

    -- leave via scope — should trigger leave event
    s.leave(group)

    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event")
    assert.eq(result.value.kind, "member.left", "should be member.left")

    -- join a different non-scoped group — should NOT produce event on our scoped monitor
    pg.join("test.scope_monitor.unrelated")

    timeout = time.after("500ms")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.eq(result.channel, timeout, "should NOT receive events for unrelated group")

    -- cleanup
    pg.leave("test.scope_monitor.unrelated")
    sub:close()
end

return { main = main }
