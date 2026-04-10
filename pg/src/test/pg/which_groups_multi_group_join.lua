-- Test: which_groups returns all 5 joined groups, and none after leaving
local assert = require("assert")
local pg = require("pg")

local function main()
    local groups = {
        "test.wg5.a",
        "test.wg5.b",
        "test.wg5.c",
        "test.wg5.d",
        "test.wg5.e",
    }

    -- join all 5 groups
    for i, g in ipairs(groups) do
        local ok, err = pg.join(g)
        assert.no_error(ok, err, "join group " .. g)
    end

    -- which_groups should include all 5
    local wg, err = pg.which_groups()
    assert.no_error(wg, err, "which_groups should succeed")
    assert.is_table(wg, "which_groups should return a table")
    assert.gte(#wg, 5, "should have at least 5 groups")

    -- build lookup table
    local found = {}
    for _, g in ipairs(wg) do
        found[g] = true
    end
    for _, g in ipairs(groups) do
        assert.ok(found[g], g .. " should be in which_groups")
    end

    -- leave all 5 groups
    for _, g in ipairs(groups) do
        local ok, err2 = pg.leave(g)
        assert.no_error(ok, err2, "leave group " .. g)
    end

    -- which_groups should no longer contain any of the 5
    wg, err = pg.which_groups()
    assert.no_error(wg, err, "which_groups after leaves should succeed")

    found = {}
    for _, g in ipairs(wg) do
        found[g] = true
    end
    for _, g in ipairs(groups) do
        assert.is_nil(found[g], g .. " should NOT be in which_groups after leave")
    end
end

return { main = main }
