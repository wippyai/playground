-- Test: after scope:monitor():close(), no more events are received
-- Verifies that demonitor/unsubscribe is synchronous: once close() returns,
-- subsequent join/leave operations do NOT deliver events to the closed subscription.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")
local time = require("time")

local function main()
    local group = "test.demonitor_no_events"

    -- subscribe to monitor for this group
    local sub, members, err = scope:monitor(group)
    assert.no_error(sub, err, "pg.monitor should succeed")
    assert.eq(#members, 0, "initial members should be empty")

    local ch = sub:channel()

    -- join the group to verify monitor works
    local ok, err2 = scope:join(group)
    assert.no_error(ok, err2, "pg.join should succeed")

    -- receive the join event
    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive join event before close")
    assert.eq(result.value.kind, "member.joined", "should be join event")

    -- leave the group first, then close the subscription
    scope:leave(group)

    -- consume the leave event
    timeout = time.after("3s")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event")

    -- close the subscription (synchronous — no more events after this)
    sub:close()

    -- join and leave again AFTER close
    scope:join(group)
    scope:leave(group)

    -- small delay to allow any in-flight events
    time.sleep("200ms")

    -- attempt to receive — should timeout (no events after close)
    timeout = time.after("500ms")
    result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.eq(result.channel, timeout,
        "should NOT receive any events after close (got timeout as expected)")
end

return { main = main }
