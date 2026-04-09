-- Test: scope events — snapshot is filtered to scoped groups only
-- Note: the channel delivers ALL pg events (scope filtering applies to snapshot only).
local assert = require("assert")
local pg = require("pg")
local time = require("time")

local function main()
    local s = pg.scope("scope_evt")
    local scoped_group = "test.scope_events.scoped"
    local other_group = "test.scope_events.other"

    -- join a group through the scope
    local ok, err = s.join(scoped_group)
    assert.no_error(ok, err, "scoped join")

    -- join a group outside the scope (via global pg)
    ok, err = pg.join(other_group)
    assert.no_error(ok, err, "global join")

    -- subscribe to scoped events
    local sub, snapshot, serr = s.events()
    assert.no_error(sub, serr, "scoped events should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(snapshot, "snapshot should be a table")

    -- snapshot should include the scoped group (without prefix)
    assert.not_nil(snapshot[scoped_group], "snapshot should include scoped group")
    assert.is_table(snapshot[scoped_group], "scoped group members should be a table")
    assert.gte(#snapshot[scoped_group], 1, "scoped group should have at least 1 member")

    -- snapshot should NOT include the other group (not in this scope)
    assert.is_nil(snapshot[other_group], "snapshot should NOT include unscoped group")

    -- snapshot should NOT include the prefixed version (prefix is stripped)
    assert.is_nil(snapshot["scope_evt::" .. scoped_group],
        "snapshot should NOT include prefixed group name")

    local ch = sub:channel()

    -- leave from the scoped group — should get an event
    s.leave(scoped_group)

    local timeout = time.after("3s")
    local result = channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }
    assert.neq(result.channel, timeout, "should receive leave event for scoped group")

    local evt = result.value
    assert.eq(evt.kind, "member.left", "event should be member.left")
    -- event path carries the full prefixed group name on the channel
    local expected_path = "scope_evt::" .. scoped_group
    assert.eq(evt.path, expected_path, "event path should be the full prefixed group name")

    -- cleanup: leave the other group and close subscription
    pg.leave(other_group)

    -- drain any remaining event from the channel before closing
    timeout = time.after("500ms")
    channel.select{
        ch:case_receive(),
        timeout:case_receive(),
    }

    sub:close()
end

return { main = main }
