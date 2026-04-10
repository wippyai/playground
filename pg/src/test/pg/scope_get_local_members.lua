-- Test: instance get_local_members returns members of the group
local assert = require("assert")
local pg = require("pg")

local function main()
    local s = pg.open("app:pg")
    local group = "test.scope_get_local_members"

    -- join group via instance
    local ok, err = s:join(group)
    assert.no_error(ok, err, "join")

    -- get_local_members via instance should find our process
    local members, merr = s:get_local_members(group)
    assert.no_error(members, merr, "get_local_members")
    assert.eq(#members, 1, "should have 1 local member")

    -- join again (multi-join)
    ok, err = s:join(group)
    assert.no_error(ok, err, "join #2")

    members, merr = s:get_local_members(group)
    assert.no_error(members, merr, "get_local_members after multi-join")
    assert.eq(#members, 2, "should have 2 entries after 2 joins")

    -- cleanup
    s:leave(group)
    s:leave(group)

    -- verify empty after leaves
    members, merr = s:get_local_members(group)
    assert.no_error(members, merr, "get_local_members after leave")
    assert.eq(#members, 0, "should be empty after leaves")
end

return { main = main }
