-- Test: scope:join() with a table of groups (batch join)
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local groups = {"test.batch_join.a", "test.batch_join.b", "test.batch_join.c"}

    -- batch join all 3 groups at once
    local ok, err = scope:join(groups)
    assert.no_error(ok, err, "batch join should succeed")

    -- verify membership in each group
    for _, group in ipairs(groups) do
        local members, merr = scope:get_members(group)
        assert.no_error(members, merr, "get_members for " .. group)
        assert.eq(#members, 1, group .. " should have 1 member")
    end

    -- verify which_groups includes all 3
    local all_groups, err2 = scope:which_groups()
    assert.no_error(all_groups, err2, "which_groups should succeed")
    local found = {}
    for _, g in ipairs(all_groups) do
        found[g] = true
    end
    for _, group in ipairs(groups) do
        assert.ok(found[group], group .. " should be in which_groups")
    end

    -- cleanup
    for _, group in ipairs(groups) do
        scope:leave(group)
    end
end

return { main = main }
