-- Test: pg.events() delivers member.joined event on self-join
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.events_basic"

    -- subscribe to pg events
    local sub, err = pg.events()
    assert.no_error(sub, err, "pg.events should succeed")
    assert.not_nil(sub, "subscription should not be nil")

    local ch = sub:channel()
    assert.not_nil(ch, "channel should not be nil")

    -- join a group (this should emit a member.joined event)
    local ok, err2 = pg.join(group)
    assert.no_error(ok, err2, "pg.join should succeed")

    -- wait for event with timeout
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
    assert.not_nil(evt.data, "event data should not be nil")
    assert.eq(evt.data.Group, group, "event data.Group should match")
    assert.not_nil(evt.data.PIDs, "event data.PIDs should not be nil")

    -- cleanup
    pg.leave(group)
    sub:close()
end

return { main = main }
