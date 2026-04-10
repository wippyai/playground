-- Test: which_groups does not list groups after all members have left
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group_a = "test.wg_empty.a"
    local group_b = "test.wg_empty.b"
    local group_c = "test.wg_empty.c"
    local test_groups = { group_a, group_b, group_c }

    -- join all 3 groups
    local ok, err
    ok, err = scope:join(group_a)
    assert.no_error(ok, err, "join a")
    ok, err = scope:join(group_b)
    assert.no_error(ok, err, "join b")
    ok, err = scope:join(group_c)
    assert.no_error(ok, err, "join c")

    -- verify all 3 appear in which_groups
    local groups, gerr = scope:which_groups()
    assert.no_error(groups, gerr, "which_groups before leave")
    local found = {}
    for _, g in ipairs(groups) do
        found[g] = true
    end
    for _, tg in ipairs(test_groups) do
        assert.ok(found[tg], tg .. " should be in which_groups before leave")
    end

    -- leave all 3 groups
    scope:leave(group_a)
    scope:leave(group_b)
    scope:leave(group_c)

    -- verify none of those 3 appear in which_groups
    groups, gerr = scope:which_groups()
    assert.no_error(groups, gerr, "which_groups after leave")
    found = {}
    for _, g in ipairs(groups) do
        found[g] = true
    end
    for _, tg in ipairs(test_groups) do
        assert.ok(not found[tg], tg .. " should NOT be in which_groups after leave")
    end
end

return { main = main }
