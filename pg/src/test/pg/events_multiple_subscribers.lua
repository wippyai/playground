-- Test: two concurrent pg.events() subscriptions both receive events
-- Verifies that multiple subscribers to pg events all get notified independently.
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.events_multi_sub"

    -- create two subscriptions
    local sub1, groups1, err1 = pg.events()
    assert.no_error(sub1, err1, "first pg.events should succeed")
    local ch1 = sub1:channel()

    local sub2, groups2, err2 = pg.events()
    assert.no_error(sub2, err2, "second pg.events should succeed")
    local ch2 = sub2:channel()

    -- join a group
    local ok, jerr = pg.join(group)
    assert.no_error(ok, jerr, "pg.join should succeed")

    -- both channels should receive the join event
    local timeout = time.after("3s")
    local r1 = channel.select{
        ch1:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(r1.channel, timeout, "sub1 should receive join event (not timeout)")
    assert.eq(r1.value.kind, "member.joined", "sub1 event should be member.joined")
    assert.eq(r1.value.data.Group, group, "sub1 event group should match")

    timeout = time.after("3s")
    local r2 = channel.select{
        ch2:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(r2.channel, timeout, "sub2 should receive join event (not timeout)")
    assert.eq(r2.value.kind, "member.joined", "sub2 event should be member.joined")
    assert.eq(r2.value.data.Group, group, "sub2 event group should match")

    -- leave the group
    pg.leave(group)

    -- both should receive the leave event
    timeout = time.after("3s")
    r1 = channel.select{
        ch1:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(r1.channel, timeout, "sub1 should receive leave event (not timeout)")
    assert.eq(r1.value.kind, "member.left", "sub1 leave event kind should match")

    timeout = time.after("3s")
    r2 = channel.select{
        ch2:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(r2.channel, timeout, "sub2 should receive leave event (not timeout)")
    assert.eq(r2.value.kind, "member.left", "sub2 leave event kind should match")

    -- cleanup
    sub1:close()
    sub2:close()
end

return { main = main }
