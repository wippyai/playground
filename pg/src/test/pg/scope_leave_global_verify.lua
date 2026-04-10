-- Test: scoped join is visible globally with prefix, and scoped leave removes it
local assert = require("assert")
local pg = require("pg")

local function main()
    local scope_name = "verify_scope"
    local group = "test.slgv"
    local prefixed_group = scope_name .. "::" .. group

    -- create scope and join a group within it
    local s = pg.scope(scope_name)
    local ok, err = s.join(group)
    assert.no_error(ok, err, "scoped join should succeed")

    -- verify global pg.get_members with the prefixed name returns 1 member
    local members, merr = pg.get_members(prefixed_group)
    assert.no_error(members, merr, "global get_members with prefix should succeed")
    assert.eq(#members, 1, "global get_members should return 1 member for scoped group")

    -- leave via scope
    ok, err = s.leave(group)
    assert.no_error(ok, err, "scoped leave should succeed")

    -- verify global pg.get_members with the prefixed name returns 0 members
    members, merr = pg.get_members(prefixed_group)
    assert.no_error(members, merr, "global get_members after leave should succeed")
    assert.eq(#members, 0, "global get_members should return 0 members after scoped leave")
end

return { main = main }
