-- Test: interleaved join/leave with multiple groups
-- Verifies membership correctness when joining and leaving groups in non-sequential order.
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group_a = "test.interl.a"
    local group_b = "test.interl.b"
    local group_c = "test.interl.c"

    -- join a
    local ok, err = scope:join(group_a)
    assert.no_error(ok, err, "join group a")

    -- join b
    ok, err = scope:join(group_b)
    assert.no_error(ok, err, "join group b")

    -- leave a
    ok, err = scope:leave(group_a)
    assert.no_error(ok, err, "leave group a")

    -- join c
    ok, err = scope:join(group_c)
    assert.no_error(ok, err, "join group c")

    -- verify: a has 0, b has 1, c has 1
    local members, merr
    members, merr = scope:get_members(group_a)
    assert.no_error(members, merr, "get_members group a")
    assert.eq(#members, 0, "group a should have 0 members after leave")

    members, merr = scope:get_members(group_b)
    assert.no_error(members, merr, "get_members group b")
    assert.eq(#members, 1, "group b should have 1 member")

    members, merr = scope:get_members(group_c)
    assert.no_error(members, merr, "get_members group c")
    assert.eq(#members, 1, "group c should have 1 member")

    -- leave b
    ok, err = scope:leave(group_b)
    assert.no_error(ok, err, "leave group b")

    -- verify: b has 0, c has 1
    members, merr = scope:get_members(group_b)
    assert.no_error(members, merr, "get_members group b after leave")
    assert.eq(#members, 0, "group b should have 0 members after leave")

    members, merr = scope:get_members(group_c)
    assert.no_error(members, merr, "get_members group c still")
    assert.eq(#members, 1, "group c should still have 1 member")

    -- leave c
    ok, err = scope:leave(group_c)
    assert.no_error(ok, err, "leave group c")

    -- verify: c has 0
    members, merr = scope:get_members(group_c)
    assert.no_error(members, merr, "get_members group c after leave")
    assert.eq(#members, 0, "group c should have 0 members after leave")

    -- which_groups should NOT contain any of a, b, c
    local wg, wgerr = scope:which_groups()
    assert.no_error(wg, wgerr, "which_groups should succeed")

    local found = {}
    for _, g in ipairs(wg) do
        found[g] = true
    end
    assert.is_nil(found[group_a], "group a should NOT be in which_groups")
    assert.is_nil(found[group_b], "group b should NOT be in which_groups")
    assert.is_nil(found[group_c], "group c should NOT be in which_groups")
end

return { main = main }
