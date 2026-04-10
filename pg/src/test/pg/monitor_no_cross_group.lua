-- Test: scope:monitor() does NOT receive events for a different group
-- Monitor group A, join group B, verify no event fires for the wrong group.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local monitor_group = "test.mon_cross_a"
    local other_group = "test.mon_cross_b"

    -- monitor group A
    local sub, members, err = scope:monitor(monitor_group)
    assert.no_error(sub, err, "pg.monitor should succeed")
    assert.is_table(members, "members snapshot should be a table")

    local ch = sub:channel()
    assert.not_nil(ch, "channel should not be nil")

    -- join group B (a different group)
    local ok, err2 = scope:join(other_group)
    assert.no_error(ok, err2, "join other group should succeed")

    -- wait 500ms — should NOT receive any event on the monitor channel
    local timeout = time.after("500ms")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.eq(result.channel, timeout, "should NOT receive event for a different group (timeout expected)")

    -- leave group B
    local ok2, err3 = scope:leave(other_group)
    assert.no_error(ok2, err3, "leave other group should succeed")

    -- cleanup
    sub:close()
end

return { main = main }
