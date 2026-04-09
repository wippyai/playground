-- Test: pg.monitor() receives join and leave events for a specific group
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.monitor_basic"

    -- subscribe to monitor for this group
    local sub, members, err = pg.monitor(group)
    assert.no_error(sub, err, "pg.monitor should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(members, "members snapshot should be a table")
    assert.eq(#members, 0, "initial members should be empty")

    local ch = sub:channel()
    assert.not_nil(ch, "channel should not be nil")

    -- join the group - should trigger a join event
    local ok, err2 = pg.join(group)
    assert.no_error(ok, err2, "pg.join should succeed")

    -- wait for join event
    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event (not timeout)")

    local evt = result.value
    assert.not_nil(evt, "event should not be nil")
    assert.eq(evt.system, "pg", "event system should be 'pg'")
    assert.eq(evt.kind, "member.joined", "event kind should be 'member.joined'")
    assert.eq(evt.path, group, "event path should be the group name")

    -- leave the group - should trigger a leave event
    pg.leave(group)

    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event (not timeout)")

    evt = result.value
    assert.eq(evt.kind, "member.left", "event kind should be 'member.left'")
    assert.eq(evt.path, group, "leave event path should be the group name")

    -- cleanup
    sub:close()
end

return { main = main }
