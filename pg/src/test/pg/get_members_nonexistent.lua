-- Test: get_members and get_local_members for non-existent group returns empty table
local assert = require("assert")
local pg = require("pg")

local function main()
    local group = "test.nonexistent_group_that_does_not_exist_12345"

    -- get_members for a group nobody has ever joined should return empty table
    local members, err = pg.get_members(group)
    assert.no_error(members, err, "get_members for non-existent group should not error")
    assert.is_table(members, "should return a table")
    assert.eq(#members, 0, "non-existent group should have 0 members")

    -- get_local_members for a group nobody has ever joined should return empty table
    local local_members, lerr = pg.get_local_members(group)
    assert.no_error(local_members, lerr, "get_local_members for non-existent group should not error")
    assert.is_table(local_members, "should return a table")
    assert.eq(#local_members, 0, "non-existent group should have 0 local members")
end

return { main = main }
