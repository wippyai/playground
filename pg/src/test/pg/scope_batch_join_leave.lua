-- Test: instance batch join/leave
local assert = require("assert")
local pg = require("pg")

local function main()
    local s = pg.open("app:pg")
    local groups = {"test.sbatch.a", "test.sbatch.b", "test.sbatch.c"}

    -- batch join via instance
    local ok, err = s:join(groups)
    assert.no_error(ok, err, "batch join should succeed")

    -- verify membership in each group
    for _, group in ipairs(groups) do
        local members, merr = s:get_members(group)
        assert.no_error(members, merr, "get_members for " .. group)
        assert.eq(#members, 1, group .. " should have 1 member")
    end

    -- verify which_groups lists all 3
    local sgroups, gerr = s:which_groups()
    assert.no_error(sgroups, gerr, "which_groups")
    local found = {}
    for _, g in ipairs(sgroups) do
        found[g] = true
    end
    for _, group in ipairs(groups) do
        assert.ok(found[group], group .. " should be in which_groups")
    end

    -- batch leave via instance
    ok, err = s:leave(groups)
    assert.no_error(ok, err, "batch leave should succeed")

    -- verify all groups empty
    for _, group in ipairs(groups) do
        local members, merr = s:get_members(group)
        assert.no_error(members, merr, "get_members after leave for " .. group)
        assert.eq(#members, 0, group .. " should be empty after batch leave")
    end
end

return { main = main }
