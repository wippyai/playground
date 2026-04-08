-- Test: pg.events() receives correct sequence of join and leave events
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group = "test.events_sequence"

    -- subscribe to pg events
    local sub, err = pg.events()
    assert.no_error(sub, err, "pg.events should succeed")

    local ch = sub:channel()

    -- perform a sequence: join, join again (multi-join), leave once
    pg.join(group)
    pg.join(group)
    pg.leave(group)

    -- we should receive: joined, joined, left (3 events total)
    local events = {}
    for i = 1, 3 do
        local timeout = time.after("3s")
        local result = channel.select{
            ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "should receive event " .. i .. " (not timeout)")
        table.insert(events, result.value.kind)
    end

    assert.eq(events[1], "member.joined", "first event should be member.joined")
    assert.eq(events[2], "member.joined", "second event should be member.joined")
    assert.eq(events[3], "member.left", "third event should be member.left")

    -- leave the remaining join
    pg.leave(group)

    -- should get one more leave event
    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive final leave event (not timeout)")
    assert.eq(result.value.kind, "member.left", "final event should be member.left")

    -- cleanup
    sub:close()
end

return { main = main }
