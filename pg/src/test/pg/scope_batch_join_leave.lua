-- Test: scope batch join/leave with prefix verification
local assert = require("assert")
local pg = require("pg")

local function main()
    local s = pg.scope("scope_batch")
    local groups = {"test.sbatch.a", "test.sbatch.b", "test.sbatch.c"}

    -- batch join via scope
    local ok, err = s.join(groups)
    assert.no_error(ok, err, "scoped batch join should succeed")

    -- verify membership in each scoped group
    for _, group in ipairs(groups) do
        local members, merr = s.get_members(group)
        assert.no_error(members, merr, "scoped get_members for " .. group)
        assert.eq(#members, 1, group .. " should have 1 member")
    end

    -- verify scoped which_groups lists all 3 (without prefix)
    local sgroups, gerr = s.which_groups()
    assert.no_error(sgroups, gerr, "scoped which_groups")
    local found = {}
    for _, g in ipairs(sgroups) do
        found[g] = true
    end
    for _, group in ipairs(groups) do
        assert.ok(found[group], group .. " should be in scoped which_groups")
    end

    -- verify global pg sees them with prefix
    local all_groups, aerr = pg.which_groups()
    assert.no_error(all_groups, aerr, "global which_groups")
    local global_found = {}
    for _, g in ipairs(all_groups) do
        global_found[g] = true
    end
    for _, group in ipairs(groups) do
        local prefixed = "scope_batch::" .. group
        assert.ok(global_found[prefixed], prefixed .. " should be in global which_groups")
    end

    -- batch leave via scope
    ok, err = s.leave(groups)
    assert.no_error(ok, err, "scoped batch leave should succeed")

    -- verify all groups empty
    for _, group in ipairs(groups) do
        local members, merr = s.get_members(group)
        assert.no_error(members, merr, "scoped get_members after leave for " .. group)
        assert.eq(#members, 0, group .. " should be empty after batch leave")
    end
end

return { main = main }
