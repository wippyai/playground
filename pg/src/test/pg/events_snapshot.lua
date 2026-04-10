-- Test: scope:events() returns a snapshot of current groups atomically
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group_a = "test.events_snap.a"
    local group_b = "test.events_snap.b"

    -- join two groups BEFORE subscribing
    local ok, err
    ok, err = scope:join(group_a)
    assert.no_error(ok, err, "join group_a")
    ok, err = scope:join(group_b)
    assert.no_error(ok, err, "join group_b")

    -- subscribe to events - should receive snapshot of current groups
    local sub, groups, serr = scope:events()
    assert.no_error(sub, serr, "pg.events should succeed")
    assert.not_nil(sub, "subscription should not be nil")
    assert.is_table(groups, "groups snapshot should be a table")

    -- the snapshot should include our two groups
    assert.not_nil(groups[group_a], "snapshot should include group_a")
    assert.is_table(groups[group_a], "group_a value should be a table of PIDs")
    assert.gte(#groups[group_a], 1, "group_a should have at least 1 member")

    assert.not_nil(groups[group_b], "snapshot should include group_b")
    assert.is_table(groups[group_b], "group_b value should be a table of PIDs")
    assert.gte(#groups[group_b], 1, "group_b should have at least 1 member")

    -- cleanup
    sub:close()
    scope:leave(group_a)
    scope:leave(group_b)
end

return { main = main }
