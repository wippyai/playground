-- Test: pg.scope() isolation - two scopes with same group name don't interfere
local assert = require("assert")
local pg = require("pg")

local function main()
    local s1 = pg.scope("scope_a")
    local s2 = pg.scope("scope_b")
    local group = "test.scope_isolation"

    -- join same group name in both scopes
    local ok, err
    ok, err = s1.join(group)
    assert.no_error(ok, err, "scope_a join should succeed")
    ok, err = s2.join(group)
    assert.no_error(ok, err, "scope_b join should succeed")

    -- each scope should see only its own member
    local m1, e1 = s1.get_members(group)
    assert.no_error(m1, e1, "scope_a get_members")
    assert.eq(#m1, 1, "scope_a should have 1 member")

    local m2, e2 = s2.get_members(group)
    assert.no_error(m2, e2, "scope_b get_members")
    assert.eq(#m2, 1, "scope_b should have 1 member")

    -- each scope's which_groups should only list its own groups
    local g1, ge1 = s1.which_groups()
    assert.no_error(g1, ge1, "scope_a which_groups")
    local g2, ge2 = s2.which_groups()
    assert.no_error(g2, ge2, "scope_b which_groups")

    -- scope_a should see its group but not scope_b's
    local found_in_s1 = false
    for _, g in ipairs(g1) do
        if g == group then
            found_in_s1 = true
        end
        -- group names should NOT have the prefix in scoped results
        assert.ok(not string.find(g, "scope_a::", 1, true), "scoped which_groups should not have prefix")
    end
    assert.ok(found_in_s1, "scope_a should see the group")

    local found_in_s2 = false
    for _, g in ipairs(g2) do
        if g == group then
            found_in_s2 = true
        end
    end
    assert.ok(found_in_s2, "scope_b should see the group")

    -- leave from scope_a only
    s1.leave(group)

    -- scope_a should now be empty, scope_b should still have a member
    m1, e1 = s1.get_members(group)
    assert.no_error(m1, e1, "scope_a after leave")
    assert.eq(#m1, 0, "scope_a should be empty after leave")

    m2, e2 = s2.get_members(group)
    assert.no_error(m2, e2, "scope_b after scope_a leave")
    assert.eq(#m2, 1, "scope_b should still have 1 member")

    -- cleanup
    s2.leave(group)
end

return { main = main }
