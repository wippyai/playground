-- Test: scope events snapshot is filtered to scoped groups only
-- Global groups should NOT appear in the scoped events snapshot.
local assert = require("assert")
local pg = require("pg")

local function main()
    local global_group = "global_group"
    local scoped_group = "test.scope_evt_snap"

    -- join a group globally
    local ok, err = pg.join(global_group)
    assert.no_error(ok, err, "global join should succeed")

    -- create a scope and join a group within it
    local s = pg.scope("filtered")
    ok, err = s.join(scoped_group)
    assert.no_error(ok, err, "scoped join should succeed")

    -- subscribe to scoped events
    local sub, snapshot, serr = s.events()
    assert.no_error(sub, serr, "scoped events should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(snapshot, "snapshot should be a table")

    -- snapshot should include the scoped group (without prefix)
    assert.not_nil(snapshot[scoped_group], "snapshot should include scoped group")
    assert.is_table(snapshot[scoped_group], "scoped group members should be a table")
    assert.gte(#snapshot[scoped_group], 1, "scoped group should have at least 1 member")

    -- snapshot should NOT include the global group
    assert.is_nil(snapshot[global_group], "snapshot should NOT include global group")

    -- cleanup
    sub:close()
    s.leave(scoped_group)
    pg.leave(global_group)
end

return { main = main }
