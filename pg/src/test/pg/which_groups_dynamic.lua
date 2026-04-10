-- Test: which_groups reflects group lifecycle dynamically
-- Erlang PG: groups are implicitly created on first join, removed when last member leaves
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

local function main()
    local g1 = "test.dynamic.one"
    local g2 = "test.dynamic.two"
    local g3 = "test.dynamic.three"

    -- initially none of our test groups should exist
    local groups, err = scope:which_groups()
    assert.no_error(groups, err, "which_groups initial")
    assert.ok(not contains(groups, g1), "g1 should not exist initially")
    assert.ok(not contains(groups, g2), "g2 should not exist initially")
    assert.ok(not contains(groups, g3), "g3 should not exist initially")

    -- join g1 → it should appear
    scope:join(g1)
    groups, err = scope:which_groups()
    assert.no_error(groups, err, "which_groups after join g1")
    assert.ok(contains(groups, g1), "g1 should appear after join")
    assert.ok(not contains(groups, g2), "g2 should not exist yet")

    -- join g2 → both should appear
    scope:join(g2)
    groups, err = scope:which_groups()
    assert.no_error(groups, err, "which_groups after join g2")
    assert.ok(contains(groups, g1), "g1 should still exist")
    assert.ok(contains(groups, g2), "g2 should appear after join")

    -- join g3 twice (multi-join)
    scope:join(g3)
    scope:join(g3)
    groups, err = scope:which_groups()
    assert.no_error(groups, err, "which_groups after join g3 twice")
    assert.ok(contains(groups, g3), "g3 should appear after join")

    -- leave g1 → it should disappear
    scope:leave(g1)
    groups, err = scope:which_groups()
    assert.no_error(groups, err, "which_groups after leave g1")
    assert.ok(not contains(groups, g1), "g1 should disappear after leave")
    assert.ok(contains(groups, g2), "g2 should still exist")
    assert.ok(contains(groups, g3), "g3 should still exist")

    -- leave g3 once → still has one membership, should remain
    scope:leave(g3)
    groups, err = scope:which_groups()
    assert.no_error(groups, err, "which_groups after leave g3 once")
    assert.ok(contains(groups, g3), "g3 should still exist with 1 remaining join")

    -- leave g3 again → now empty, should disappear
    scope:leave(g3)
    groups, err = scope:which_groups()
    assert.no_error(groups, err, "which_groups after leave g3 fully")
    assert.ok(not contains(groups, g3), "g3 should disappear after all leaves")

    -- cleanup g2
    scope:leave(g2)
end

return { main = main }
