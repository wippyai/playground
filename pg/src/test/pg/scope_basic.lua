-- Test: pg.open() basic functionality - join, get_members, which_groups within an instance
local assert = require("assert")
local pg = require("pg")

local function main()
    local s = pg.open("app:pg")
    assert.not_nil(s, "instance should not be nil")

    local group = "test.scope_basic"

    -- join a group within the instance
    local ok, err = s:join(group)
    assert.no_error(ok, err, "join should succeed")

    -- get_members within the instance should find our process
    local members, merr = s:get_members(group)
    assert.no_error(members, merr, "get_members should succeed")
    assert.eq(#members, 1, "group should have 1 member")

    -- which_groups within the instance should list the group
    local groups, gerr = s:which_groups()
    assert.no_error(groups, gerr, "which_groups should succeed")
    assert.is_table(groups, "should return a table")

    local found = false
    for _, g in ipairs(groups) do
        if g == group then
            found = true
        end
    end
    assert.ok(found, "which_groups should include our group")

    -- which_local_groups within the instance should also list the group
    local lgroups, lerr = s:which_local_groups()
    assert.no_error(lgroups, lerr, "which_local_groups should succeed")

    found = false
    for _, g in ipairs(lgroups) do
        if g == group then
            found = true
        end
    end
    assert.ok(found, "which_local_groups should include our group")

    -- leave within instance
    ok, err = s:leave(group)
    assert.no_error(ok, err, "leave should succeed")

    -- verify empty
    members, merr = s:get_members(group)
    assert.no_error(members, merr, "get_members after leave")
    assert.eq(#members, 0, "group should be empty after leave")
end

return { main = main }
