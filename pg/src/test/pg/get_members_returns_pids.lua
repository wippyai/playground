-- Test: get_members returns a table of PID strings
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.get_members_pids"

    -- join the group
    local ok, err = pg.join(group)
    assert.no_error(ok, err, "pg.join should succeed")

    -- get_members should return a table with 1 entry
    local members, merr = pg.get_members(group)
    assert.no_error(members, merr, "get_members should succeed")
    assert.is_table(members, "get_members should return a table")
    assert.eq(#members, 1, "should have exactly 1 member")

    -- the entry should be a string (PID)
    assert.eq(type(members[1]), "string", "member entry should be a string")

    -- the string should be non-empty
    assert.ok(#members[1] > 0, "PID string should be non-empty")

    -- cleanup
    pg.leave(group)
end

return { main = main }
