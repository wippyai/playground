-- Test: join and leave a group
local assert = require("assert")
local pg = require("pg")
local scope = pg.open("app:pg")

local function main()
    local group = "test.join_leave"

    -- join the group
    local ok, err = scope:join(group)
    assert.no_error(ok, err, "pg.join should succeed")
    assert.ok(ok, "pg.join should return true")

    -- verify we are a member
    local members, err2 = scope:get_members(group)
    assert.no_error(members, err2, "pg.get_members should succeed")
    assert.is_table(members, "get_members should return a table")
    assert.eq(#members, 1, "group should have 1 member after join")

    -- leave the group
    ok, err = scope:leave(group)
    assert.no_error(ok, err, "pg.leave should succeed")

    -- verify we are no longer a member
    members, err2 = scope:get_members(group)
    assert.no_error(members, err2, "pg.get_members after leave should succeed")
    assert.eq(#members, 0, "group should have 0 members after leave")

    -- leaving again should return an error
    local val, leave_err = scope:leave(group)
    assert.has_error(val, leave_err, "leaving unjoined group should error")
end

return { main = main }
