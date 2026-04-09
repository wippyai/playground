-- Test: pg.scope() basic functionality - join, get_members, which_groups within a scope
local assert = require("assert")
local pg = require("pg")

local function main()
    local s = pg.scope("myscope")
    assert.not_nil(s, "scope should not be nil")
    assert.eq(s.name, "myscope", "scope name should match")

    local group = "test.scope_basic"

    -- join a group within the scope
    local ok, err = s.join(group)
    assert.no_error(ok, err, "scoped join should succeed")

    -- get_members within the scope should find our process
    local members, merr = s.get_members(group)
    assert.no_error(members, merr, "scoped get_members should succeed")
    assert.eq(#members, 1, "scoped group should have 1 member")

    -- which_groups within the scope should list the group (without prefix)
    local groups, gerr = s.which_groups()
    assert.no_error(groups, gerr, "scoped which_groups should succeed")
    assert.is_table(groups, "should return a table")

    local found = false
    for _, g in ipairs(groups) do
        if g == group then
            found = true
        end
    end
    assert.ok(found, "scoped which_groups should include our group without prefix")

    -- which_local_groups within the scope should also list the group
    local lgroups, lerr = s.which_local_groups()
    assert.no_error(lgroups, lerr, "scoped which_local_groups should succeed")

    found = false
    for _, g in ipairs(lgroups) do
        if g == group then
            found = true
        end
    end
    assert.ok(found, "scoped which_local_groups should include our group without prefix")

    -- the global pg module should see the group with the scope prefix
    local all_groups, aerr = pg.which_groups()
    assert.no_error(all_groups, aerr, "global which_groups should succeed")
    local prefixed = "myscope::" .. group
    local found_prefixed = false
    for _, g in ipairs(all_groups) do
        if g == prefixed then
            found_prefixed = true
        end
    end
    assert.ok(found_prefixed, "global which_groups should show prefixed group name")

    -- leave within scope
    ok, err = s.leave(group)
    assert.no_error(ok, err, "scoped leave should succeed")

    -- verify empty
    members, merr = s.get_members(group)
    assert.no_error(members, merr, "scoped get_members after leave")
    assert.eq(#members, 0, "scoped group should be empty after leave")
end

return { main = main }
