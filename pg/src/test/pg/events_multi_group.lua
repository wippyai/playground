-- Test: pg.events() receives events for multiple groups
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local group_a = "test.events_multi.alpha"
    local group_b = "test.events_multi.beta"

    -- subscribe to pg events
    local sub, err = pg.events()
    assert.no_error(sub, err, "pg.events should succeed")

    local ch = sub:channel()

    -- join two different groups
    pg.join(group_a)
    pg.join(group_b)

    -- receive two join events
    local events_received = {}
    for i = 1, 2 do
        local timeout = time.after("3s")
        local result = channel.select{
            ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "should receive event " .. i .. " (not timeout)")
        local evt = result.value
        assert.eq(evt.kind, "member.joined", "event " .. i .. " should be member.joined")
        table.insert(events_received, evt.data.Group)
    end

    -- verify we got events for both groups (order may vary)
    table.sort(events_received)
    assert.eq(#events_received, 2, "should receive 2 events")
    assert.eq(events_received[1], group_a, "first group should be alpha")
    assert.eq(events_received[2], group_b, "second group should be beta")

    -- cleanup
    pg.leave(group_a)
    pg.leave(group_b)
    sub:close()
end

return { main = main }
