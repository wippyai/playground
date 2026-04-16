-- Test: two PG scopes (pg and pg_alt) with same group name have isolated members
local assert = require("assert")
local pg = require("pg")

local function main()
    local s1 = pg.open("app:pg")
    local s2 = pg.open("app:pg_alt")
    local group = "test.multi_scope_iso"

    -- join same group name in both scopes
    local ok, err
    ok, err = s1:join(group)
    assert.no_error(ok, err, "scope1 join should succeed")
    ok, err = s2:join(group)
    assert.no_error(ok, err, "scope2 join should succeed")

    -- verify each scope sees only its own member
    local m1, e1 = s1:get_members(group)
    assert.no_error(m1, e1, "scope1 get_members")
    assert.eq(#m1, 1, "scope1 should have 1 member")

    local m2, e2 = s2:get_members(group)
    assert.no_error(m2, e2, "scope2 get_members")
    assert.eq(#m2, 1, "scope2 should have 1 member")

    -- leave from scope1 should not affect scope2
    s1:leave(group)

    m1, e1 = s1:get_members(group)
    assert.no_error(m1, e1, "scope1 after leave")
    assert.eq(#m1, 0, "scope1 should have 0 members after leave")

    m2, e2 = s2:get_members(group)
    assert.no_error(m2, e2, "scope2 after scope1 leave")
    assert.eq(#m2, 1, "scope2 should still have 1 member")

    -- cleanup
    s2:leave(group)
end

return { main = main }
