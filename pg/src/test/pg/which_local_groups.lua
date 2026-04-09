-- Test: pg.which_local_groups() returns groups with local members
local assert = require("assert")
local pg = require("pg")

local function main()
    local group_a = "test.wlg.alpha"
    local group_b = "test.wlg.beta"
    local group_c = "test.wlg.gamma"

    -- initially which_local_groups should return empty or not include our groups
    local groups, err = pg.which_local_groups()
    assert.no_error(groups, err, "which_local_groups should succeed")
    assert.is_table(groups, "which_local_groups should return a table")

    -- join 3 different groups
    local ok
    ok, err = pg.join(group_a)
    assert.no_error(ok, err, "join alpha")
    ok, err = pg.join(group_b)
    assert.no_error(ok, err, "join beta")
    ok, err = pg.join(group_c)
    assert.no_error(ok, err, "join gamma")

    -- which_local_groups should include all 3
    groups, err = pg.which_local_groups()
    assert.no_error(groups, err, "which_local_groups after joins")
    assert.is_table(groups, "should return a table")
    assert.gte(#groups, 3, "should have at least 3 local groups")

    -- check each group is present
    local found = {}
    for _, g in ipairs(groups) do
        found[g] = true
    end
    assert.ok(found[group_a], "alpha should be in which_local_groups")
    assert.ok(found[group_b], "beta should be in which_local_groups")
    assert.ok(found[group_c], "gamma should be in which_local_groups")

    -- leave one group and verify it's gone
    pg.leave(group_b)

    groups, err = pg.which_local_groups()
    assert.no_error(groups, err, "which_local_groups after leave")
    found = {}
    for _, g in ipairs(groups) do
        found[g] = true
    end
    assert.ok(found[group_a], "alpha should still be present")
    assert.ok(not found[group_b], "beta should be gone after leave")
    assert.ok(found[group_c], "gamma should still be present")

    -- cleanup
    pg.leave(group_a)
    pg.leave(group_c)
end

return { main = main }
