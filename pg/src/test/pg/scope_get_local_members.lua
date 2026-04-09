-- Test: scope get_local_members returns members of the scoped group
local assert = require("assert")
local pg = require("pg")

local function main()
    local s = pg.scope("scope_glm")
    local group = "test.scope_get_local_members"

    -- join group via scope
    local ok, err = s.join(group)
    assert.no_error(ok, err, "scoped join")

    -- get_local_members via scope should find our process
    local members, merr = s.get_local_members(group)
    assert.no_error(members, merr, "scoped get_local_members")
    assert.eq(#members, 1, "should have 1 local member")

    -- join again (multi-join)
    ok, err = s.join(group)
    assert.no_error(ok, err, "scoped join #2")

    members, merr = s.get_local_members(group)
    assert.no_error(members, merr, "scoped get_local_members after multi-join")
    assert.eq(#members, 2, "should have 2 entries after 2 joins")

    -- verify global get_local_members sees the prefixed group
    local prefixed = "scope_glm::" .. group
    local gm, gerr = pg.get_local_members(prefixed)
    assert.no_error(gm, gerr, "global get_local_members for prefixed group")
    assert.eq(#gm, 2, "global should also see 2 entries")

    -- cleanup
    s.leave(group)
    s.leave(group)

    -- verify empty after leaves
    members, merr = s.get_local_members(group)
    assert.no_error(members, merr, "scoped get_local_members after leave")
    assert.eq(#members, 0, "should be empty after leaves")
end

return { main = main }
