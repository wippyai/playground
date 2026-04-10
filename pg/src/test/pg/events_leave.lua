-- Test: scope:events() delivers member.left event on leave
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.events_leave"

    -- subscribe to pg events
    local sub, groups, err = scope:events()
    assert.no_error(sub, err, "pg.events should succeed")

    local ch = sub:channel()

    -- join a group
    local ok, err2 = scope:join(group)
    assert.no_error(ok, err2, "pg.join should succeed")

    -- consume the join event
    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event (not timeout)")
    assert.eq(result.value.kind, "member.joined", "first event should be member.joined")

    -- now leave the group
    ok, err2 = scope:leave(group)
    assert.no_error(ok, err2, "pg.leave should succeed")

    -- wait for leave event
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event (not timeout)")

    local evt = result.value
    assert.eq(evt.system, "pg", "event system should be 'pg'")
    assert.eq(evt.kind, "member.left", "event kind should be 'member.left'")
    assert.eq(evt.path, group, "event path should be the group name")
    assert.eq(evt.data.Group, group, "event data.Group should match")

    -- cleanup
    sub:close()
end

return { main = main }
