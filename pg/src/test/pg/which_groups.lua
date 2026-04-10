-- Test: which_groups lists all active groups
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group_a = "test.which.alpha"
    local group_b = "test.which.beta"
    local group_c = "test.which.gamma"

    -- join 3 different groups
    local ok, err
    ok, err = scope:join(group_a)
    assert.no_error(ok, err, "join alpha")
    ok, err = scope:join(group_b)
    assert.no_error(ok, err, "join beta")
    ok, err = scope:join(group_c)
    assert.no_error(ok, err, "join gamma")

    -- which_groups should include all 3
    local groups, err2 = scope:which_groups()
    assert.no_error(groups, err2, "which_groups should succeed")
    assert.is_table(groups, "which_groups should return a table")
    assert.gte(#groups, 3, "should have at least 3 groups")

    -- check each group is present
    local found = {}
    for _, g in ipairs(groups) do
        found[g] = true
    end
    assert.ok(found[group_a], "alpha should be in which_groups")
    assert.ok(found[group_b], "beta should be in which_groups")
    assert.ok(found[group_c], "gamma should be in which_groups")

    -- cleanup
    scope:leave(group_a)
    scope:leave(group_b)
    scope:leave(group_c)
end

return { main = main }
