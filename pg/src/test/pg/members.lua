-- Test: get_members and get_local_members
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group = "test.members"

    -- join the group
    local ok, err = scope:join(group)
    assert.no_error(ok, err, "pg.join should succeed")

    -- get_members should return our PID
    local members, err2 = scope:get_members(group)
    assert.no_error(members, err2, "get_members should succeed")
    assert.eq(#members, 1, "get_members should have 1 member")

    -- get_local_members should also return our PID (we are local)
    local local_members, err3 = scope:get_local_members(group)
    assert.no_error(local_members, err3, "get_local_members should succeed")
    assert.eq(#local_members, 1, "get_local_members should have 1 member")

    -- both should return the same PID
    assert.eq(members[1], local_members[1], "get_members and get_local_members should return same PID")

    -- query a non-existent group returns empty table
    local empty, err4 = scope:get_members("test.nonexistent.group")
    assert.no_error(empty, err4, "querying non-existent group should not error")
    assert.is_table(empty, "should return a table")
    assert.eq(#empty, 0, "non-existent group should have 0 members")

    -- cleanup
    scope:leave(group)
end

return { main = main }
