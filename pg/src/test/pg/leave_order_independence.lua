-- Test: groups can be left in any order regardless of join order
local assert = require("assert")
local pg = require("pg")

local function main()
    local group_a = "test.leave_ord.a"
    local group_b = "test.leave_ord.b"
    local group_c = "test.leave_ord.c"

    -- join in order a, b, c
    local ok, err
    ok, err = pg.join(group_a)
    assert.no_error(ok, err, "join a")
    ok, err = pg.join(group_b)
    assert.no_error(ok, err, "join b")
    ok, err = pg.join(group_c)
    assert.no_error(ok, err, "join c")

    -- leave in reverse order: c, b, a
    -- leave c
    ok, err = pg.leave(group_c)
    assert.no_error(ok, err, "leave c should succeed")

    local members, merr = pg.get_members(group_c)
    assert.no_error(members, merr, "get_members c after leave")
    assert.eq(#members, 0, "c should have 0 members after leave")

    members, merr = pg.get_members(group_a)
    assert.no_error(members, merr, "get_members a after leaving c")
    assert.eq(#members, 1, "a should still have 1 member")
    members, merr = pg.get_members(group_b)
    assert.no_error(members, merr, "get_members b after leaving c")
    assert.eq(#members, 1, "b should still have 1 member")

    -- leave b
    ok, err = pg.leave(group_b)
    assert.no_error(ok, err, "leave b should succeed")

    members, merr = pg.get_members(group_b)
    assert.no_error(members, merr, "get_members b after leave")
    assert.eq(#members, 0, "b should have 0 members after leave")

    members, merr = pg.get_members(group_a)
    assert.no_error(members, merr, "get_members a after leaving b")
    assert.eq(#members, 1, "a should still have 1 member")

    -- leave a
    ok, err = pg.leave(group_a)
    assert.no_error(ok, err, "leave a should succeed")

    members, merr = pg.get_members(group_a)
    assert.no_error(members, merr, "get_members a after leave")
    assert.eq(#members, 0, "a should have 0 members after leave")
end

return { main = main }
