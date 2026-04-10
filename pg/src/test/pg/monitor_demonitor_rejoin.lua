-- Test: re-subscribing to monitor after close works correctly
-- Verifies that after closing a monitor subscription, a new one can be created
-- and will receive events.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.mon_rejoin"

    -- first monitor subscription
    local sub1, members1, err = scope:monitor(group)
    assert.no_error(sub1, err, "first pg.monitor should succeed")
    assert.eq(#members1, 0, "initial members should be empty")

    -- close the first subscription
    sub1:close()

    -- create a second monitor subscription on the same group
    local sub2, members2, err2 = scope:monitor(group)
    assert.no_error(sub2, err2, "second pg.monitor should succeed")
    assert.eq(#members2, 0, "members should still be empty")

    local ch = sub2:channel()
    assert.not_nil(ch, "channel should not be nil")

    -- join the group - second monitor should receive the event
    local ok, jerr = scope:join(group)
    assert.no_error(ok, jerr, "pg.join should succeed")

    -- wait for join event on second subscription
    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "second monitor should receive join event (not timeout)")

    local evt = result.value
    assert.not_nil(evt, "event should not be nil")
    assert.eq(evt.kind, "member.joined", "event kind should be 'member.joined'")
    assert.eq(evt.path, group, "event path should be the group name")

    -- cleanup
    scope:leave(group)
    sub2:close()
end

return { main = main }
