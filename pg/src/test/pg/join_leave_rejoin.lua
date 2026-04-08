-- Test: join, leave, verify empty, rejoin, verify member again
-- Tests that a process can rejoin a group after leaving it.
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.join_leave_rejoin"

    -- join
    local ok, err = pg.join(group)
    assert.no_error(ok, err, "first join should succeed")

    local members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members after join should succeed")
    assert.eq(#members, 1, "should have 1 member after join")

    -- leave
    ok, err = pg.leave(group)
    assert.no_error(ok, err, "leave should succeed")

    members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members after leave should succeed")
    assert.eq(#members, 0, "should have 0 members after leave")

    -- rejoin
    ok, err = pg.join(group)
    assert.no_error(ok, err, "rejoin should succeed")

    members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members after rejoin should succeed")
    assert.eq(#members, 1, "should have 1 member after rejoin")
    assert.eq(members[1], process.pid(), "member should be our PID")

    -- cleanup
    pg.leave(group)
end

return { main = main }
