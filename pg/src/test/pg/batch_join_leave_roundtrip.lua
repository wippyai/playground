-- Test: batch join and leave roundtrip with which_groups verification
local assert = require("assert")
local pg = require("pg")

local function main()
    local groups = {"test.bjlr.w", "test.bjlr.x", "test.bjlr.y", "test.bjlr.z"}

    -- batch join all 4 groups
    local ok, err = pg.join(groups)
    assert.no_error(ok, err, "batch join should succeed")

    -- verify which_groups contains all 4
    local all_groups, gerr = pg.which_groups()
    assert.no_error(all_groups, gerr, "which_groups after join")
    local found = {}
    for _, g in ipairs(all_groups) do
        found[g] = true
    end
    for _, group in ipairs(groups) do
        assert.ok(found[group], group .. " should be in which_groups after join")
    end

    -- batch leave all 4 groups
    ok, err = pg.leave(groups)
    assert.no_error(ok, err, "batch leave should succeed")

    -- verify which_groups contains none of them
    all_groups, gerr = pg.which_groups()
    assert.no_error(all_groups, gerr, "which_groups after leave")
    found = {}
    for _, g in ipairs(all_groups) do
        found[g] = true
    end
    for _, group in ipairs(groups) do
        assert.ok(not found[group], group .. " should NOT be in which_groups after leave")
    end

    -- verify get_members for each returns 0
    for _, group in ipairs(groups) do
        local members, merr = pg.get_members(group)
        assert.no_error(members, merr, "get_members after leave for " .. group)
        assert.eq(#members, 0, group .. " should have 0 members after leave")
    end
end

return { main = main }
