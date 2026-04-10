-- Test: instance events snapshot contains only groups for this instance
local assert = require("assert")
local pg = require("pg")

local function main()
    local s = pg.open("app:pg")
    local group = "test.scope_evt_snap"

    -- join a group within the instance
    local ok, err = s:join(group)
    assert.no_error(ok, err, "join should succeed")

    -- subscribe to instance events
    local sub, snapshot, serr = s:events()
    assert.no_error(sub, serr, "events should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(snapshot, "snapshot should be a table")

    -- snapshot should include the group
    assert.not_nil(snapshot[group], "snapshot should include group")
    assert.is_table(snapshot[group], "group members should be a table")
    assert.gte(#snapshot[group], 1, "group should have at least 1 member")

    -- cleanup
    sub:close()
    s:leave(group)
end

return { main = main }
