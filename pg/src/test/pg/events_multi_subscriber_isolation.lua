-- Test: closing one events subscriber does not affect another
-- Subscribe twice, close one, verify the other still receives events.
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group1 = "test.evt_iso"
    local group2 = "test.evt_iso_2"

    -- create two subscriptions
    local sub1, _, err1 = pg.events()
    assert.no_error(sub1, err1, "first pg.events should succeed")
    local ch1 = sub1:channel()

    local sub2, _, err2 = pg.events()
    assert.no_error(sub2, err2, "second pg.events should succeed")
    local ch2 = sub2:channel()

    -- join the first group
    local ok, jerr = pg.join(group1)
    assert.no_error(ok, jerr, "pg.join group1 should succeed")

    -- both channels should receive the join event
    local timeout = time.after("3s")
    local r1 = channel.select{
        ch1:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(r1.channel, timeout, "sub1 should receive join event for group1")

    timeout = time.after("3s")
    local r2 = channel.select{
        ch2:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(r2.channel, timeout, "sub2 should receive join event for group1")

    -- close sub1
    sub1:close()

    -- join a second group
    ok, jerr = pg.join(group2)
    assert.no_error(ok, jerr, "pg.join group2 should succeed")

    -- sub2 should still receive the event
    timeout = time.after("3s")
    r2 = channel.select{
        ch2:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(r2.channel, timeout, "sub2 should still receive join event for group2")
    assert.eq(r2.value.kind, "member.joined", "sub2 event should be member.joined")

    -- sub1's channel should NOT receive anything (it is closed) — short timeout
    timeout = time.after("300ms")
    r1 = channel.select{
        ch1:case_receive(),
        timeout:case_receive(),
    }
    assert.eq(r1.channel, timeout, "sub1 should NOT receive events after close (timeout expected)")

    -- cleanup
    sub2:close()
    pg.leave(group1)
    pg.leave(group2)
end

return { main = main }
