-- Test: pg.open() isolation - two instances with same group name don't interfere
local assert = require("assert")
local pg = require("pg")

local function main()
    local s1 = pg.open("app:pg_alt")
    local s2 = pg.open("app:pg_alt2")
    local group = "test.scope_isolation"

    -- join same group name in both instances
    local ok, err
    ok, err = s1:join(group)
    assert.no_error(ok, err, "instance 1 join should succeed")
    ok, err = s2:join(group)
    assert.no_error(ok, err, "instance 2 join should succeed")

    -- each instance should see only its own member
    local m1, e1 = s1:get_members(group)
    assert.no_error(m1, e1, "instance 1 get_members")
    assert.eq(#m1, 1, "instance 1 should have 1 member")

    local m2, e2 = s2:get_members(group)
    assert.no_error(m2, e2, "instance 2 get_members")
    assert.eq(#m2, 1, "instance 2 should have 1 member")

    -- each instance's which_groups should only list its own groups
    local g1, ge1 = s1:which_groups()
    assert.no_error(g1, ge1, "instance 1 which_groups")
    local g2, ge2 = s2:which_groups()
    assert.no_error(g2, ge2, "instance 2 which_groups")

    -- instance 1 should see its group
    local found_in_s1 = false
    for _, g in ipairs(g1) do
        if g == group then
            found_in_s1 = true
        end
    end
    assert.ok(found_in_s1, "instance 1 should see the group")

    local found_in_s2 = false
    for _, g in ipairs(g2) do
        if g == group then
            found_in_s2 = true
        end
    end
    assert.ok(found_in_s2, "instance 2 should see the group")

    -- leave from instance 1 only
    s1:leave(group)

    -- instance 1 should now be empty, instance 2 should still have a member
    m1, e1 = s1:get_members(group)
    assert.no_error(m1, e1, "instance 1 after leave")
    assert.eq(#m1, 0, "instance 1 should be empty after leave")

    m2, e2 = s2:get_members(group)
    assert.no_error(m2, e2, "instance 2 after instance 1 leave")
    assert.eq(#m2, 1, "instance 2 should still have 1 member")

    -- cleanup
    s2:leave(group)
end

return { main = main }
