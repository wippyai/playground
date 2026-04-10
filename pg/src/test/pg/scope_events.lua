-- Test: instance events — snapshot contains groups for this instance only
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local s = pg.open("app:pg")
    local scoped_group = "test.scope_events.scoped"

    -- join a group through the instance
    local ok, err = s:join(scoped_group)
    assert.no_error(ok, err, "join")

    -- subscribe to instance events
    local sub, snapshot, serr = s:events()
    assert.no_error(sub, serr, "events should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(snapshot, "snapshot should be a table")

    -- snapshot should include the group
    assert.not_nil(snapshot[scoped_group], "snapshot should include group")
    assert.is_table(snapshot[scoped_group], "group members should be a table")
    assert.gte(#snapshot[scoped_group], 1, "group should have at least 1 member")

    local ch = sub:channel()

    -- leave from the group — should get an event
    s:leave(scoped_group)

    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event for group")

    local evt = result.value
    assert.eq(evt.kind, "member.left", "event should be member.left")
    assert.eq(evt.path, scoped_group, "event path should be the group name")

    -- drain any remaining event from the channel before closing
    timeout = time.after("500ms")
    channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }

    sub:close()
end

return { main = main }
