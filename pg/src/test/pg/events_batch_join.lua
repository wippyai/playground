-- Test: pg.events() receives events for batch join operations
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local groups = {"test.evt_batch.a", "test.evt_batch.b", "test.evt_batch.c"}

    -- subscribe to events first
    local sub, snapshot, err = pg.events()
    assert.no_error(sub, err, "pg.events should succeed")
    local ch = sub:channel()

    -- batch join 3 groups at once
    local ok, err2 = pg.join(groups)
    assert.no_error(ok, err2, "batch join should succeed")

    -- we should receive at least one member.joined event for each group
    -- (batch join may emit one event per group or one event for all)
    local joined_groups = {}
    for i = 1, #groups do
        local timeout = time.after("3s")
        local result = channel.select{
            ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "should receive join event #" .. i)

        local evt = result.value
        assert.eq(evt.system, "pg", "event system should be pg")
        assert.eq(evt.kind, "member.joined", "event should be member.joined")
        assert.not_nil(evt.data.Group, "event data.Group should not be nil")
        joined_groups[evt.data.Group] = true
    end

    -- verify all groups received a join event
    for _, group in ipairs(groups) do
        assert.ok(joined_groups[group], group .. " should have a join event")
    end

    -- cleanup: batch leave
    pg.leave(groups)

    -- drain leave events
    for i = 1, #groups do
        local timeout = time.after("3s")
        local result = channel.select{
            ch:case_receive(),
            timeout:case_receive(),
        }
        assert.neq(result.channel, timeout, "should receive leave event #" .. i)
        assert.eq(result.value.kind, "member.left", "should be member.left")
    end

    sub:close()
end

return { main = main }
